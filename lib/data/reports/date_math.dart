/// Calendar-day arithmetic that is correct across daylight-saving transitions.
///
/// `DateTime` in local time is a wall clock: adding `Duration(days: 1)` adds
/// exactly 24 hours, so on a spring-forward day that lands on 23:00 the
/// *previous* day. `difference().inDays` has the mirror problem — a month
/// containing a transition measures 30 days 23 hours and truncates to 30.
///
/// Both failures are silent and off-by-one, which is exactly the kind of bug a
/// budget or a "17 days remaining" label must not have. Every date-only
/// calculation in the reporting layer therefore goes through this module,
/// which keeps the *calendar* day as the unit instead of the elapsed duration.
library;

/// Strips the time component, keeping the local calendar day at midnight.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Shifts by whole calendar days, preserving the wall-clock time-of-day.
///
/// Uses the `DateTime(y, m, d + n)` constructor, which normalises out-of-range
/// day numbers (day 0 = last day of the previous month, day 32 = early next
/// month) and is immune to DST because the constructor takes calendar fields.
DateTime addDays(DateTime value, int days) => DateTime(
  value.year,
  value.month,
  value.day + days,
  value.hour,
  value.minute,
);

/// Whole calendar days from [from] to [to]; negative when [to] precedes [from].
///
/// Computed in UTC so neither side can be distorted by a transition.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
