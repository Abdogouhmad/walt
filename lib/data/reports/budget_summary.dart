import 'budget_calculation.dart';

/// Aggregated budget figures for the budget screen header.
class BudgetSummary {
  const BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percent,
    required this.remainingDays,
    required this.count,
    required this.exceededCount,
  });

  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double percent;
  final int remainingDays;
  final int count;
  final int exceededCount;

  bool get isOver => totalSpent > totalBudget;
  bool get isEmpty => count == 0;
}

/// Sums [calculations] into a header summary. Safe for an empty list.
BudgetSummary summariseBudgets(
  List<BudgetCalculation> calculations, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  if (calculations.isEmpty) {
    return const BudgetSummary(
      totalBudget: 0,
      totalSpent: 0,
      remaining: 0,
      percent: 0,
      remainingDays: 0,
      count: 0,
      exceededCount: 0,
    );
  }

  var totalBudget = 0.0;
  var totalSpent = 0.0;
  var exceeded = 0;
  var remainingDays = 0;

  for (final c in calculations) {
    totalBudget += c.limit;
    totalSpent += c.spent;
    if (c.isExceeded) exceeded++;
    final left = c.window.dayCount - c.window.elapsedDays(reference);
    if (left > remainingDays) remainingDays = left;
  }

  final percent = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    remaining: totalBudget - totalSpent,
    percent: percent.isFinite ? percent : 0,
    remainingDays: remainingDays,
    count: calculations.length,
    exceededCount: exceeded,
  );
}
