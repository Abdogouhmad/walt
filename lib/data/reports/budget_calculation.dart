import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';

import 'budget_window.dart';

/// Threshold crossed by a budget's consumption.
enum BudgetAlert { approaching, exceeded }

extension BudgetAlertX on BudgetAlert {
  String get title => switch (this) {
    BudgetAlert.approaching => 'Approaching limit',
    BudgetAlert.exceeded => 'Budget exceeded',
  };
}

/// Pure, total calculation of a single budget's consumption. Every field is
/// safe for a zero limit, an empty transaction list and boundary dates.
class BudgetCalculation {
  const BudgetCalculation({
    required this.window,
    required this.limit,
    required this.spent,
    required this.alertAt,
  });

  final BudgetWindow window;
  final double limit;
  final double spent;

  /// The user-configurable "approaching" fraction (default 0.8).
  final double alertAt;

  double get remaining => limit - spent;

  /// Spent / limit, clamped to `0..1` and always finite. A zero or negative
  /// limit reports 0 rather than dividing by zero.
  double get ratio {
    if (limit <= 0) return 0;
    final raw = spent / limit;
    if (raw.isNaN || raw.isInfinite) return 0;
    return raw.clamp(0.0, 1.0);
  }

  /// Unclamped ratio, used for the over-budget indicator.
  double get rawRatio {
    if (limit <= 0) return 0;
    final raw = spent / limit;
    return (raw.isNaN || raw.isInfinite) ? 0 : raw;
  }

  double get percent => ratio * 100;

  /// Reached at *or above* the limit — spending exactly 100% counts as exceeded.
  bool get isExceeded => limit > 0 && spent >= limit;

  bool get isNearLimit {
    if (limit <= 0) return false;
    final threshold = alertAt.clamp(0.0, 1.0);
    return spent >= limit * threshold;
  }

  /// What the limit can still absorb, per remaining day. Zero once the budget
  /// is spent or when no days remain.
  double safeDailySpend(DateTime now) {
    if (limit <= 0) return 0;
    final left = remaining;
    if (left <= 0) return 0;
    final elapsed = window.elapsedDays(now);
    final total = window.dayCount;
    final daysLeft = total - elapsed;
    if (daysLeft <= 0) return left;
    return left / daysLeft;
  }

  /// The alert this budget currently qualifies for, preferring the more
  /// severe one. Returns null when nothing is crossed.
  BudgetAlert? get activeAlert {
    if (isExceeded) return BudgetAlert.exceeded;
    if (isNearLimit) return BudgetAlert.approaching;
    return null;
  }
}

/// Whether [transaction] belongs to [budget]'s consumption.
///
/// An explicit [WaltTransaction.budgetId] wins: the expense belongs to exactly
/// that budget, even when several budgets share its category. Without a link,
/// the legacy rule applies — any budget whose categories include the
/// transaction's category consumes it.
bool transactionCountsForBudget(
  WaltTransaction transaction,
  WaltBudget budget,
) {
  if (transaction.type.toLowerCase() != 'expense') return false;
  final budgetId = transaction.budgetId;
  if (budgetId != null) return budgetId == budget.id;
  return budget.effectiveCategoryIds.contains(transaction.categoryId);
}

/// Computes [budget]'s consumption over its current window from [transactions].
///
/// Only expenses that belong to the budget (see [transactionCountsForBudget])
/// and fall inside the window count. Income, transactions from other
/// categories and transactions from previous periods are all ignored — that is
/// the rollover behaviour.
BudgetCalculation calculateBudget({
  required WaltBudget budget,
  required List<WaltTransaction> transactions,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final window = BudgetWindow.forPeriod(
    BudgetPeriodX.parse(budget.period),
    reference,
  );

  var spent = 0.0;
  for (final t in transactions) {
    if (!transactionCountsForBudget(t, budget)) continue;
    if (!window.contains(t.date)) continue;
    spent += t.amount;
  }

  return BudgetCalculation(
    window: window,
    limit: budget.amount,
    spent: spent,
    alertAt: budget.alertAt,
  );
}

/// Spending for an arbitrary [window], used by budget history where each period
/// gets its own limit snapshot rather than the current one.
double spendingInWindow({
  required WaltBudget budget,
  required List<WaltTransaction> transactions,
  required BudgetWindow window,
}) {
  var spent = 0.0;
  for (final t in transactions) {
    if (!transactionCountsForBudget(t, budget)) continue;
    if (!window.contains(t.date)) continue;
    spent += t.amount;
  }
  return spent;
}
