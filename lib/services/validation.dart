class Validation {
  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Vnesi veljaven e-poštni naslov.';
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Obvezno polje.' : null;
  static String? password(String? value) =>
      (value?.length ?? 0) < 8 ? 'Geslo naj vsebuje vsaj 8 znakov.' : null;
  static bool interval(DateTime start, DateTime end) =>
      end.isAfter(start) && end.difference(start) <= const Duration(hours: 24);
  static bool overlaps(DateTime a, DateTime b, DateTime c, DateTime d) =>
      a.isBefore(d) && c.isBefore(b);
  static double workHours(DateTime start, DateTime end, int breakMinutes) {
    if (!interval(start, end) ||
        breakMinutes < 0 ||
        breakMinutes >= end.difference(start).inMinutes) {
      throw ArgumentError('Neveljaven interval ali odmor.');
    }
    return (end.difference(start).inMinutes - breakMinutes) / 60;
  }

  static DateTime weekStart(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).subtract(Duration(days: utc.weekday - 1));
  }

  static double hoursInWeek(DateTime start, DateTime end, DateTime week) {
    final finish = week.add(const Duration(days: 7));
    final a = start.isAfter(week) ? start : week;
    final b = end.isBefore(finish) ? end : finish;
    return b.isAfter(a) ? b.difference(a).inMinutes / 60 : 0;
  }
}
