/// Academic constants and helper utilities for Degree, Department, and Batch Year.
class AcademicOptions {
  static const String otherOption = 'Other';

  static const List<String> defaultDegrees = [
    'MCA',
    'BCA',
    'MBA',
    'BBA',
    'B.Tech',
    'M.Tech',
    'B.Sc. IT',
    'M.Sc. IT',
    'B.Com',
    'M.Com',
  ];

  static const List<String> defaultDepartments = [
    'MCA',
    'BCA',
    'MBA',
    'IT',
    'CS',
    'Management',
    'Commerce',
  ];

  static const Map<String, List<String>> degreeToDepartments = {
    'MCA': ['MCA', 'IT', 'CS'],
    'BCA': ['BCA', 'IT', 'CS'],
    'MBA': ['MBA', 'Management'],
    'BBA': ['MBA', 'Management'],
    'B.Tech': ['IT', 'CS'],
    'M.Tech': ['IT', 'CS'],
    'B.Sc. IT': ['IT', 'CS'],
    'M.Sc. IT': ['IT', 'CS'],
    'B.Com': ['Commerce', 'Management'],
    'M.Com': ['Commerce', 'Management'],
  };

  /// Generates batch years in descending order from (currentYear + 6) down to 1980.
  /// If [customYear] is provided and valid, it is guaranteed to be in the returned list.
  static List<int> getBatchYears({int? customYear}) {
    final currentYear = DateTime.now().year;
    final maxYear = currentYear > 2026 ? currentYear + 6 : 2032;
    const minYear = 1980;

    final years = <int>[];
    for (int y = maxYear; y >= minYear; y--) {
      years.add(y);
    }

    if (customYear != null && customYear > 1900 && !years.contains(customYear)) {
      years.add(customYear);
      years.sort((a, b) => b.compareTo(a));
    }

    return years;
  }

  /// Returns valid degrees with "Other" option appended.
  /// If [customDegree] is provided, it is retained for compatibility.
  static List<String> getDegrees({
    String? customDegree,
    bool includeOther = true,
  }) {
    final list = List<String>.from(defaultDegrees);
    if (customDegree != null &&
        customDegree.trim().isNotEmpty &&
        customDegree.trim() != otherOption &&
        !list.contains(customDegree.trim())) {
      list.add(customDegree.trim());
    }
    if (includeOther && !list.contains(otherOption)) {
      list.add(otherOption);
    }
    return list;
  }

  /// Returns valid departments for the selected [degree], ensuring "Other" option
  /// is appended so custom departments can be entered.
  static List<String> getDepartmentsForDegree({
    String? degree,
    String? customDepartment,
    bool includeOther = true,
  }) {
    List<String> list;
    if (degree != null &&
        degree.trim() != otherOption &&
        degreeToDepartments.containsKey(degree.trim())) {
      list = List<String>.from(degreeToDepartments[degree.trim()]!);
    } else {
      list = List<String>.from(defaultDepartments);
    }

    if (customDepartment != null &&
        customDepartment.trim().isNotEmpty &&
        customDepartment.trim() != otherOption &&
        !list.contains(customDepartment.trim())) {
      list.add(customDepartment.trim());
    }

    if (includeOther && !list.contains(otherOption)) {
      list.add(otherOption);
    }

    return list;
  }

  /// Checks whether [degree] is among the predefined default degrees.
  static bool isPredefinedDegree(String? degree) {
    if (degree == null || degree.trim().isEmpty) return false;
    return defaultDegrees.contains(degree.trim());
  }

  /// Checks whether [department] is among the predefined departments for [degree].
  static bool isPredefinedDepartment(String? degree, String? department) {
    if (department == null || department.trim().isEmpty) return false;
    final trimmedDept = department.trim();
    if (trimmedDept == otherOption) return false;

    if (degree != null &&
        degree.trim() != otherOption &&
        degreeToDepartments.containsKey(degree.trim())) {
      return degreeToDepartments[degree.trim()]!.contains(trimmedDept);
    }
    return defaultDepartments.contains(trimmedDept);
  }

  /// Checks whether [department] is valid for [degree].
  static bool isDepartmentValidForDegree(String? degree, String? department) {
    if (department == null || department.trim().isEmpty) return false;
    final validDepts = getDepartmentsForDegree(degree: degree);
    return validDepts.contains(department.trim());
  }
}
