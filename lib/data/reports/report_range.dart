import 'package:walt/data/reports/date_math.dart';

import 'report_period.dart';

/// An inclusive, half-open date range anchored on a calendar period.
///
/// [start] is midnight of the first day of the period, [endExclusive] is
/// midnight of the first day of the *next* period. Using an exclusive upper
/// bound avoids the "23:59:59 misses the last millisecond" class of bug.
class ReportRange {
  const ReportRange({
    required this.period,
    required this.anchor,
    required this.start,
    required this.endExclusive,
  });

  final ReportPeriod period;
  final DateTime anchor;
  final DateTime start;
  final DateTime endExclusive;

  static DateTime _midnight(DateTime d) => dateOnly(d);

  /// Monday-based start of the week containing [anchor].
  static DateTime startOfWeek(DateTime anchor) {
    final day = _midnight(anchor);
    // DateTime.weekday: Monday == 1 ... Sunday == 7.
    return addDays(day, -(day.weekday - 1));
  }

  /// Resolves the range for [period] containing [anchor].
  factory ReportRange.forPeriod(ReportPeriod period, DateTime anchor) {
    final day = _midnight(anchor);
    return switch (period) {
      ReportPeriod.week => ReportRange(
        period: period,
        anchor: day,
        start: startOfWeek(day),
        endExclusive: addDays(startOfWeek(day), 7),
      ),
      ReportPeriod.month => ReportRange(
        period: period,
        anchor: day,
        start: DateTime(day.year, day.month, 1),
        endExclusive: DateTime(day.year, day.month + 1, 1),
      ),
      ReportPeriod.year => ReportRange(
        period: period,
        anchor: day,
        start: DateTime(day.year, 1, 1),
        endExclusive: DateTime(day.year + 1, 1, 1),
      ),
    };
  }

  /// The range shifted by [delta] periods. [delta] may be negative (past) or
  /// positive (future).
  ReportRange shift(int delta) {
    final a = anchor;
    return ReportRange.forPeriod(period, switch (period) {
      ReportPeriod.week => addDays(a, 7 * delta),
      ReportPeriod.month => DateTime(a.year, a.month + delta, 1),
      ReportPeriod.year => DateTime(a.year + delta, a.month, a.day),
    });
  }

  /// Whether [this] is the period containing [now] — the furthest point the
  /// period navigator is allowed to travel to.
  bool containsPeriodOf(DateTime now) {
    final d = _midnight(now);
    final range = ReportRange.forPeriod(period, d);
    return range.start == start && range.endExclusive == endExclusive;
  }

  /// Number of calendar days the period spans.
  int get dayCount => daysBetween(start, endExclusive);

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  /// Short, human readable label for the period — used by the period navigator.
  ///
  /// [now] is injectable so the label is deterministic in tests; the app always
  /// leaves it unset and gets the wall clock.
  String label({DateTime? now}) {
    now ??= DateTime.now();
    // Direction is relative to *this* range: the range one step ahead holding
    // `now` means we are looking at the last one (and vice versa). Getting this
    // backwards labels February "Next month" while March is the current period.
    final isThis = containsPeriodOf(now);
    final isLast = shift(1).containsPeriodOf(now);
    final isNext = shift(-1).containsPeriodOf(now);
    if (isThis) return 'This ${period.label.toLowerCase()}';
    if (isLast) return 'Last ${period.label.toLowerCase()}';
    if (isNext) return 'Next ${period.label.toLowerCase()}';
    return switch (period) {
      ReportPeriod.week =>
        '${_shortWeekday(start)} – ${_shortWeekday(addDays(endExclusive, -1))}',
      ReportPeriod.month => '${_monthName(start.month)} ${start.year}',
      ReportPeriod.year => '${start.year}',
    };
  }

  static String _shortWeekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
