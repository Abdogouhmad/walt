import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/models/walt_budget.dart';

final budgetProvider =
    NotifierProvider<BudgetNotifier, AsyncValue<List<WaltBudget>>>(
      () => BudgetNotifier(),
    );

class BudgetNotifier extends Notifier<AsyncValue<List<WaltBudget>>> {
  final _dao = BudgetDao();

  @override
  AsyncValue<List<WaltBudget>> build() {
    _loadBudgets();
    return const AsyncValue.loading();
  }

  Future<void> _loadBudgets() async {
    state = await AsyncValue.guard(() => _dao.getAllBudgets());
  }

  Future<void> addBudget(WaltBudget budget) async {
    state = const AsyncValue.loading();
    await _dao.insertBudget(budget);
    await _loadBudgets();
  }

  Future<void> updateBudget(WaltBudget budget) async {
    state = const AsyncValue.loading();
    await _dao.updateBudget(budget);
    await _loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    state = const AsyncValue.loading();
    await _dao.deleteBudget(id);
    await _loadBudgets();
  }

  Future<void> refresh() => _loadBudgets();
}
