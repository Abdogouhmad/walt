import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/providers/budget_provider.dart';

/// A [BudgetProgress] built by hand, for the alert-threshold tests.
BudgetProgress testBudgetProgress({
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
    categories: [
      WaltCategory(
        id: id,
        name: 'Category $id',
        icon: 'icon',
        color: '#000000',
        type: 'expense',
      ),
    ],
    now: anchor ?? DateTime(2026, 3, 18),
    calculation: BudgetCalculation(
      window: window,
      limit: limit,
      spent: spent,
      alertAt: alertAt,
    ),
  );
}
