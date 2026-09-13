class SalaryHelper {
  /// Formats any salary string into clean "₹X LPA" standard.
  /// Examples:
  /// "3.5" -> "₹3.5 LPA"
  /// "6" -> "₹6 LPA"
  /// "4.5 LPA" -> "₹4.5 LPA"
  /// "₹8 LPA" -> "₹8 LPA"
  static String formatLpa(String? salary) {
    if (salary == null || salary.trim().isEmpty) {
      return "Competitive LPA";
    }

    final clean = salary.trim();

    // Already has standard format: "₹X LPA"
    if (clean.startsWith("₹") && clean.toLowerCase().endsWith("lpa")) {
      return clean;
    }

    final lpaValue = parseLpa(clean);
    if (lpaValue == null) {
      return clean.toLowerCase().contains("lpa") ? clean : "₹$clean LPA";
    }

    final formattedNumber = (lpaValue % 1 == 0)
        ? lpaValue.toInt().toString()
        : lpaValue.toString();

    return "₹$formattedNumber LPA";
  }

  /// Extracts numeric LPA value for calculations and filtering.
  static double? parseLpa(String? salary) {
    if (salary == null || salary.trim().isEmpty) return null;

    final s = salary.trim().replaceAll("₹", "").replaceAll(",", "");
    
    // Extract first numeric group (including optional decimals)
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(s);
    if (match == null) return null;

    final numVal = double.tryParse(match.group(1)!);
    if (numVal == null) return null;

    // Legacy migration handling:
    // If the number is huge (e.g. 100000 or 10000 monthly), convert safely:
    if (numVal > 10000) {
      // e.g. 100000 / 100000 = 1.0 LPA
      return double.parse((numVal / 100000).toStringAsFixed(2));
    } else if (numVal > 100 && numVal <= 10000) {
      // e.g. 10000 monthly -> 10000 * 12 / 100000 = 1.2 LPA
      return double.parse((numVal * 12 / 100000).toStringAsFixed(2));
    }

    return numVal;
  }

  /// LPA filter range options for Dropdowns and Chips
  static const List<String> filterOptions = [
    "All",
    "0–3 LPA",
    "3–5 LPA",
    "5–8 LPA",
    "8–12 LPA",
    "12+ LPA",
  ];

  /// Evaluates whether a salary matches the selected filter option.
  static bool matchesFilter(String? salary, String filter) {
    if (filter == "All" || filter.trim().isEmpty) return true;

    final lpa = parseLpa(salary);
    if (lpa == null) return false;

    switch (filter) {
      case "0–3 LPA":
      case "0-3 LPA":
        return lpa < 3.0;
      case "3–5 LPA":
      case "3-5 LPA":
        return lpa >= 3.0 && lpa < 5.0;
      case "5–8 LPA":
      case "5-8 LPA":
        return lpa >= 5.0 && lpa < 8.0;
      case "8–12 LPA":
      case "8-12 LPA":
        return lpa >= 8.0 && lpa <= 12.0;
      case "12+ LPA":
        return lpa > 12.0;
      default:
        return true;
    }
  }
}
