import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/services/budget_alert_service.dart';
import 'package:walt/providers/budget_provider.dart';

BudgetProgress _progress({
  required int id,
  required double limit,
  required double spent,
  String period = 'monthly',
  double alertAt = 0.8,
  DateTime? anchor,
}) {
  final budget = WaltBudget(
    id: id,
    categoryId: id,
    amount: limit,
    period: period,
    alertAt: alertAt,
  );
  final window = BudgetWindow.forPeriod(
    BudgetPeriodX.parse(period),
    anchor ?? DateTime(2026, 3, 18),
  );
  return BudgetProgress(
    budget: budget,
    category: WaltCategory(
      id: id,
      name: 'Category $id',
      icon: 'icon',
      color: '#000000',
      type: 'expense',
    ),
    calculation: BudgetCalculation(
      window: window,
      limit: limit,
      spent: spent,
      alertAt: alertAt,
    ),
  );
}

void main() {
  group('reachedAlerts', () {
    test('an untouched budget reaches nothing', () {
      expect(
        BudgetAlertService.reachedAlerts(
          _progress(id: 1, limit: 100, spent: 10).calculation,
        ),
        isEmpty,
      );
    });

    test('crossing 80% yields only the approaching alert', () {
      expect(
        BudgetAlertService.reachedAlerts(
          _progress(id: 1, limit: 100, spent: 80).calculation,
        ),
        [BudgetAlert.approaching],
      );
    });

    test('crossing both thresholds yields both, in severity order', () {
      // A jump from 40% straight past the limit still crossed 80% on the way.
      expect(
        BudgetAlertService.reachedAlerts(
          _progress(id: 1, limit: 100, spent: 120).calculation,
        ),
        [BudgetAlert.approaching, BudgetAlert.exceeded],
      );
    });

    test('the approaching threshold is configurable per budget', () {
      expect(
        BudgetAlertService.reachedAlerts(
          _progress(id: 1, limit: 100, spent: 60, alertAt: 0.5).calculation,
        ),
        [BudgetAlert.approaching],
      );
      expect(
        BudgetAlertService.reachedAlerts(
          _progress(id: 1, limit: 100, spent: 60, alertAt: 0.9).calculation,
        ),
        isEmpty,
      );
    });
  });

  group('pendingAlerts', () {
    test('an unfired threshold is pending for each budget', () {
      final pending = BudgetAlertService.pendingAlerts([
        _progress(id: 1, limit: 100, spent: 90),
        _progress(id: 2, limit: 100, spent: 10),
      ], const {});
      expect(pending, hasLength(1));
      expect(pending.single.$1.budget.id, 1);
      expect(pending.single.$2, BudgetAlert.approaching);
    });

    test('a budget over its limit yields two distinct pending alerts', () {
      final pending = BudgetAlertService.pendingAlerts([
        _progress(id: 1, limit: 100, spent: 150),
      ], const {});
      expect(pending.map((e) => e.$2), [
        BudgetAlert.approaching,
        BudgetAlert.exceeded,
      ]);
    });

    test('an already-fired threshold is not repeated', () {
      final p = _progress(id: 1, limit: 100, spent: 90);
      final key = BudgetAlertService.storageKey(
        budgetId: 1,
        periodKey: p.calculation.window.key,
        alert: BudgetAlert.approaching,
      );
      expect(BudgetAlertService.pendingAlerts([p], {key}), isEmpty);
    });

    test('firing one threshold does not suppress the other', () {
      final p = _progress(id: 1, limit: 100, spent: 150);
      final approaching = BudgetAlertService.storageKey(
        budgetId: 1,
        periodKey: p.calculation.window.key,
        alert: BudgetAlert.approaching,
      );
      final pending = BudgetAlertService.pendingAlerts([p], {approaching});
      expect(pending.map((e) => e.$2), [BudgetAlert.exceeded]);
    });

    test('the next period re-arms both thresholds', () {
      final march = _progress(id: 1, limit: 100, spent: 150);
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
      final april = _progress(
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

  group('calculateBudget wiring', () {
    test('a real transaction list drives the threshold', () {
      final calc = calculateBudget(
        budget: WaltBudget(
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
