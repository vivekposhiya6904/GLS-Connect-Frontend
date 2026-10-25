import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/storage_service.dart';

class EncryptionService {
  static const String v2Prefix = "v2:aes-gcm:";
  static const String legacyPrefix = "ENC:";
  static const String unableToDecrypt = "[Unable to decrypt message]";

  static final Map<String, List<int>> _memoryKeyCache = {};
  static FlutterSecureStorage? _secureStorage;

  static FlutterSecureStorage get secureStorage =>
      _secureStorage ??= const FlutterSecureStorage();

  static set secureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  static String _getStorageKey(String user1, String user2) {
    final emails = [user1.trim().toLowerCase(), user2.trim().toLowerCase()]..sort();
    return "conv_key_${emails[0]}_${emails[1]}";
  }

  static void setConversationKeyForTest(String user1, String user2, List<int> keyBytes) {
    final storageKey = _getStorageKey(user1, user2);
    _memoryKeyCache[storageKey] = List<int>.unmodifiable(keyBytes);
  }

  static void clearKeyCacheForTest() {
    _memoryKeyCache.clear();
  }

  static Future<List<int>?> getOrFetchKey(String user1, String user2) async {
    final storageKey = _getStorageKey(user1, user2);

    // 1. In-memory cache
    if (_memoryKeyCache.containsKey(storageKey)) {
      return _memoryKeyCache[storageKey];
    }

    // 2. Platform secure storage (Android Keystore / iOS Keychain)
    try {
      final storedBase64 = await secureStorage.read(key: storageKey);
      if (storedBase64 != null && storedBase64.isNotEmpty) {
        final decoded = base64Decode(storedBase64);
        if (decoded.length == 32) {
          _memoryKeyCache[storageKey] = decoded;
          return decoded;
        }
      }
    } catch (_) {}

    // 3. Fetch from backend
    String partnerEmail = user2.trim().toLowerCase();
    try {
      final currentEmail = await StorageService.getUserEmail();
      if (currentEmail != null && currentEmail.trim().isNotEmpty) {
        final normCurrent = currentEmail.trim().toLowerCase();
        if (user1.trim().toLowerCase() == normCurrent) {
          partnerEmail = user2.trim().toLowerCase();
        } else if (user2.trim().toLowerCase() == normCurrent) {
          partnerEmail = user1.trim().toLowerCase();
        }
      }
    } catch (_) {}

    try {
      final token = await StorageService.getToken();
      if (token != null && partnerEmail.isNotEmpty) {
        final res = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/api/chat/key/$partnerEmail"),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final keyStr = data["key"]?.toString();
          if (keyStr != null && keyStr.isNotEmpty) {
            final decoded = base64Decode(keyStr);
            if (decoded.length == 32) {
              _memoryKeyCache[storageKey] = decoded;
              try {
                await secureStorage.write(key: storageKey, value: keyStr);
              } catch (_) {}
              return decoded;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Encrypts plaintext using AES-256-GCM with a 12-byte CSPRNG nonce and 16-byte authentication tag.
  /// Formats output as "v2:aes-gcm:" + base64([12-byte nonce] + [ciphertext] + [16-byte tag]).
  static Future<String> encrypt(String plainText, String user1, String user2) async {
    if (plainText.isEmpty) return plainText;

    final keyBytes = await getOrFetchKey(user1, user2);
    if (keyBytes == null || keyBytes.length != 32) {
      throw StateError("Missing or invalid 256-bit encryption key");
    }

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);
    final nonce = algorithm.newNonce(); // 12-byte cryptographically secure random nonce

    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final combined = <int>[
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return "$v2Prefix${base64Encode(combined)}";
  }

  /// Decrypts ciphertext.
  /// If format is "v2:aes-gcm:", decrypts using AES-256-GCM, verifying nonce and tag.
  /// If format is "ENC:", decrypts using legacy XOR algorithm with email derivation.
  /// If unencrypted, returns text as-is.
  /// On any authentication failure, tampering, or malformed input, safely returns "[Unable to decrypt message]".
  static Future<String> decrypt(String text, String user1, String user2) async {
    if (text.isEmpty) return text;

    if (text.startsWith(v2Prefix)) {
      return await _decryptV2(text.substring(v2Prefix.length), user1, user2);
    } else if (text.startsWith(legacyPrefix)) {
      return _decryptLegacy(text.substring(legacyPrefix.length), user1, user2);
    } else {
      // Plaintext message
      return text;
    }
  }

  static Future<String> _decryptV2(String base64Payload, String user1, String user2) async {
    try {
      final combined = base64Decode(base64Payload);
      // Nonce: 12 bytes, MAC: 16 bytes. Minimum valid payload is 28 bytes
      if (combined.length < 28) {
        return unableToDecrypt;
      }

      final nonce = combined.sublist(0, 12);
      final macBytes = combined.sublist(combined.length - 16);
      final cipherText = combined.sublist(12, combined.length - 16);

      final keyBytes = await getOrFetchKey(user1, user2);
      if (keyBytes == null || keyBytes.length != 32) {
        return unableToDecrypt;
      }

      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(keyBytes);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      final clearBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clearBytes);
    } catch (_) {
      // SecretBoxAuthenticationError, FormatException, etc.
      return unableToDecrypt;
    }
  }

  static String _decryptLegacy(String base64Cipher, String user1, String user2) {
    try {
      final encryptedBytes = base64Decode(base64Cipher);
      final emails = [user1.trim().toLowerCase(), user2.trim().toLowerCase()]..sort();
      final combined = "${emails[0]}:${emails[1]}:GLS_CONNECT_E2EE_KEY_2026";
      final key = sha256.convert(utf8.encode(combined)).bytes;

      final decryptedBytes = List<int>.generate(
        encryptedBytes.length,
        (i) => encryptedBytes[i] ^ key[i % key.length],
      );

      return utf8.decode(decryptedBytes);
    } catch (_) {
      return unableToDecrypt;
    }
  }
}
