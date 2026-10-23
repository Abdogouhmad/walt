import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/date_math.dart';

import 'report_buckets.dart';
import 'report_models.dart';
import 'report_range.dart';

export 'report_buckets.dart';
export 'report_models.dart';
export 'report_period.dart';
export 'report_range.dart';

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
      // Empty means "no stored accent"; the chart derives one from the active
      // palette instead of inventing a grey.
      color: cat?.color ?? '',
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

bool _isExpense(String type) => type.toLowerCase() == 'expense';
