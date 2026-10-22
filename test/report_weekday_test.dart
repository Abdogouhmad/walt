import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/report_aggregation.dart';

import 'support/report_fixtures.dart';

void main() {
  final now = DateTime(2026, 3, 18, 14, 30);

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
          testTransaction(id: 1, amount: 10, date: DateTime(2026, 3, 16)),
          testTransaction(
            id: 2,
            amount: 20,
            date: DateTime(2026, 3, 18, 23, 59),
          ),
          testTransaction(id: 3, amount: 30, date: DateTime(2026, 3, 22)),
          // Previous week — excluded.
          testTransaction(id: 4, amount: 999, date: DateTime(2026, 3, 15)),
          // Next week — excluded.
          testTransaction(id: 5, amount: 999, date: DateTime(2026, 3, 23)),
          // Income ignored.
          testTransaction(
            id: 6,
            amount: 999,
            date: DateTime(2026, 3, 17),
            type: 'income',
          ),
        ],
        anchor: now,
      );
      expect(totals, [10, 0, 20, 0, 0, 0, 30]);
    });
  });
}
