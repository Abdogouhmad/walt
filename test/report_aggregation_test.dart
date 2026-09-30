import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/date_math.dart';
import 'package:walt/data/reports/report_aggregation.dart';

WaltCategory _cat(int id, String name) => WaltCategory(
  id: id,
  name: name,
  icon: 'icon',
  color: '#000000',
  type: 'expense',
);

final _cats = <int, WaltCategory>{
  1: _cat(1, 'Food'),
  2: _cat(2, 'Transport'),
  3: _cat(3, 'Fun'),
};

WaltTransaction _tx({
  required int id,
  required double amount,
  required DateTime date,
  int categoryId = 1,
  String type = 'expense',
}) => WaltTransaction(
  id: id,
  amount: amount,
  type: type,
  categoryId: categoryId,
  date: date,
);

void main() {
  final now = DateTime(2026, 3, 18, 14, 30);

  group('date_math', () {
    test('addDays keeps the wall clock across a DST transition', () {
      // 29 Mar 2026 is inside the European summer-time switch for many zones;
      // adding 24h of duration would land on the previous day at 23:00.
      final d = DateTime(2026, 3, 28, 12);
      final next = addDays(d, 1);
      expect(next.day, 29);
      expect(next.hour, 12);
      expect(daysBetween(d, next), 1);
    });

    test('daysBetween counts calendar days, not elapsed hours', () {
      expect(daysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 1)), 31);
      expect(daysBetween(DateTime(2026, 4, 1), DateTime(2026, 3, 1)), -31);
      expect(daysBetween(DateTime(2026, 3, 5), DateTime(2026, 3, 5)), 0);
    });
  });

  group('ReportRange', () {
    test('week runs Monday→Monday and contains exactly 7 days', () {
      final r = ReportRange.forPeriod(ReportPeriod.week, now);
      expect(r.start, DateTime(2026, 3, 16));
      expect(r.endExclusive, DateTime(2026, 3, 23));
      expect(r.dayCount, 7);
      expect(r.contains(DateTime(2026, 3, 22, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 3, 23)), isFalse);
    });

    test('month and year spans the right number of days', () {
      expect(ReportRange.forPeriod(ReportPeriod.month, now).dayCount, 31);
      expect(
        ReportRange.forPeriod(
          ReportPeriod.month,
          DateTime(2026, 2, 10),
        ).dayCount,
        28,
      );
      // Leap year.
      expect(
        ReportRange.forPeriod(
          ReportPeriod.month,
          DateTime(2028, 2, 10),
        ).dayCount,
        29,
      );
      expect(ReportRange.forPeriod(ReportPeriod.year, now).dayCount, 365);
      expect(
        ReportRange.forPeriod(ReportPeriod.year, DateTime(2028, 5, 1)).dayCount,
        366,
      );
    });

    test('shift walks whole periods in both directions', () {
      final march = ReportRange.forPeriod(ReportPeriod.month, now);
      expect(march.shift(-1).start, DateTime(2026, 2, 1));
      expect(march.shift(-2).start, DateTime(2026, 1, 1));
      // Crossing the year boundary backwards.
      expect(
        ReportRange.forPeriod(
          ReportPeriod.month,
          DateTime(2026, 1, 15),
        ).shift(-1).start,
        DateTime(2025, 12, 1),
      );
      expect(
        ReportRange.forPeriod(
          ReportPeriod.year,
          DateTime(2026, 5, 1),
        ).shift(-1).start,
        DateTime(2025, 1, 1),
      );
      expect(
        ReportRange.forPeriod(ReportPeriod.week, now).shift(-1).start,
        DateTime(2026, 3, 9),
      );
    });

    test('shifting by zero is the identity', () {
      final r = ReportRange.forPeriod(ReportPeriod.month, now);
      expect(r.shift(0).start, r.start);
      expect(r.shift(0).endExclusive, r.endExclusive);
    });

    test('label distinguishes this, last and next', () {
      final thisMonth = ReportRange.forPeriod(ReportPeriod.month, now);
      expect(thisMonth.label(now: now), 'This month');
      expect(thisMonth.shift(-1).label(now: now), 'Last month');
      expect(thisMonth.shift(1).label(now: now), 'Next month');
      // Far enough away to fall through to an absolute label.
      expect(thisMonth.shift(-6).label(now: now), contains('2025'));
    });
  });

  group('buildBuckets', () {
    test('a week always yields 7 Monday-first buckets', () {
      final buckets = buildBuckets(
        ReportRange.forPeriod(ReportPeriod.week, now),
      );
      expect(buckets, hasLength(7));
      expect(buckets.first.start, DateTime(2026, 3, 16));
      expect(buckets.last.start, DateTime(2026, 3, 22));
      expect(buckets.first.label, 'M');
    });

    test('a month yields one bucket per calendar day', () {
      final buckets = buildBuckets(
        ReportRange.forPeriod(ReportPeriod.month, now),
      );
      expect(buckets, hasLength(31));
      expect(buckets.first.start, DateTime(2026, 3, 1));
      expect(buckets.last.start, DateTime(2026, 3, 31));
      expect(buckets.last.label, '31');
    });

    test('February yields 28 buckets in a common year', () {
      final buckets = buildBuckets(
        ReportRange.forPeriod(ReportPeriod.month, DateTime(2026, 2, 10)),
      );
      expect(buckets, hasLength(28));
    });

    test('a year yields 12 month buckets', () {
      final buckets = buildBuckets(
        ReportRange.forPeriod(ReportPeriod.year, now),
      );
      expect(buckets, hasLength(12));
      expect(buckets.first.start, DateTime(2026, 1, 1));
      expect(buckets.last.start, DateTime(2026, 12, 1));
    });
  });

  group('aggregateReport', () {
    final range = ReportRange.forPeriod(ReportPeriod.month, now);

    test('totals, ignores income, and never divides by zero', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: _cats,
        transactions: [
          _tx(id: 1, amount: 40, date: DateTime(2026, 3, 2)),
          _tx(id: 2, amount: 60, date: DateTime(2026, 3, 20)),
          _tx(id: 3, amount: 1000, date: DateTime(2026, 3, 3), type: 'income'),
          // Outside the range.
          _tx(id: 4, amount: 500, date: DateTime(2026, 2, 28)),
          _tx(id: 5, amount: 500, date: DateTime(2026, 4, 1)),
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
        categories: _cats,
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
        categories: _cats,
        transactions: [_tx(id: 1, amount: 280, date: DateTime(2026, 2, 14))],
      );
      expect(result.averageDailyExpense, closeTo(10, 0.0001));
    });

    test('category shares sum to 1 and the biggest one is flagged', () {
      final result = aggregateReport(
        range: range,
        now: now,
        categories: _cats,
        transactions: [
          _tx(id: 1, amount: 60, date: DateTime(2026, 3, 2), categoryId: 1),
          _tx(id: 2, amount: 30, date: DateTime(2026, 3, 3), categoryId: 2),
          _tx(id: 3, amount: 10, date: DateTime(2026, 3, 4), categoryId: 3),
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
        categories: _cats,
        transactions: [
          _tx(id: 1, amount: 50, date: DateTime(2026, 3, 2), categoryId: 1),
          // A category present in the budget list but with no spending.
          _tx(id: 2, amount: 0, date: DateTime(2026, 3, 3), categoryId: 2),
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
        categories: _cats,
        transactions: [
          _tx(id: 1, amount: 10, date: DateTime(2026, 3, 16)),
          _tx(id: 2, amount: 5, date: DateTime(2026, 3, 22)),
        ],
      );
      expect(week.buckets, hasLength(7));
      expect(week.buckets.first.total, 10);
      expect(week.buckets.last.total, 5);
      expect(week.totalExpense, 15);

      final year = aggregateReport(
        range: ReportRange.forPeriod(ReportPeriod.year, now),
        now: now,
        categories: _cats,
        transactions: [_tx(id: 1, amount: 7, date: DateTime(2026, 7, 4))],
      );
      expect(year.buckets, hasLength(12));
      expect(year.buckets[6].total, 7);
    });

    test('a transaction landing exactly on the range end is excluded', () {
      // Half-open window: [start, endExclusive).
      final result = aggregateReport(
        range: range,
        now: now,
        categories: _cats,
        transactions: [
          _tx(id: 1, amount: 40, date: DateTime(2026, 4, 1)),
          _tx(id: 2, amount: 40, date: DateTime(2026, 3, 31, 23, 59, 59)),
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

  group('spendingByWeekday', () {
    test('always returns 7 Monday-first entries', () {
      final totals = spendingByWeekday(transactions: const [], anchor: now);
      expect(totals, hasLength(7));
      expect(totals.every((t) => t == 0), isTrue);
    });

    test('files spending under the correct weekday', () {
      final totals = spendingByWeekday(
        transactions: [
          // Mon 16th, Wed 18th, Sun 22nd of the same week.
          _tx(id: 1, amount: 10, date: DateTime(2026, 3, 16)),
          _tx(id: 2, amount: 20, date: DateTime(2026, 3, 18, 23, 59)),
          _tx(id: 3, amount: 30, date: DateTime(2026, 3, 22)),
          // Previous week — excluded.
          _tx(id: 4, amount: 999, date: DateTime(2026, 3, 15)),
          // Next week — excluded.
          _tx(id: 5, amount: 999, date: DateTime(2026, 3, 23)),
          // Income ignored.
          _tx(id: 6, amount: 999, date: DateTime(2026, 3, 17), type: 'income'),
        ],
        anchor: now,
      );
      expect(totals, [10, 0, 20, 0, 0, 0, 30]);
    });
  });
}
