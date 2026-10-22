/// Date helpers for the weekly recap strip.
///
/// All of them work on *local midnight* days: a day is a calendar day, not a
/// 24-hour window starting at some arbitrary hour, so "the same day" means the
/// same y/m/d and nothing else.
library;

/// The local midnight that starts [d]'s calendar day.
DateTime weekMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

/// The Monday that starts the week containing [day].
DateTime startOfWeek(DateTime day) =>
    weekMidnight(day).subtract(Duration(days: day.weekday - 1));

/// Index of [day] inside a Monday-first week (0 = Monday).
int weekdayIndex(DateTime day) => day.weekday - 1;

/// Whether [a] and [b] fall on the same calendar day.
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Human label for [day]: "Tuesday 4/3".
String dayLabel(DateTime day) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return '${names[day.weekday - 1]} ${day.day}/${day.month}';
}
