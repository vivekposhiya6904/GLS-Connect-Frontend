/// Canonical dataset of Indian cities and work locations for Alumni Connect
/// Standardized, sorted A to Z, and deduplicated for consistency across jobs, events, and filters.
class CityConstants {
  CityConstants._();

  /// Canonical list of major Indian cities, sorted alphabetically A-Z.
  static const List<String> canonicalCities = [
    "Agra",
    "Ahmedabad",
    "Amritsar",
    "Bengaluru (Bangalore)",
    "Bhopal",
    "Bhubaneswar",
    "Chandigarh",
    "Chennai",
    "Coimbatore",
    "Dehradun",
    "Delhi NCR",
    "Gandhinagar",
    "Gurugram (Gurgaon)",
    "Guwahati",
    "Hybrid",
    "Hyderabad",
    "Indore",
    "Jaipur",
    "Jodhpur",
    "Kanpur",
    "Kochi (Cochin)",
    "Kolkata",
    "Lucknow",
    "Ludhiana",
    "Madurai",
    "Mangalore",
    "Mumbai",
    "Nagpur",
    "Nashik",
    "Navi Mumbai",
    "Noida",
    "Patna",
    "Pune",
    "Raipur",
    "Rajkot",
    "Ranchi",
    "Remote",
    "Surat",
    "Thiruvananthapuram",
    "Udaipur",
    "Vadodara",
    "Varanasi",
    "Vijayawada",
    "Visakhapatnam",
  ];

  /// Get dropdown items ensuring any existing value from edit records is preserved and valid
  static List<String> getDropdownOptions({String? currentCity}) {
    final Set<String> citySet = Set<String>.from(canonicalCities);
    if (currentCity != null && currentCity.trim().isNotEmpty) {
      final trimmed = currentCity.trim();
      // Match existing value or add it seamlessly if it's a legacy value
      final existingMatch = canonicalCities.firstWhere(
        (c) => c.toLowerCase() == trimmed.toLowerCase(),
        orElse: () => trimmed,
      );
      citySet.add(existingMatch);
    }
    final sorted = citySet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  /// Match an initial value to the canonical list (handling legacy names like Bangalore or Delhi)
  static String? matchCanonicalCity(String? city) {
    if (city == null || city.trim().isEmpty) return null;
    final lower = city.trim().toLowerCase();
    for (final c in canonicalCities) {
      if (c.toLowerCase() == lower) return c;
      if (lower == "bangalore" && c.contains("Bengaluru")) return c;
      if (lower == "delhi" && c.contains("Delhi")) return c;
      if (lower == "gurgaon" && c.contains("Gurugram")) return c;
      if (lower == "cochin" && c.contains("Kochi")) return c;
    }
    return city.trim();
  }

  /// Filter options for job and event filters with "All" as first item
  static List<String> get filterCities {
    return ["All", ...canonicalCities];
  }
}
