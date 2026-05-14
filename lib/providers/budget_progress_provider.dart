import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

class BudgetProgress {
  final WaltBudget budget;
  final WaltCategory category;
  final double spentAmount;

  BudgetProgress({
    required this.budget,
    required this.category,
    required this.spentAmount,
  });

  double get progress => spentAmount / budget.amount;
  double get remaining => budget.amount - spentAmount;
  bool get isOverBudget => spentAmount > budget.amount;
  bool get isNearLimit => spentAmount >= (budget.amount * budget.alertAt);
}

final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(budgetProvider);
  final budgets = budgetsAsync.value ?? [];
  final categories = ref.watch(categoryProvider).value ?? [];
  final transactions = ref.watch(transactionProvider).value ?? [];

  // Filter expenses for current month
  final now = DateTime.now();
  final currentMonthTransactions = transactions.where((tx) {
    return tx.type.toLowerCase() == 'expense' &&
        tx.date.year == now.year &&
        tx.date.month == now.month;
  }).toList();

  return budgets.map((budget) {
    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => WaltCategory(
        id: budget.categoryId,
        name: 'Unknown',
        icon: 'help_outline',
        color: '0xFF9E9E9E',
        type: 'expense',
      ),
    );

    final spentAmount = currentMonthTransactions
        .where((tx) => tx.categoryId == budget.categoryId)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return BudgetProgress(
      budget: budget,
      category: category,
      spentAmount: spentAmount,
    );
  }).toList();
});

final budgetSummaryProvider = Provider((ref) {
  final progress = ref.watch(budgetProgressProvider);

  final totalBudget = progress.fold(
    0.0,
    (sum, p) => sum + p.budget.amount,
  );
  final totalSpent = progress.fold(
    0.0,
    (sum, p) => sum + p.spentAmount,
  );

  return {
    'totalBudget': totalBudget,
    'totalSpent': totalSpent,
    'remaining': totalBudget - totalSpent,
    'percentage': totalBudget > 0 ? (totalSpent / totalBudget) : 0.0,
  };
});
