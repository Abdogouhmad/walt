import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/services/budget_alert_service.dart';

import 'support/budget_alert_fixtures.dart';

void main() {
  group('pendingAlerts', () {
    test('an unfired threshold is pending for each budget', () {
      final pending = BudgetAlertService.pendingAlerts([
        testBudgetProgress(id: 1, limit: 100, spent: 90),
        testBudgetProgress(id: 2, limit: 100, spent: 10),
      ], const {});
      expect(pending, hasLength(1));
      expect(pending.single.$1.budget.id, 1);
      expect(pending.single.$2, BudgetAlert.approaching);
    });

    test('a budget over its limit yields two distinct pending alerts', () {
      final pending = BudgetAlertService.pendingAlerts([
        testBudgetProgress(id: 1, limit: 100, spent: 150),
      ], const {});
      expect(pending.map((e) => e.$2), [
        BudgetAlert.approaching,
        BudgetAlert.exceeded,
      ]);
    });

    test('an already-fired threshold is not repeated', () {
      final p = testBudgetProgress(id: 1, limit: 100, spent: 90);
      final key = BudgetAlertService.storageKey(
        budgetId: 1,
        periodKey: p.calculation.window.key,
        alert: BudgetAlert.approaching,
      );
      expect(BudgetAlertService.pendingAlerts([p], {key}), isEmpty);
    });

    test('firing one threshold does not suppress the other', () {
      final p = testBudgetProgress(id: 1, limit: 100, spent: 150);
      final approaching = BudgetAlertService.storageKey(
        budgetId: 1,
        periodKey: p.calculation.window.key,
        alert: BudgetAlert.approaching,
      );
      final pending = BudgetAlertService.pendingAlerts([p], {approaching});
      expect(pending.map((e) => e.$2), [BudgetAlert.exceeded]);
    });

    test('the next period re-arms both thresholds', () {
      final march = testBudgetProgress(id: 1, limit: 100, spent: 150);
      final firedThisPeriod = {
        BudgetAlertService.storageKey(
          budgetId: 1,
          periodKey: march.calculation.window.key,
          alert: BudgetAlert.approaching,
        ),
        BudgetAlertService.storageKey(
          budgetId: 1,
          periodKey: march.calculation.window.key,
          alert: BudgetAlert.exceeded,
        ),
      };
      // Same budget, next month: the window key differs, so nothing is
      // suppressed and rollover is observable.
      final april = testBudgetProgress(
        id: 1,
        limit: 100,
        spent: 150,
        anchor: DateTime(2026, 4, 18),
      );
      expect(april.calculation.window.key, isNot(march.calculation.window.key));
      expect(
        BudgetAlertService.pendingAlerts([april], firedThisPeriod),
        hasLength(2),
      );
    });

    test('the storage key encodes budget, period and threshold', () {
      expect(
        BudgetAlertService.storageKey(
          budgetId: 7,
          periodKey: 'Monthly:2026-03-01',
          alert: BudgetAlert.exceeded,
        ),
        'budget_alert_fired:7|Monthly:2026-03-01|exceeded',
      );
    });

    test('an empty budget list produces nothing', () {
      expect(BudgetAlertService.pendingAlerts(const [], const {}), isEmpty);
    });
  });
}
