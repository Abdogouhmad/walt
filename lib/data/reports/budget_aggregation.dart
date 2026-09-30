import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/reports/date_math.dart';
import 'package:walt/data/models/walt_transaction.dart';

/// Recurrence of a budget. Stored as a free-form string in SQLite, so parsing
/// is lenient and always falls back to monthly.
enum BudgetPeriod { weekly, monthly, yearly }

extension BudgetPeriodX on BudgetPeriod {
  String get label => switch (this) {
    BudgetPeriod.weekly => 'Weekly',
    BudgetPeriod.monthly => 'Monthly',
    BudgetPeriod.yearly => 'Yearly',
  };

  static BudgetPeriod parse(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'weekly':
      case 'week':
        return BudgetPeriod.weekly;
      case 'yearly':
      case 'year':
      case 'annually':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }
}

/// The window a budget's spending is measured over. Rollover is implicit: the
/// window is always derived from "now", so budgets reset at the period boundary
/// without any persisted bookkeeping.
class BudgetWindow {
  const BudgetWindow({
    required this.period,
    required this.start,
    required this.endExclusive,
  });

  final BudgetPeriod period;
  final DateTime start;
  final DateTime endExclusive;

  factory BudgetWindow.forPeriod(BudgetPeriod period, DateTime anchor) {
    final day = dateOnly(anchor);
    return switch (period) {
      BudgetPeriod.weekly => BudgetWindow(
        period: period,
        start: addDays(day, -(day.weekday - 1)),
        endExclusive: addDays(day, -(day.weekday - 1) + 7),
      ),
      BudgetPeriod.monthly => BudgetWindow(
        period: period,
        start: DateTime(day.year, day.month, 1),
        endExclusive: DateTime(day.year, day.month + 1, 1),
      ),
      BudgetPeriod.yearly => BudgetWindow(
        period: period,
        start: DateTime(day.year, 1, 1),
        endExclusive: DateTime(day.year + 1, 1, 1),
      ),
    };
  }

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  int get dayCount => daysBetween(start, endExclusive);

  /// Days of the window that have already elapsed (at least 1 for an in-flight
  /// period, the full length once the window is in the past).
  int elapsedDays(DateTime now) {
    final today = dateOnly(now);
    if (today.isBefore(start)) return dayCount;
    if (!today.isBefore(endExclusive)) return dayCount;
    return daysBetween(start, today) + 1;
  }

  /// Stable identifier for the concrete instance of the period, e.g.
  /// `Monthly:2024-07`. Used as the persistence key so a threshold only fires
  /// once per budget per period.
  String get key {
    String stamp(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${period.label}:${stamp(start)}';
  }
}

/// Threshold crossed by a budget's consumption.
enum BudgetAlert { approaching, exceeded }

extension BudgetAlertX on BudgetAlert {
  /// Fractions of the limit that must be reached to trigger this alert.
  double get threshold => this == BudgetAlert.approaching ? 0.8 : 1.0;

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

/// Computes [budget]'s consumption over its current window from [transactions].
///
/// Only expenses in the budget's category and inside the window count. Income,
/// transactions from other categories and transactions from previous periods
/// are all ignored — that is the rollover behaviour.
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
    if (t.type.toLowerCase() != 'expense') continue;
    if (t.categoryId != budget.categoryId) continue;
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
    return BudgetSummary(
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
