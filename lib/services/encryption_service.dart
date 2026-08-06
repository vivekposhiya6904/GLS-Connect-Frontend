import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  /// Generate a deterministic AES key bytes from conversation partner emails
  static List<int> _deriveKey(String user1, String user2) {
    final emails = [user1.trim().toLowerCase(), user2.trim().toLowerCase()]..sort();
    final combined = "${emails[0]}:${emails[1]}:GLS_CONNECT_E2EE_KEY_2026";
    final bytes = utf8.encode(combined);
    return sha256.convert(bytes).bytes;
  }

  /// Encrypt plaintext into base64 ciphertext with "ENC:" prefix
  static String encrypt(String plainText, String user1, String user2) {
    if (plainText.isEmpty) return plainText;

    try {
      final key = _deriveKey(user1, user2);
      final textBytes = utf8.encode(plainText);
      final encryptedBytes = List<int>.generate(
        textBytes.length,
        (i) => textBytes[i] ^ key[i % key.length],
      );

      final base64Cipher = base64Encode(encryptedBytes);
      return "ENC:$base64Cipher";
    } catch (_) {
      return plainText;
    }
  }

  /// Decrypt ciphertext with "ENC:" prefix back to plaintext
  static String decrypt(String text, String user1, String user2) {
    if (text.isEmpty || !text.startsWith("ENC:")) return text;

    try {
      final base64Cipher = text.substring(4);
      final encryptedBytes = base64Decode(base64Cipher);
      final key = _deriveKey(user1, user2);

      final decryptedBytes = List<int>.generate(
        encryptedBytes.length,
        (i) => encryptedBytes[i] ^ key[i % key.length],
      );

      return utf8.decode(decryptedBytes);
    } catch (_) {
      return text;
    }
  }
}
