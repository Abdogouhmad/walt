import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/report_aggregation.dart';

import 'support/report_fixtures.dart';

void main() {
  final now = DateTime(2026, 3, 18, 14, 30);
  final range = ReportRange.forPeriod(ReportPeriod.month, now);

  group('aggregateReport — categories and buckets', () {
    test('category shares sum to 1 and the biggest one is flagged', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(
            id: 1,
            amount: 60,
            date: DateTime(2026, 3, 2),
            categoryId: 1,
          ),
          testTransaction(
            id: 2,
            amount: 30,
            date: DateTime(2026, 3, 3),
            categoryId: 2,
          ),
          testTransaction(
            id: 3,
            amount: 10,
            date: DateTime(2026, 3, 4),
            categoryId: 3,
          ),
        ],
      );

      expect(result.categories, hasLength(3));
      expect(result.categories.first.categoryId, 1);
      expect(result.categories.first.percent, closeTo(0.6, 0.001));
      expect(result.biggestCategory?.categoryId, 1);
      // Shares are stored in 0..1 and must total 1, not 100.
      expect(
        result.categories.fold<double>(0, (a, s) => a + s.percent),
        closeTo(1, 0.0001),
      );
    });

    test('a zero-amount category never produces NaN shares', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(
            id: 1,
            amount: 50,
            date: DateTime(2026, 3, 2),
            categoryId: 1,
          ),
          // A category present in the budget list but with no spending.
          testTransaction(
            id: 2,
            amount: 0,
            date: DateTime(2026, 3, 3),
            categoryId: 2,
          ),
        ],
      );
      for (final slice in result.categories) {
        expect(slice.percent.isNaN, isFalse);
        expect(slice.percent.isFinite, isTrue);
        expect(slice.percent, inInclusiveRange(0, 1));
      }
    });

    test('bucket totals follow the selected granularity', () {
      final week = aggregateReport(
        range: ReportRange.forPeriod(ReportPeriod.week, now),
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(id: 1, amount: 10, date: DateTime(2026, 3, 16)),
          testTransaction(id: 2, amount: 5, date: DateTime(2026, 3, 22)),
        ],
      );
      expect(week.buckets, hasLength(7));
      expect(week.buckets.first.total, 10);
      expect(week.buckets.last.total, 5);
      expect(week.totalExpense, 15);

      final year = aggregateReport(
        range: ReportRange.forPeriod(ReportPeriod.year, now),
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(id: 1, amount: 7, date: DateTime(2026, 7, 4)),
        ],
      );
      expect(year.buckets, hasLength(12));
      expect(year.buckets[6].total, 7);
    });

    test('a transaction landing exactly on the range end is excluded', () {
      // Half-open window: [start, endExclusive).
      final result = aggregateReport(
        range: range,
        now: now,
        categories: testCategories,
        transactions: [
          testTransaction(id: 1, amount: 40, date: DateTime(2026, 4, 1)),
          testTransaction(
            id: 2,
            amount: 40,
            date: DateTime(2026, 3, 31, 23, 59, 59),
          ),
        ],
      );
      expect(result.totalExpense, 40);
    });

    test('bucketIndexFor locates a date and rejects out-of-range ones', () {
      final buckets = buildBuckets(range);
      expect(bucketIndexFor(range, buckets, DateTime(2026, 3, 1)), 0);
      expect(bucketIndexFor(range, buckets, DateTime(2026, 3, 31)), 30);
      expect(bucketIndexFor(range, buckets, DateTime(2026, 2, 28)), -1);
      expect(bucketIndexFor(range, buckets, DateTime(2026, 4, 1)), -1);
    });
  });
}
