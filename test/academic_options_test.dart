import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/utils/academic_options.dart';

void main() {
  group('AcademicOptions Tests', () {
    test('getBatchYears returns descending list of years including range', () {
      final years = AcademicOptions.getBatchYears();
      expect(years.isNotEmpty, isTrue);
      expect(years.first >= 2030, isTrue);
      expect(years.last, equals(1980));
      expect(years[0] > years[1], isTrue);
    });

    test('getBatchYears incorporates legacy customYear not in default range', () {
      final years = AcademicOptions.getBatchYears(customYear: 1974);
      expect(years.contains(1974), isTrue);
      expect(years.last, equals(1974));
    });

    test('getDegrees includes default degrees, custom degree, and Other option', () {
      final degrees = AcademicOptions.getDegrees(customDegree: 'Ph.D Computer Science');
      expect(degrees.contains('MCA'), isTrue);
      expect(degrees.contains('BCA'), isTrue);
      expect(degrees.contains('Ph.D Computer Science'), isTrue);
      expect(degrees.contains(AcademicOptions.otherOption), isTrue);
    });

    test('getDepartmentsForDegree filters departments appropriately and includes Other', () {
      final mcaDepts = AcademicOptions.getDepartmentsForDegree(degree: 'MCA');
      expect(mcaDepts.contains('MCA'), isTrue);
      expect(mcaDepts.contains('IT'), isTrue);
      expect(mcaDepts.contains('CS'), isTrue);
      expect(mcaDepts.contains('Commerce'), isFalse);
      expect(mcaDepts.contains(AcademicOptions.otherOption), isTrue);

      final mbaDepts = AcademicOptions.getDepartmentsForDegree(degree: 'MBA');
      expect(mbaDepts.contains('MBA'), isTrue);
      expect(mbaDepts.contains('Management'), isTrue);
      expect(mbaDepts.contains('MCA'), isFalse);
      expect(mbaDepts.contains(AcademicOptions.otherOption), isTrue);
    });

    test('isPredefinedDegree and isPredefinedDepartment accurately identify default options', () {
      expect(AcademicOptions.isPredefinedDegree('MCA'), isTrue);
      expect(AcademicOptions.isPredefinedDegree('B.Tech'), isTrue);
      expect(AcademicOptions.isPredefinedDegree('Ph.D Computer Science'), isFalse);
      expect(AcademicOptions.isPredefinedDegree('Other'), isFalse);
      expect(AcademicOptions.isPredefinedDegree(null), isFalse);

      expect(AcademicOptions.isPredefinedDepartment('MCA', 'MCA'), isTrue);
      expect(AcademicOptions.isPredefinedDepartment('MCA', 'IT'), isTrue);
      expect(AcademicOptions.isPredefinedDepartment('MCA', 'Civil'), isFalse);
      expect(AcademicOptions.isPredefinedDepartment('MCA', 'Other'), isFalse);
      expect(AcademicOptions.isPredefinedDepartment(null, null), isFalse);
    });

    test('isDepartmentValidForDegree returns true for valid combination including Other', () {
      expect(AcademicOptions.isDepartmentValidForDegree('MCA', 'MCA'), isTrue);
      expect(AcademicOptions.isDepartmentValidForDegree('MCA', 'IT'), isTrue);
      expect(AcademicOptions.isDepartmentValidForDegree('MCA', AcademicOptions.otherOption), isTrue);
      expect(AcademicOptions.isDepartmentValidForDegree('MCA', 'Commerce'), isFalse);
      expect(AcademicOptions.isDepartmentValidForDegree(null, null), isFalse);
    });
  });
}
