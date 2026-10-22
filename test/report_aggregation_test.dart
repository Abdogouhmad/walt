import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/report_aggregation.dart';

import 'support/report_fixtures.dart';

void main() {
  final now = DateTime(2026, 3, 18, 14, 30);
  final range = ReportRange.forPeriod(ReportPeriod.month, now);

  group('aggregateReport — totals', () {
    test('totals, ignores income, and never divides by zero', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(id: 1, amount: 40, date: DateTime(2026, 3, 2)),
          testTransaction(id: 2, amount: 60, date: DateTime(2026, 3, 20)),
          testTransaction(
            id: 3,
            amount: 1000,
            date: DateTime(2026, 3, 3),
            type: 'income',
          ),
          // Outside the range.
          testTransaction(id: 4, amount: 500, date: DateTime(2026, 2, 28)),
          testTransaction(id: 5, amount: 500, date: DateTime(2026, 4, 1)),
        ],
      );

      expect(result.totalExpense, 100);
      expect(result.totalIncome, 1000);
      expect(result.net, 900);
      expect(result.averageDailyExpense.isFinite, isTrue);
      // 18 elapsed days of March.
      expect(result.averageDailyExpense, closeTo(100 / 18, 0.0001));
    });

    test('an empty report is all zeroes and finite', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: testCategories,
        transactions: [],
      );
      expect(result.totalExpense, 0);
      expect(result.totalIncome, 0);
      expect(result.net, 0);
      expect(result.averageDailyExpense, 0);
      expect(result.biggestCategory, isNull);
      expect(result.categories, isEmpty);
      expect(result.buckets.every((b) => b.total == 0), isTrue);
    });

    test('a past period averages over the full period, not the stale delta', () {
      final feb = ReportRange.forPeriod(
        ReportPeriod.month,
        DateTime(2026, 2, 10),
      );
      // `now` is long after February closed: the divisor must be capped at 28,
      // otherwise the average is understated.
      final result = aggregateReport(
        range: feb,
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(id: 1, amount: 280, date: DateTime(2026, 2, 14)),
        ],
      );
      expect(result.averageDailyExpense, closeTo(10, 0.0001));
    });
  });
}
