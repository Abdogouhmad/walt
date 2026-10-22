import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/date_math.dart';
import 'package:walt/data/reports/report_aggregation.dart';

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
}
