import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/budget_aggregation.dart';

import 'support/budget_fixtures.dart';

void main() {
  // A Wednesday, deliberately, so week windows are not accidentally aligned
  // with a Monday anchor.
  final now = DateTime(2026, 3, 18, 14, 30);

  group('calculateBudget', () {
    test('counts only matching expenses inside the window', () {
      final result = calculateBudget(
        budget: testBudget(amount: 200),
        transactions: [
          testExpense(id: 1, amount: 50, date: DateTime(2026, 3, 5)),
          testExpense(id: 2, amount: 25, date: DateTime(2026, 3, 18)),
          // Different category.
          testExpense(
            id: 3,
            amount: 999,
            date: DateTime(2026, 3, 10),
            categoryId: 8,
          ),
          // Income in the same category.
          testExpense(
            id: 4,
            amount: 999,
            date: DateTime(2026, 3, 10),
            type: 'income',
          ),
          // Previous period — excluded by rollover.
          testExpense(id: 5, amount: 999, date: DateTime(2026, 2, 28)),
          // Next period.
          testExpense(id: 6, amount: 999, date: DateTime(2026, 4, 1)),
        ],
        now: now,
      );
      expect(result.spent, 75);
      expect(result.remaining, 125);
    });

    test('a zero limit reports 0 percent instead of dividing by zero', () {
      final result = calculateBudget(
        budget: testBudget(amount: 0),
        transactions: [
          testExpense(id: 1, amount: 100, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      );
      expect(result.ratio, 0);
      expect(result.percent, 0);
      expect(result.percent.isFinite, isTrue);
      expect(result.isExceeded, isFalse);
      expect(result.safeDailySpend(now), 0);
    });

    test('overspending reports exactly 100 percent and stays finite', () {
      final result = calculateBudget(
        budget: testBudget(amount: 100),
        transactions: [
          testExpense(id: 1, amount: 250, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      );
      expect(result.ratio, 1.0);
      expect(result.percent, 100);
      expect(result.rawRatio, 2.5);
      expect(result.remaining, -150);
      expect(result.isExceeded, isTrue);
      expect(result.safeDailySpend(now), 0);
    });

    test('spending exactly the limit counts as exceeded', () {
      final result = calculateBudget(
        budget: testBudget(amount: 100),
        transactions: [
          testExpense(id: 1, amount: 100, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      );
      expect(result.isExceeded, isTrue);
      expect(result.activeAlert, BudgetAlert.exceeded);
    });

    test('safe daily spend divides the remainder by the days left', () {
      final result = calculateBudget(
        budget: testBudget(amount: 300),
        transactions: [
          testExpense(id: 1, amount: 0, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      );
      // March: 31 days, 18 elapsed → 13 days left, 300 remaining.
      expect(result.window.dayCount - result.window.elapsedDays(now), 13);
      expect(result.safeDailySpend(now), closeTo(300 / 13, 0.0001));
    });

    test('a past period spends nothing — budgets reset on rollover', () {
      final result = calculateBudget(
        budget: testBudget(amount: 200),
        transactions: [
          testExpense(id: 1, amount: 180, date: DateTime(2026, 3, 10)),
        ],
        now: DateTime(2026, 4, 2),
      );
      expect(result.spent, 0);
      expect(result.isExceeded, isFalse);
      expect(result.activeAlert, isNull);
    });

    test('threshold alerts prefer the severe one', () {
      BudgetAlert? alertFor(double spent) => calculateBudget(
        budget: testBudget(amount: 100),
        transactions: [
          testExpense(id: 1, amount: spent, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      ).activeAlert;

      expect(alertFor(79), isNull);
      expect(alertFor(80), BudgetAlert.approaching);
      expect(alertFor(99), BudgetAlert.approaching);
      expect(alertFor(100), BudgetAlert.exceeded);
      expect(alertFor(150), BudgetAlert.exceeded);
    });

    test('an unknown period string falls back to monthly', () {
      expect(BudgetPeriodX.parse('fortnightly'), BudgetPeriod.monthly);
      expect(BudgetPeriodX.parse(null), BudgetPeriod.monthly);
      expect(BudgetPeriodX.parse('WEEK'), BudgetPeriod.weekly);
    });
  });
}
