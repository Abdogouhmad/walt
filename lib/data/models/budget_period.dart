import '../reports/budget_window.dart';

/// A budget's limit for one concrete period instance.
///
/// Limits are snapshotted as soon as a period becomes current, so editing a
/// budget later cannot rewrite what its history says it used to allow. A
/// missing row simply means "this period predates snapshots"; the history
/// builder falls back to the budget's current limit for those.
class BudgetPeriodSnapshot {
  const BudgetPeriodSnapshot({
    required this.budgetId,
    required this.start,
    required this.endExclusive,
    required this.limit,
  });

  final int budgetId;
  final DateTime start;
  final DateTime endExclusive;
  final double limit;
}

/// One period as the history screen renders it: the window, the snapshotted
/// limit and the spending calculated from transactions.
class BudgetPeriodSummary {
  const BudgetPeriodSummary({
    required this.window,
    required this.limit,
    required this.spent,
    required this.isCurrent,
  });

  final BudgetWindow window;
  final double limit;
  final double spent;
  final bool isCurrent;

  double get remaining => limit - spent;
  bool get isOver => limit > 0 && spent > limit;

  /// Spent / limit clamped to `0..1`; a zero limit reports 0.
  double get ratio {
    if (limit <= 0) return 0;
    final value = spent / limit;
    return value.isFinite ? value.clamp(0.0, 1.0) : 0;
  }

  double get rawRatio {
    if (limit <= 0) return 0;
    final value = spent / limit;
    return value.isFinite ? value : 0;
  }
}
