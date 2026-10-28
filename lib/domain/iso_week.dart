/// ISO-8601 week key in local time, for example `2026-W44`.
///
/// Weeks start on Monday. The free fake-call allowance resets when this key
/// changes, which is Monday 00:00 in the device timezone.
String isoWeekKey(DateTime local) {
  final day = DateTime(local.year, local.month, local.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final yearStart = DateTime(thursday.year, 1, 1);
  final ordinal = thursday.difference(yearStart).inDays + 1;
  final week = ((ordinal - 1) ~/ 7) + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}
