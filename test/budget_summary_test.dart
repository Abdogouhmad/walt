import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/budget_aggregation.dart';

import 'support/budget_fixtures.dart';

void main() {
  // A Wednesday, deliberately, so week windows are not accidentally aligned
  // with a Monday anchor.
  final now = DateTime(2026, 3, 18, 14, 30);

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
          budget: testBudget(id: 1, categoryId: 1, amount: 100),
          transactions: [
            testExpense(
              id: 1,
              amount: 120,
              date: DateTime(2026, 3, 5),
              categoryId: 1,
            ),
          ],
          now: now,
        ),
        calculateBudget(
          budget: testBudget(id: 2, categoryId: 2, amount: 100),
          transactions: [
            testExpense(
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
          budget: testBudget(
            id: 1,
            categoryId: 1,
            amount: 100,
            period: 'monthly',
          ),
          transactions: const [],
          now: now,
        ),
        calculateBudget(
          budget: testBudget(
            id: 2,
            categoryId: 2,
            amount: 100,
            period: 'weekly',
          ),
          transactions: const [],
          now: now,
        ),
      ], now: now);

      // March: 13 days left. Week of Mar 16: 5 days left.
      expect(s.remainingDays, 13);
    });
  });
}
