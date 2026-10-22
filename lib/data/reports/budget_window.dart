import 'package:walt/data/reports/date_math.dart';

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
