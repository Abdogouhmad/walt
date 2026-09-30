import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

final budgetProvider =
    NotifierProvider<BudgetNotifier, AsyncValue<List<WaltBudget>>>(
      () => BudgetNotifier(),
    );

class BudgetNotifier extends Notifier<AsyncValue<List<WaltBudget>>> {
  final BudgetDao _dao = BudgetDao();

  @override
  AsyncValue<List<WaltBudget>> build() {
    _loadBudgets();
    return const AsyncValue.loading();
  }

  Future<void> _loadBudgets() async {
    state = await AsyncValue.guard(() => _dao.getAllBudgets());
  }

  /// Mutations keep the previous list visible while the write happens, so
  /// dependent providers (progress, alerts) never see a transient empty state
  /// and the budget cards don't flash back to 0%.
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

/// A budget joined with its category and its consumption for the current
/// period window.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.calculation,
  });

  final WaltBudget budget;
  final WaltCategory category;
  final BudgetCalculation calculation;

  double get spentAmount => calculation.spent;
  double get limit => calculation.limit;
  double get progress => calculation.ratio;
  double get remaining => calculation.remaining;
  bool get isOverBudget => calculation.isExceeded;
  bool get isNearLimit => calculation.isNearLimit;

  /// Stable key for "once per threshold per period" notification persistence.
  String get alertKey => '${budget.id}|${calculation.window.key}';
}

final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetProvider).value ?? const <WaltBudget>[];
  final categories =
      ref.watch(categoryProvider).value ?? const <WaltCategory>[];
  final transactions = ref.watch(transactionProvider).value ?? const [];
  final now = ref.watch(budgetClockProvider);

  final byId = {for (final c in categories) c.id: c};

  return budgets.map((budget) {
    final category =
        byId[budget.categoryId] ??
        WaltCategory(
          id: budget.categoryId,
          name: 'Unknown',
          icon: 'help_outline',
          color: '#9E9E9E',
          type: 'expense',
        );
    return BudgetProgress(
      budget: budget,
      category: category,
      calculation: calculateBudget(
        budget: budget,
        transactions: transactions,
        now: now,
      ),
    );
  }).toList();
});

/// Typed replacement for the old stringly-typed `Map<String, dynamic>` summary.
final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final progress = ref.watch(budgetProgressProvider);
  final now = ref.watch(budgetClockProvider);
  return summariseBudgets(
    progress.map((p) => p.calculation).toList(),
    now: now,
  );
});

/// Injectable clock so tests and rollover checks are deterministic.
final budgetClockProvider = StateProvider<DateTime>((ref) => DateTime.now());
