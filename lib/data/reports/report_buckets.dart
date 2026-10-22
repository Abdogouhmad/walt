import 'package:walt/data/reports/date_math.dart';

import 'report_models.dart';
import 'report_period.dart';
import 'report_range.dart';

/// Builds the buckets for [range] for the given [period], all zeroed.
List<PeriodBucket> buildBuckets(ReportRange range) {
  switch (range.period) {
    case ReportPeriod.week:
      return List.generate(7, (i) {
        final d = addDays(range.start, i);
        return PeriodBucket(start: d, label: _weekdayInitial(d));
      });
    case ReportPeriod.month:
      return List.generate(range.dayCount, (i) {
        final d = addDays(range.start, i);
        return PeriodBucket(start: d, label: '${d.day}');
      });
    case ReportPeriod.year:
      return List.generate(12, (i) {
        final d = DateTime(range.start.year, i + 1, 1);
        return PeriodBucket(start: d, label: _monthInitial(d.month));
      });
  }
}

String _weekdayInitial(DateTime d) =>
    const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

String _monthInitial(int month) => const [
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D',
][month - 1];

/// Index of the bucket a [date] belongs to, or `-1` when it falls outside.
///
/// Derived arithmetically rather than by scanning: the buckets are laid out
/// contiguously from `range.start` (one per day for weeks/months, one per month
/// for years), so the position follows from the calendar directly. This keeps
/// aggregation linear in the number of transactions instead of
/// transactions × buckets.
int bucketIndexFor(
  ReportRange range,
  List<PeriodBucket> buckets,
  DateTime date,
) {
  final day = dateOnly(date);
  final index = switch (range.period) {
    ReportPeriod.week || ReportPeriod.month => daysBetween(range.start, day),
    ReportPeriod.year => day.month - 1,
  };
  return (index >= 0 && index < buckets.length) ? index : -1;
}
