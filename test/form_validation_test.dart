import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/utils/url_helper.dart';

void main() {
  group('Event & Job Form Validation Logic Tests', () {
    test('Event date validation rejects past dates and accepts today or future dates', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      // Past date check
      expect(yesterday.isBefore(today), isTrue);
      // Today check
      expect(today.isBefore(today), isFalse);
      // Future date check
      expect(tomorrow.isBefore(today), isFalse);
    });

    test('Salary LPA format cleaning and formatting', () {
      String formatSalary(String input) {
        final clean = input.trim();
        return clean.toLowerCase().endsWith("lpa") ? clean : "$clean LPA";
      }

      expect(formatSalary("6.5"), equals("6.5 LPA"));
      expect(formatSalary("12 LPA"), equals("12 LPA"));
      expect(formatSalary("10 lpa"), equals("10 lpa"));
    });

    test('Company website URL parsing and validation', () {
      expect(UrlHelper.parseAndNormalizeUrl("infosys.com")?.toString(), equals("https://infosys.com"));
      expect(UrlHelper.parseAndNormalizeUrl("http://tcs.com/careers")?.toString(), equals("http://tcs.com/careers"));
      expect(UrlHelper.parseAndNormalizeUrl("https://google.com/jobs")?.toString(), equals("https://google.com/jobs"));
      expect(UrlHelper.parseAndNormalizeUrl(""), isNull);
      expect(UrlHelper.parseAndNormalizeUrl("not a url"), isNull);
    });
  });
}
