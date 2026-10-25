import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService - Core Persistence & Account Isolation', () {
    const userA = 'alice@gls.edu';
    const userB = 'bob@gls.edu';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CacheService.setDeviceKeyForTest(List<int>.generate(32, (i) => (i * 3 + 7) % 256));
      await CacheService.clearAll();
    });

    tearDown(() async {
      CacheService.clearKeyCacheForTest();
    });

    test('Cache persistence and retrieval of non-sensitive data (Events/Jobs)', () async {
      final sampleEvents = [
        {'id': 1, 'title': 'Tech Symposium 2026', 'department': 'Computer Science'},
        {'id': 2, 'title': 'Alumni Meetup', 'department': 'All'},
      ];

      final saved = await CacheService.save(
        key: 'events_all',
        userEmail: userA,
        rawJson: sampleEvents,
        isSensitive: false,
      );
      expect(saved, isTrue);

      final result = await CacheService.get<List<dynamic>>(
        key: 'events_all',
        userEmail: userA,
        isSensitive: false,
      );

      expect(result, isNotNull);
      expect(result!.data.length, equals(2));
      expect(result.data[0]['title'], equals('Tech Symposium 2026'));
      expect(result.timeAgoFormatted, equals('just now'));
    });

    test('Account-switch isolation: User B cannot access User A cache', () async {
      final aliceJobs = [
        {'jobId': 'job_101', 'title': 'Software Engineer', 'company': 'Acme Corp'},
      ];

      await CacheService.save(
        key: 'jobs_all',
        userEmail: userA,
        rawJson: aliceJobs,
        isSensitive: false,
      );

      // User A reads their own cache -> succeeds
      final aliceResult = await CacheService.get<List<dynamic>>(
        key: 'jobs_all',
        userEmail: userA,
        isSensitive: false,
      );
      expect(aliceResult, isNotNull);
      expect(aliceResult!.data.length, equals(1));

      // User B reads same key -> isolated, returns null
      final bobResult = await CacheService.get<List<dynamic>>(
        key: 'jobs_all',
        userEmail: userB,
        isSensitive: false,
      );
      expect(bobResult, isNull);
    });

    test('Logout isolation: clearAll removes all cached data across accounts', () async {
      await CacheService.save(
        key: 'events_all',
        userEmail: userA,
        rawJson: [{'id': 1}],
      );
      await CacheService.save(
        key: 'jobs_all',
        userEmail: userB,
        rawJson: [{'jobId': 'j2'}],
      );

      // Call logout cleanup
      await CacheService.clearAll();

      // Verify both caches are purged
      expect(await CacheService.get(key: 'events_all', userEmail: userA), isNull);
      expect(await CacheService.get(key: 'jobs_all', userEmail: userB), isNull);
    });

    test('User-specific cache clear leaves other users unaffected', () async {
      await CacheService.save(
        key: 'events_all',
        userEmail: userA,
        rawJson: [{'id': 1}],
      );
      await CacheService.save(
        key: 'events_all',
        userEmail: userB,
        rawJson: [{'id': 2}],
      );

      await CacheService.clearUserCache(userA);

      expect(await CacheService.get(key: 'events_all', userEmail: userA), isNull);
      final bobResult = await CacheService.get<List<dynamic>>(key: 'events_all', userEmail: userB);
      expect(bobResult, isNotNull);
      expect(bobResult!.data[0]['id'], equals(2));
    });

    test('Distinguish successful empty response from network failure', () async {
      // 1. Initial valid cache
      await CacheService.save(
        key: 'events_all',
        userEmail: userA,
        rawJson: [{'id': 100, 'title': 'Hackathon'}],
      );

      // 2. Server successfully responds with empty list []
      final emptyList = <dynamic>[];
      await CacheService.save(
        key: 'events_all',
        userEmail: userA,
        rawJson: emptyList,
      );

      final cachedEmpty = await CacheService.get<List<dynamic>>(
        key: 'events_all',
        userEmail: userA,
      );
      // Empty response is preserved and distinguished from null (network failure)
      expect(cachedEmpty, isNotNull);
      expect(cachedEmpty!.data, isEmpty);
    });

    test('Sequencing protection: older slow responses cannot overwrite newer cache', () async {
      final now = DateTime.now();

      // Newer response arrives and saves
      final newerTime = now.subtract(const Duration(seconds: 2));
      await CacheService.save(
        key: 'jobs_all',
        userEmail: userA,
        rawJson: [{'jobId': 'new_job'}],
        requestStartTime: newerTime,
      );

      // Older slow request (started 10s ago) arrives late and attempts to save
      final olderTime = now.subtract(const Duration(seconds: 10));
      final savedOlder = await CacheService.save(
        key: 'jobs_all',
        userEmail: userA,
        rawJson: [{'jobId': 'stale_old_job'}],
        requestStartTime: olderTime,
      );

      expect(savedOlder, isFalse, reason: 'Older response must be rejected by sequencing check');

      final current = await CacheService.get<List<dynamic>>(key: 'jobs_all', userEmail: userA);
      expect(current!.data[0]['jobId'], equals('new_job'));
    });

    test('Concurrency deduplication merges simultaneous in-flight requests', () async {
      int callCount = 0;

      Future<String> slowNetworkCall() async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'network_data_$callCount';
      }

      // Fire 3 concurrent calls to the same dedup key
      final results = await Future.wait([
        CacheService.deduplicate('test_action', slowNetworkCall),
        CacheService.deduplicate('test_action', slowNetworkCall),
        CacheService.deduplicate('test_action', slowNetworkCall),
      ]);

      expect(callCount, equals(1), reason: 'Only 1 network call should execute');
      expect(results[0], equals('network_data_1'));
      expect(results[1], equals('network_data_1'));
      expect(results[2], equals('network_data_1'));
    });
  });

  group('CacheService - Sensitive Profile Encryption (AES-256-GCM)', () {
    const userA = 'student@gls.edu';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CacheService.setDeviceKeyForTest(List<int>.generate(32, (i) => (i * 5 + 17) % 256));
      await CacheService.clearAll();
    });

    tearDown(() async {
      CacheService.clearKeyCacheForTest();
    });

    test('Sensitive profile data is encrypted with AES-256-GCM and decrypted faithfully', () async {
      final sensitiveProfile = {
        'userName': 'Jane Doe',
        'email': userA,
        'contactNumber': '+91 9876543210',
        'universityNumber': 'GLS-2024-MCA-042',
        'skills': 'Flutter, Dart, Spring Boot',
        'currentCity': 'Ahmedabad',
      };

      final saved = await CacheService.save(
        key: 'profile_student',
        userEmail: userA,
        rawJson: sensitiveProfile,
        isSensitive: true,
      );
      expect(saved, isTrue);

      // Verify the raw stored value in secure storage is ciphertext, NOT plaintext
      final storedString = CacheService.getTestSecureStorageValue('gls_cache_${userA}_profile_student');

      expect(storedString, isNotNull);
      // Must start with v1:enc: format
      expect(storedString!.startsWith('v1:enc:'), isTrue);
      // Plaintext sensitive strings must NOT appear in stored payload
      expect(storedString.contains('+91 9876543210'), isFalse);
      expect(storedString.contains('GLS-2024-MCA-042'), isFalse);
      expect(storedString.contains('Jane Doe'), isFalse);

      // Verify successful decrypted retrieval
      final result = await CacheService.get<Map<String, dynamic>>(
        key: 'profile_student',
        userEmail: userA,
        isSensitive: true,
      );

      expect(result, isNotNull);
      expect(result!.data['userName'], equals('Jane Doe'));
      expect(result.data['contactNumber'], equals('+91 9876543210'));
      expect(result.data['universityNumber'], equals('GLS-2024-MCA-042'));
    });

    test('Fresh CSPRNG IVs produce different ciphertexts for identical sensitive payloads', () async {
      final profile = {'userName': 'Test User', 'contactNumber': '1234567890'};

      await CacheService.save(
        key: 'prof_1',
        userEmail: userA,
        rawJson: profile,
        isSensitive: true,
      );
      await CacheService.save(
        key: 'prof_2',
        userEmail: userA,
        rawJson: profile,
        isSensitive: true,
      );

      final payload1 = CacheService.getTestSecureStorageValue('gls_cache_${userA}_prof_1')!;
      final payload2 = CacheService.getTestSecureStorageValue('gls_cache_${userA}_prof_2')!;

      expect(payload1, isNot(equals(payload2)), reason: 'Each encryption must use a unique 96-bit IV');
    });

    test('Tampered sensitive ciphertext fails authentication and returns null safely', () async {
      final profile = {'userName': 'Alice', 'contactNumber': '9999999999'};
      await CacheService.save(
        key: 'prof_tamper',
        userEmail: userA,
        rawJson: profile,
        isSensitive: true,
      );

      final storageKey = 'gls_cache_${userA}_prof_tamper';
      final raw = CacheService.getTestSecureStorageValue(storageKey)!;

      // Mutate the ciphertext bytes in base64
      final tampered = raw.substring(0, raw.length - 6) + 'XXXX==';
      CacheService.setTestSecureStorageValue(storageKey, tampered);
      CacheService.clearMemoryCache();

      // Attempted retrieval of tampered data must fail safely
      final result = await CacheService.get<Map<String, dynamic>>(
        key: 'prof_tamper',
        userEmail: userA,
        isSensitive: true,
      );

      expect(result, isNull, reason: 'Tampered ciphertext must fail GCM MAC verification');
    });

    test('Mismatched device key returns null gracefully', () async {
      final profile = {'userName': 'Alice'};
      await CacheService.save(
        key: 'prof_key_mismatch',
        userEmail: userA,
        rawJson: profile,
        isSensitive: true,
      );

      // Change device key (simulating foreign device read)
      CacheService.setDeviceKeyForTest(List<int>.generate(32, (i) => (i * 9 + 41) % 256));

      final result = await CacheService.get<Map<String, dynamic>>(
        key: 'prof_key_mismatch',
        userEmail: userA,
        isSensitive: true,
      );

      expect(result, isNull, reason: 'Wrong device key must fail GCM authentication safely');
    });
  });
}
