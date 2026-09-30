import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/date_math.dart';

/// Granularity of the reports screen. Each period defines both the date range
/// that is analysed and the buckets the spending-over-time chart is built from.
enum ReportPeriod { week, month, year }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.week => 'Week',
    ReportPeriod.month => 'Month',
    ReportPeriod.year => 'Year',
  };

  /// How many buckets the spending chart shows for this period.
  int get bucketCount => switch (this) {
    ReportPeriod.week => 7,
    ReportPeriod.month => 31,
    ReportPeriod.year => 12,
  };
}

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

/// One bar/column of the "spending over time" chart.
class PeriodBucket {
  const PeriodBucket({
    required this.start,
    required this.label,
    this.expense = 0,
    this.income = 0,
  });

  final DateTime start;
  final String label;
  final double expense;
  final double income;

  double get total => expense + income;
}

/// One row of the donut chart / category breakdown list.
class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.amount,
    required this.percent,
  });

  final int categoryId;
  final String name;
  final String color;
  final String icon;
  final double amount;

  /// Share of the period's total spending, in the `0..1` range. Always 0 when
  /// the total is 0 so consumers never have to guard against a division.
  final double percent;
}

/// Immutable result of aggregating transactions over a [ReportRange].
class ReportAggregation {
  const ReportAggregation({
    required this.range,
    required this.buckets,
    required this.categories,
    required this.totalExpense,
    required this.totalIncome,
    required this.averageDailyExpense,
    required this.biggestCategory,
  });

  final ReportRange range;

  /// Always non-empty: the buckets are pre-populated with zero values so the
  /// chart has a stable x-axis even when there is no data.
  final List<PeriodBucket> buckets;

  /// Sorted by [CategorySlice.amount] descending. Empty when nothing was spent.
  final List<CategorySlice> categories;

  final double totalExpense;
  final double totalIncome;

  /// Total expense divided by the number of days in the period that have
  /// already happened (for past periods that is the full period length).
  final double averageDailyExpense;

  /// The dominant expense category, or null when nothing was spent.
  final CategorySlice? biggestCategory;

  bool get hasData => totalExpense > 0 || totalIncome > 0;
  bool get hasExpense => totalExpense > 0;
  double get net => totalIncome - totalExpense;

  /// Saving rate in percent, clamped to `0..100` territory is *not* applied —
  /// overspending legitimately produces a negative rate.
  double get savingRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
}

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
int bucketIndexFor(
  ReportRange range,
  List<PeriodBucket> buckets,
  DateTime date,
) {
  for (var i = 0; i < buckets.length; i++) {
    final b = buckets[i].start;
    final isLast = i == buckets.length - 1;
    final next = isLast ? range.endExclusive : buckets[i + 1].start;
    if (!date.isBefore(b) && date.isBefore(next)) return i;
  }
  return -1;
}

/// Pure aggregation of [transactions] over [range].
///
/// Every method is total: empty input, zero totals, null-ish categories and
/// boundary dates all produce a well-defined result rather than NaN or an
/// exception.
ReportAggregation aggregateReport({
  required ReportRange range,
  required List<WaltTransaction> transactions,
  required Map<int, WaltCategory> categories,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final buckets = buildBuckets(range);

  var totalExpense = 0.0;
  var totalIncome = 0.0;
  final byCategory = <int, double>{};

  for (final t in transactions) {
    // Defensive: the caller may hand us a wider list than the range.
    if (!range.contains(t.date)) continue;
    final index = bucketIndexFor(range, buckets, t.date);
    if (index < 0) continue;

    final bucket = buckets[index];
    if (_isExpense(t.type)) {
      totalExpense += t.amount;
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
      buckets[index] = PeriodBucket(
        start: bucket.start,
        label: bucket.label,
        expense: bucket.expense + t.amount,
        income: bucket.income,
      );
    } else {
      totalIncome += t.amount;
      buckets[index] = PeriodBucket(
        start: bucket.start,
        label: bucket.label,
        expense: bucket.expense,
        income: bucket.income + t.amount,
      );
    }
  }

  final slices = buildCategorySlices(
    byCategory: byCategory,
    categories: categories,
    total: totalExpense,
  );

  return ReportAggregation(
    range: range,
    buckets: buckets,
    categories: slices,
    totalExpense: totalExpense,
    totalIncome: totalIncome,
    averageDailyExpense: averageDailyExpense(
      totalExpense: totalExpense,
      range: range,
      now: reference,
    ),
    biggestCategory: slices.isEmpty ? null : slices.first,
  );
}

/// Share of [total] taken by each category, biggest first, percent in `0..1`.
/// A [total] of 0 yields a single-entry-safe list with all percents at 0.
List<CategorySlice> buildCategorySlices({
  required Map<int, double> byCategory,
  required Map<int, WaltCategory> categories,
  required double total,
}) {
  if (byCategory.isEmpty) return const [];
  // Guard the division: a zero total must not produce NaN/inf percents.
  final safeTotal = total > 0 ? total : 0.0;

  final slices = byCategory.entries.map((e) {
    final cat = categories[e.key];
    return CategorySlice(
      categoryId: e.key,
      name: cat?.name ?? 'Unknown',
      color: cat?.color ?? '#CCCCCC',
      icon: cat?.icon ?? 'category',
      amount: e.value,
      percent: safeTotal > 0 ? e.value / safeTotal : 0,
    );
  }).toList();

  slices.sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
}

/// Expense divided by the number of days of the period that have already
/// elapsed. For the current period that is "days since it started" (minimum 1,
/// never 0), for past periods the whole period length.
double averageDailyExpense({
  required double totalExpense,
  required ReportRange range,
  required DateTime now,
}) {
  final today = dateOnly(now);

  // Denominator is the number of days the money was actually spread over, and
  // is always clamped to the period: a period in the future is divided by its
  // full length, and a period that has already closed by its full length too.
  // Without the upper clamp a stale "now" produced a divisor larger than the
  // period, reporting an average below the true daily spend.
  final elapsedDays = today.isBefore(range.start)
      ? range.dayCount
      : daysBetween(range.start, today) + 1;
  final divisor = elapsedDays.clamp(1, range.dayCount);
  return totalExpense / divisor;
}

/// Totals spent on each day of the week containing [anchor].
///
/// Always returns exactly 7 entries, Monday first, so the week recap can render
/// a stable column per weekday. Income and non-expense types are ignored.
List<double> spendingByWeekday({
  required List<WaltTransaction> transactions,
  required DateTime anchor,
}) {
  final start = ReportRange.startOfWeek(anchor);
  final totals = List<double>.filled(7, 0);
  for (final t in transactions) {
    if (!_isExpense(t.type)) continue;
    final d = dateOnly(t.date);
    if (d.isBefore(start)) continue;
    final index = daysBetween(start, d);
    if (index < 0 || index > 6) continue;
    totals[index] += t.amount;
  }
  return totals;
}

/// Index (Monday == 0) of the weekday of [date].
int weekdayIndex(DateTime date) =>
    DateTime(date.year, date.month, date.day).weekday - 1;

bool _isExpense(String type) => type.toLowerCase() == 'expense';
