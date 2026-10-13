import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/utils/salary_helper.dart';

void main() {
  group('SalaryHelper Consistency & Range Filter Tests', () {
    test('Standard LPA filter options are uniformly defined', () {
      const expectedOptions = [
        "All",
        "0–3 LPA",
        "3–5 LPA",
        "5–8 LPA",
        "8–12 LPA",
        "12+ LPA",
      ];
      expect(SalaryHelper.filterOptions, equals(expectedOptions));
    });

    test('parseLpa correctly extracts numeric LPA from various formats', () {
      expect(SalaryHelper.parseLpa("8 LPA"), equals(8.0));
      expect(SalaryHelper.parseLpa("₹8 LPA"), equals(8.0));
      expect(SalaryHelper.parseLpa("4.5 LPA"), equals(4.5));
      expect(SalaryHelper.parseLpa("₹12.5 LPA"), equals(12.5));
      expect(SalaryHelper.parseLpa("6"), equals(6.0));
      expect(SalaryHelper.parseLpa(""), isNull);
      expect(SalaryHelper.parseLpa(null), isNull);
      expect(SalaryHelper.parseLpa("Competitive"), isNull);
    });

    test('formatLpa standardizes display strings into ₹X LPA format', () {
      expect(SalaryHelper.formatLpa("8 LPA"), equals("₹8 LPA"));
      expect(SalaryHelper.formatLpa("₹8 LPA"), equals("₹8 LPA"));
      expect(SalaryHelper.formatLpa("4.5"), equals("₹4.5 LPA"));
      expect(SalaryHelper.formatLpa(null), equals("Competitive LPA"));
      expect(SalaryHelper.formatLpa(""), equals("Competitive LPA"));
    });

    test('Salary filter matches "All" for all salary types including null/empty', () {
      expect(SalaryHelper.matchesFilter("8 LPA", "All"), isTrue);
      expect(SalaryHelper.matchesFilter("2 LPA", "All"), isTrue);
      expect(SalaryHelper.matchesFilter(null, "All"), isTrue);
      expect(SalaryHelper.matchesFilter("", "All"), isTrue);
    });

    test('Boundary values are accurately partitioned across ranges', () {
      // 0–3 LPA range (< 3.0)
      expect(SalaryHelper.matchesFilter("2.9 LPA", "0–3 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("3.0 LPA", "0–3 LPA"), isFalse);

      // 3–5 LPA range (>= 3.0 && < 5.0)
      expect(SalaryHelper.matchesFilter("3.0 LPA", "3–5 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("4.5 LPA", "3–5 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("4.99 LPA", "3–5 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("5.0 LPA", "3–5 LPA"), isFalse);

      // 5–8 LPA range (>= 5.0 && < 8.0)
      expect(SalaryHelper.matchesFilter("5.0 LPA", "5–8 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("6.5 LPA", "5–8 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("7.99 LPA", "5–8 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("8.0 LPA", "5–8 LPA"), isFalse);

      // 8–12 LPA range (>= 8.0 && <= 12.0)
      expect(SalaryHelper.matchesFilter("8.0 LPA", "8–12 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("10 LPA", "8–12 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("12.0 LPA", "8–12 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("12.1 LPA", "8–12 LPA"), isFalse);

      // 12+ LPA range (> 12.0)
      expect(SalaryHelper.matchesFilter("12.0 LPA", "12+ LPA"), isFalse);
      expect(SalaryHelper.matchesFilter("12.5 LPA", "12+ LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("24 LPA", "12+ LPA"), isTrue);
    });

    test('Null, empty, or unparseable salaries return false for specific ranges', () {
      expect(SalaryHelper.matchesFilter(null, "3–5 LPA"), isFalse);
      expect(SalaryHelper.matchesFilter("", "5–8 LPA"), isFalse);
      expect(SalaryHelper.matchesFilter("Not Disclosed", "8–12 LPA"), isFalse);
    });

    test('Hyphen variant format matches identically to en-dash', () {
      expect(SalaryHelper.matchesFilter("4 LPA", "3-5 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("7 LPA", "5-8 LPA"), isTrue);
      expect(SalaryHelper.matchesFilter("10 LPA", "8-12 LPA"), isTrue);
    });
  });
}
