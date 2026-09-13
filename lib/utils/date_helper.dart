class DateHelper {
  /// Returns true if the target date has passed (i.e. yesterday or earlier).
  /// If the date is today, it is considered active/open until the day ends.
  static bool isExpired(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;

    try {
      final clean = dateStr.trim().split("T").first;
      final parsed = DateTime.parse(clean);
      final now = DateTime.now();

      final targetDate = DateTime(parsed.year, parsed.month, parsed.day);
      final today = DateTime(now.year, now.month, now.day);

      return today.isAfter(targetDate);
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the date is exactly today.
  static bool isToday(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;

    try {
      final clean = dateStr.trim().split("T").first;
      final parsed = DateTime.parse(clean);
      final now = DateTime.now();

      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    } catch (_) {
      return false;
    }
  }

  /// Professional status string for Jobs
  static String getJobStatus(String? lastDateToApply) {
    if (lastDateToApply == null || lastDateToApply.trim().isEmpty) {
      return "Active";
    }

    if (isExpired(lastDateToApply)) {
      return "Applications Closed";
    } else if (isToday(lastDateToApply)) {
      return "Closing Today";
    } else {
      return "Active";
    }
  }

  /// Professional status string for Events
  static String getEventStatus(String? eventDate) {
    if (eventDate == null || eventDate.trim().isEmpty) {
      return "Upcoming";
    }

    if (isExpired(eventDate)) {
      return "Event Concluded";
    } else if (isToday(eventDate)) {
      return "Happening Today";
    } else {
      return "Upcoming";
    }
  }

  /// Formats date string to friendly readable format like "15 Oct 2026"
  static String formatFriendlyDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return "N/A";

    try {
      final clean = dateStr.trim().split("T").first;
      final dt = DateTime.parse(clean);
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }
}
