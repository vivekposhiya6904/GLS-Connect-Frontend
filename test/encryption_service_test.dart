import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/services/encryption_service.dart';

void main() {
  group('EncryptionService - AES-256-GCM & Compatibility', () {
    const user1 = 'alice@gls.edu';
    const user2 = 'bob@gls.edu';

    // 32-byte (256-bit) test keys
    final testKeyA = List<int>.generate(32, (i) => (i * 7 + 13) % 256);
    final testKeyB = List<int>.generate(32, (i) => (i * 11 + 29) % 256);

    setUp(() {
      EncryptionService.clearKeyCacheForTest();
      EncryptionService.setConversationKeyForTest(user1, user2, testKeyA);
    });

    tearDown(() {
      EncryptionService.clearKeyCacheForTest();
    });

    test('Round-trip encryption and decryption with AES-256-GCM', () async {
      const originalText = 'Hello Bob, this is a highly confidential message! 🚀';

      final encrypted = await EncryptionService.encrypt(originalText, user1, user2);
      expect(encrypted.startsWith(EncryptionService.v2Prefix), isTrue);

      final decrypted = await EncryptionService.decrypt(encrypted, user1, user2);
      expect(decrypted, equals(originalText));
    });

    test('Nonce uniqueness: repeated encryptions produce different ciphertexts', () async {
      const message = 'Same plaintext content';

      final enc1 = await EncryptionService.encrypt(message, user1, user2);
      final enc2 = await EncryptionService.encrypt(message, user1, user2);

      expect(enc1, isNot(equals(enc2)), reason: 'Each encryption must use a fresh CSPRNG nonce');

      expect(await EncryptionService.decrypt(enc1, user1, user2), equals(message));
      expect(await EncryptionService.decrypt(enc2, user1, user2), equals(message));
    });

    test('Wrong key rejection: decrypting with mismatched key fails safely', () async {
      const message = 'Top secret strategy';
      final encrypted = await EncryptionService.encrypt(message, user1, user2);

      // Overwrite with key B
      EncryptionService.setConversationKeyForTest(user1, user2, testKeyB);

      final result = await EncryptionService.decrypt(encrypted, user1, user2);
      expect(result, equals(EncryptionService.unableToDecrypt));
    });

    test('Tampered ciphertext rejection: modified ciphertext fails authentication', () async {
      const message = 'Transfer \$1,000 to Alice';
      final encrypted = await EncryptionService.encrypt(message, user1, user2);

      final base64Payload = encrypted.substring(EncryptionService.v2Prefix.length);
      final bytes = base64Decode(base64Payload);

      // Tamper with a byte in the ciphertext region (between byte 12 and byte length-16)
      bytes[15] ^= 0xFF;
      final tamperedEncrypted = "${EncryptionService.v2Prefix}${base64Encode(bytes)}";

      final result = await EncryptionService.decrypt(tamperedEncrypted, user1, user2);
      expect(result, equals(EncryptionService.unableToDecrypt));
    });

    test('Tampered MAC tag rejection: modified authentication tag fails authentication', () async {
      const message = 'Integrity test message';
      final encrypted = await EncryptionService.encrypt(message, user1, user2);

      final base64Payload = encrypted.substring(EncryptionService.v2Prefix.length);
      final bytes = base64Decode(base64Payload);

      // Tamper with the last byte (MAC tag region)
      bytes[bytes.length - 1] ^= 0x01;
      final tamperedEncrypted = "${EncryptionService.v2Prefix}${base64Encode(bytes)}";

      final result = await EncryptionService.decrypt(tamperedEncrypted, user1, user2);
      expect(result, equals(EncryptionService.unableToDecrypt));
    });

    test('Malformed payload handling: truncated or invalid input returns safe error', () async {
      // 1. Truncated payload less than 28 bytes
      final tooShortBytes = List<int>.generate(20, (i) => i);
      final shortEncrypted = "${EncryptionService.v2Prefix}${base64Encode(tooShortBytes)}";
      expect(await EncryptionService.decrypt(shortEncrypted, user1, user2),
          equals(EncryptionService.unableToDecrypt));

      // 2. Corrupt base64
      const corruptEncrypted = "${EncryptionService.v2Prefix}not-valid-base64!@#\$%";
      expect(await EncryptionService.decrypt(corruptEncrypted, user1, user2),
          equals(EncryptionService.unableToDecrypt));
    });

    test('Legacy XOR backward compatibility: decrypts messages with "ENC:" prefix', () async {
      const legacyMessage = 'This is an old message encrypted with legacy XOR cipher';

      // Generate legacy ciphertext manually using legacy algorithm
      final emails = [user1.trim().toLowerCase(), user2.trim().toLowerCase()]..sort();
      final combined = "${emails[0]}:${emails[1]}:GLS_CONNECT_E2EE_KEY_2026";
      final legacyKey = sha256.convert(utf8.encode(combined)).bytes;
      final textBytes = utf8.encode(legacyMessage);
      final encryptedBytes = List<int>.generate(
        textBytes.length,
        (i) => textBytes[i] ^ legacyKey[i % legacyKey.length],
      );
      final legacyCiphertext = "ENC:${base64Encode(encryptedBytes)}";

      final decrypted = await EncryptionService.decrypt(legacyCiphertext, user1, user2);
      expect(decrypted, equals(legacyMessage));
    });

    test('Plaintext compatibility: unencrypted messages without prefix returned as-is', () async {
      const rawText = 'Just a standard plain text notification';
      final result = await EncryptionService.decrypt(rawText, user1, user2);
      expect(result, equals(rawText));
    });

    test('Missing key handling: missing key throws on encrypt and returns error on decrypt', () async {
      EncryptionService.clearKeyCacheForTest();

      // Encrypt without key should throw StateError
      expect(
        () async => await EncryptionService.encrypt('Hello', 'stranger1@gls.edu', 'stranger2@gls.edu'),
        throwsA(isA<StateError>()),
      );

      // Decrypt without key should safely return unableToDecrypt
      const dummyV2 = "v2:aes-gcm:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
      final result = await EncryptionService.decrypt(dummyV2, 'stranger1@gls.edu', 'stranger2@gls.edu');
      expect(result, equals(EncryptionService.unableToDecrypt));
    });
  });
}
