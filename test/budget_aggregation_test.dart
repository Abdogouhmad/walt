import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/budget_aggregation.dart';

WaltBudget _budget({
  int id = 1,
  int categoryId = 7,
  double amount = 200,
  String period = 'monthly',
  double alertAt = 0.8,
}) => WaltBudget(
  id: id,
  categoryId: categoryId,
  amount: amount,
  period: period,
  alertAt: alertAt,
);

WaltTransaction _expense({
  required int id,
  required double amount,
  required DateTime date,
  int categoryId = 7,
  String type = 'expense',
}) => WaltTransaction(
  id: id,
  amount: amount,
  type: type,
  categoryId: categoryId,
  date: date,
);

void main() {
  // A Wednesday, deliberately, so week windows are not accidentally aligned
  // with a Monday anchor.
  final now = DateTime(2026, 3, 18, 14, 30);

  group('BudgetWindow', () {
    test('weekly runs Monday→next Monday, half-open', () {
      final w = BudgetWindow.forPeriod(BudgetPeriod.weekly, now);
      expect(w.start, DateTime(2026, 3, 16));
      expect(w.endExclusive, DateTime(2026, 3, 23));
      expect(w.dayCount, 7);
      expect(w.contains(DateTime(2026, 3, 16)), isTrue);
      expect(w.contains(DateTime(2026, 3, 22, 23, 59)), isTrue);
      expect(w.contains(DateTime(2026, 3, 23)), isFalse);
    });

    test('monthly spans the calendar month and rolls over', () {
      expect(
        BudgetWindow.forPeriod(BudgetPeriod.monthly, now).endExclusive,
        DateTime(2026, 4, 1),
      );
      // A 31-day month and a 28-day February both derive correctly, because
      // the end is computed by construction rather than by adding 30 days.
      expect(
        BudgetWindow.forPeriod(
          BudgetPeriod.monthly,
          DateTime(2026, 1, 15),
        ).dayCount,
        31,
      );
      expect(
        BudgetWindow.forPeriod(
          BudgetPeriod.monthly,
          DateTime(2026, 2, 15),
        ).dayCount,
        28,
      );
    });

    test('yearly spans the calendar year', () {
      final w = BudgetWindow.forPeriod(BudgetPeriod.yearly, now);
      expect(w.start, DateTime(2026, 1, 1));
      expect(w.endExclusive, DateTime(2027, 1, 1));
    });

    test('elapsed days never exceed the window length', () {
      final w = BudgetWindow.forPeriod(BudgetPeriod.monthly, now);
      // Mid-month, inclusive of today: 1st..18th.
      expect(w.elapsedDays(now), 18);
      // Before the window: the whole month counts as elapsed.
      expect(w.elapsedDays(DateTime(2026, 1, 5)), 31);
      // Long after the window: still capped at the full length.
      expect(w.elapsedDays(DateTime(2027, 6, 1)), 31);
    });

    test('key is stable per concrete period instance', () {
      expect(
        BudgetWindow.forPeriod(BudgetPeriod.monthly, now).key,
        'Monthly:2026-03-01',
      );
      // Same period, different day → identical key, so a threshold fires once.
      expect(
        BudgetWindow.forPeriod(BudgetPeriod.monthly, DateTime(2026, 3, 30)).key,
        BudgetWindow.forPeriod(BudgetPeriod.monthly, now).key,
      );
      // Next month → different key.
      expect(
        BudgetWindow.forPeriod(BudgetPeriod.monthly, DateTime(2026, 4, 2)).key,
        isNot('Monthly:2026-03-01'),
      );
    });
  });

  group('calculateBudget', () {
    test('counts only matching expenses inside the window', () {
      final result = calculateBudget(
        budget: _budget(amount: 200),
        transactions: [
          _expense(id: 1, amount: 50, date: DateTime(2026, 3, 5)),
          _expense(id: 2, amount: 25, date: DateTime(2026, 3, 18)),
          // Different category.
          _expense(
            id: 3,
            amount: 999,
            date: DateTime(2026, 3, 10),
            categoryId: 8,
          ),
          // Income in the same category.
          _expense(
            id: 4,
            amount: 999,
            date: DateTime(2026, 3, 10),
            type: 'income',
          ),
          // Previous period — excluded by rollover.
          _expense(id: 5, amount: 999, date: DateTime(2026, 2, 28)),
          // Next period.
          _expense(id: 6, amount: 999, date: DateTime(2026, 4, 1)),
        ],
        now: now,
      );
      expect(result.spent, 75);
      expect(result.remaining, 125);
    });

    test('a zero limit reports 0 percent instead of dividing by zero', () {
      final result = calculateBudget(
        budget: _budget(amount: 0),
        transactions: [
          _expense(id: 1, amount: 100, date: DateTime(2026, 3, 5)),
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
        budget: _budget(amount: 100),
        transactions: [
          _expense(id: 1, amount: 250, date: DateTime(2026, 3, 5)),
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
        budget: _budget(amount: 100),
        transactions: [
          _expense(id: 1, amount: 100, date: DateTime(2026, 3, 5)),
        ],
        now: now,
      );
      expect(result.isExceeded, isTrue);
      expect(result.activeAlert, BudgetAlert.exceeded);
    });

    test('safe daily spend divides the remainder by the days left', () {
      final result = calculateBudget(
        budget: _budget(amount: 300),
        transactions: [_expense(id: 1, amount: 0, date: DateTime(2026, 3, 5))],
        now: now,
      );
      // March: 31 days, 18 elapsed → 13 days left, 300 remaining.
      expect(result.window.dayCount - result.window.elapsedDays(now), 13);
      expect(result.safeDailySpend(now), closeTo(300 / 13, 0.0001));
    });

    test('a past period spends nothing — budgets reset on rollover', () {
      final result = calculateBudget(
        budget: _budget(amount: 200),
        transactions: [
          _expense(id: 1, amount: 180, date: DateTime(2026, 3, 10)),
        ],
        now: DateTime(2026, 4, 2),
      );
      expect(result.spent, 0);
      expect(result.isExceeded, isFalse);
      expect(result.activeAlert, isNull);
    });

    test('threshold alerts prefer the severe one', () {
      BudgetAlert? alertFor(double spent) => calculateBudget(
        budget: _budget(amount: 100),
        transactions: [
          _expense(id: 1, amount: spent, date: DateTime(2026, 3, 5)),
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

  group('summariseBudgets', () {
    test('an empty list is all zeroes, not a crash', () {
      final s = summariseBudgets(const [], now: now);
      expect(s.count, 0);
      expect(s.isEmpty, isTrue);
      expect(s.totalBudget, 0);
      expect(s.totalSpent, 0);
      expect(s.percent, 0);
      expect(s.remainingDays, 0);
    });

    test('totals the limits and the spending', () {
      final s = summariseBudgets([
        calculateBudget(
          budget: _budget(id: 1, categoryId: 1, amount: 100),
          transactions: [
            _expense(
              id: 1,
              amount: 120,
              date: DateTime(2026, 3, 5),
              categoryId: 1,
            ),
          ],
          now: now,
        ),
        calculateBudget(
          budget: _budget(id: 2, categoryId: 2, amount: 100),
          transactions: [
            _expense(
              id: 2,
              amount: 30,
              date: DateTime(2026, 3, 6),
              categoryId: 2,
            ),
          ],
          now: now,
        ),
      ], now: now);

      expect(s.count, 2);
      expect(s.totalBudget, 200);
      expect(s.totalSpent, 150);
      expect(s.remaining, 50);
      expect(s.percent, 75);
      expect(s.exceededCount, 1);
      expect(s.isOver, isFalse);
    });

    test('remaining days is the longest window still in flight', () {
      final s = summariseBudgets([
        calculateBudget(
          budget: _budget(id: 1, categoryId: 1, amount: 100, period: 'monthly'),
          transactions: const [],
          now: now,
        ),
        calculateBudget(
          budget: _budget(id: 2, categoryId: 2, amount: 100, period: 'weekly'),
          transactions: const [],
          now: now,
        ),
      ], now: now);

      // March: 13 days left. Week of Mar 16: 5 days left.
      expect(s.remainingDays, 13);
    });
  });
}
