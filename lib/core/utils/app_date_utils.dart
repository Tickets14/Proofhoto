import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  /// Returns today in UTC midnight (for consistent date comparison).
  static DateTime today() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Strips time from a UTC date.
  static DateTime utcDate(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);

  /// Day-of-week as 1=Mon … 7=Sun (matches DateTime.weekday).
  static int weekday(DateTime dt) => dt.weekday;

  /// Friendly date string: "Today", "Yesterday", or "Mar 5, 2026".
  static String friendlyDate(DateTime dt) {
    final d = utcDate(dt.toLocal());
    final t = today();
    if (d == t) return 'Today';
    if (d == t.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(d);
  }

  /// Time formatted as "8:30 AM".
  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt.toLocal());

  /// Date formatted as "Mon, Mar 5".
  static String formatShortDate(DateTime dt) =>
      DateFormat('EEE, MMM d').format(dt.toLocal());

  /// Full datetime: "Mar 5, 2026 at 8:30 AM".
  static String formatDateTime(DateTime dt) =>
      DateFormat("MMM d, yyyy 'at' h:mm a").format(dt.toLocal());

  /// Returns the start of the week (Monday) for the given date.
  static DateTime startOfWeek(DateTime dt) {
    final d = utcDate(dt);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Returns a list of the last [n] dates (UTC, midnight), newest first.
  static List<DateTime> lastNDays(int n) {
    final t = today();
    return List.generate(n, (i) => t.subtract(Duration(days: i)));
  }

  /// Returns whether two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the number of calendar days between two dates (unsigned).
  static int daysBetween(DateTime a, DateTime b) {
    final da = utcDate(a);
    final db = utcDate(b);
    return (da.difference(db).inDays).abs();
  }

  /// Parses "HH:mm" time string into hours and minutes.
  static (int hours, int minutes) parseTimeString(String time) {
    final parts = time.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Returns greeting based on current hour.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Formats the current date as "Friday, March 7".
  static String todayFormatted() =>
      DateFormat('EEEE, MMMM d').format(DateTime.now());

  /// Returns all days in the given month.
  static List<DateTime> daysInMonth(int year, int month) {
    final first = DateTime.utc(year, month, 1);
    final last = DateTime.utc(year, month + 1, 0);
    return List.generate(
      last.day,
      (i) => first.add(Duration(days: i)),
    );
  }
}
