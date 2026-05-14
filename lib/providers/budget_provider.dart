import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/models/walt_budget.dart';

final budgetProvider =
    NotifierProvider.autoDispose<BudgetNotifier, AsyncValue<List<WaltBudget>>>(
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
    try {
      // Don't set loading if we already have data (for smoother updates)
      if (state.hasValue) {
        // Optional: you could keep the old data while loading
      } else {
        state = const AsyncValue.loading();
      }
      
      final budgets = await _dao.getAllBudgets();
      
      if (ref.mounted) {
        state = AsyncValue.data(budgets);
      }
    } catch (e, st) {
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addBudget(WaltBudget budget) async {
    await _dao.insertBudget(budget);
    await _loadBudgets();
  }

  Future<void> updateBudget(WaltBudget budget) async {
    await _dao.updateBudget(budget);
    await _loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await _dao.deleteBudget(id);
    await _loadBudgets();
  }

  Future<void> refresh() => _loadBudgets();
}
