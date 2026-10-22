import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/budget_aggregation.dart';

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
}
