import 'package:flutter_riverpod/legacy.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/models/walt_budget.dart';

final budgetProvider =
    StateNotifierProvider.autoDispose<BudgetNotifier, List<WaltBudget>>((ref) {
      return BudgetNotifier();
    });

class BudgetNotifier extends StateNotifier<List<WaltBudget>> {
  BudgetNotifier() : super([]) {
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await BudgetDao().getAllBudgets();
    state = budgets;
  }

  Future<void> addBudget(WaltBudget budget) async {
    await BudgetDao().insertBudget(budget);
    _loadBudgets();
  }

  Future<void> updateBudget(WaltBudget budget) async {
    await BudgetDao().updateBudget(budget);
    _loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await BudgetDao().deleteBudget(id);
    _loadBudgets();
  }
}
