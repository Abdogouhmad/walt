import 'report_range.dart';

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

  bool get hasExpense => totalExpense > 0;
  double get net => totalIncome - totalExpense;
}
