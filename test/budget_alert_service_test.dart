import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/services/budget_alert_service.dart';

import 'support/budget_alert_fixtures.dart';

void main() {
  group('reachedAlerts', () {
    test('an untouched budget reaches nothing', () {
      expect(
        BudgetAlertService.reachedAlerts(
          testBudgetProgress(id: 1, limit: 100, spent: 10).calculation,
        ),
        isEmpty,
      );
    });

    test('crossing 80% yields only the approaching alert', () {
      expect(
        BudgetAlertService.reachedAlerts(
          testBudgetProgress(id: 1, limit: 100, spent: 80).calculation,
        ),
        [BudgetAlert.approaching],
      );
    });

    test('crossing both thresholds yields both, in severity order', () {
      // A jump from 40% straight past the limit still crossed 80% on the way.
      expect(
        BudgetAlertService.reachedAlerts(
          testBudgetProgress(id: 1, limit: 100, spent: 120).calculation,
        ),
        [BudgetAlert.approaching, BudgetAlert.exceeded],
      );
    });

    test('the approaching threshold is configurable per budget', () {
      expect(
        BudgetAlertService.reachedAlerts(
          testBudgetProgress(
            id: 1,
            limit: 100,
            spent: 60,
            alertAt: 0.5,
          ).calculation,
        ),
        [BudgetAlert.approaching],
      );
      expect(
        BudgetAlertService.reachedAlerts(
          testBudgetProgress(
            id: 1,
            limit: 100,
            spent: 60,
            alertAt: 0.9,
          ).calculation,
        ),
        isEmpty,
      );
    });
  });

  group('calculateBudget wiring', () {
    test('a real transaction list drives the threshold', () {
      final calc = calculateBudget(
        budget: const WaltBudget(
          id: 1,
          categoryId: 3,
          amount: 100,
          period: 'monthly',
        ),
        transactions: [
          WaltTransaction(
            id: 1,
            amount: 85,
            type: 'expense',
            categoryId: 3,
            date: DateTime(2026, 3, 10),
          ),
        ],
        now: DateTime(2026, 3, 18),
      );
      expect(calc.spent, 85);
      expect(BudgetAlertService.reachedAlerts(calc), [BudgetAlert.approaching]);
    });
  });
}
