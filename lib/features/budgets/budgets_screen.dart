import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/input_ui.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/empty_state.dart';
import 'package:walt/shared/text_ui.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsProgress = ref.watch(budgetProgressProvider);
    final summary = ref.watch(budgetSummaryProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(context, summary, currency),

              SizedBox(height: context.h(24)),
              UiText(
                text: 'Active Budgets',
                type: UiTextType.titleLarge,
                style: TextStyle(
                  color: context.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.h(16)),
              if (budgetsProgress.isEmpty)
                EmptyState(
                  title: 'No budgets set yet',
                  subtitle: 'Create a budget to keep your spending in check.',
                  icon: Icons.account_balance_wallet_outlined,
                  actionLabel: 'Create Budget',
                  onActionPressed: () => _showAddBudgetBottomSheet(context),
                  topPadding: context.h(40),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgetsProgress.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: context.h(12)),
                  itemBuilder: (context, index) {
                    final progress = budgetsProgress[index];
                    return _buildBudgetCard(context, progress, currency);
                  },
                ),
              SizedBox(height: context.h(80)), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetBottomSheet(context),
        backgroundColor: context.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, double> summary,
    String currency,
  ) {
    final totalBudget = summary['totalBudget'] ?? 0.0;
    final totalSpent = summary['totalSpent'] ?? 0.0;
    final percentage = summary['percentage'] ?? 0.0;

    return M3Ecard(
      data: AppCardData(
        colorCard: context.primaryCardBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: 'TOTAL BUDGET',
                      type: UiTextType.bodySmall,
                      style: TextStyle(
                        color: context.cardTextSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    UiText(
                      text: '$currency ${totalBudget.toStringAsFixed(0)}',
                      type: UiTextType.displaySmall,
                      style: TextStyle(
                        color: context.cardTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(context.w(12)),
                  decoration: BoxDecoration(
                    color: context.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: context.primary,
                    size: context.w(28),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  'Spent',
                  '$currency ${totalSpent.toStringAsFixed(0)}',
                  context.cardExpense,
                ),
                _buildSummaryItem(
                  context,
                  'Remaining',
                  '$currency ${(totalBudget - totalSpent).toStringAsFixed(0)}',
                  context.cardIncome,
                ),
              ],
            ),
            SizedBox(height: context.h(20)),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.r(10)),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: context.primary.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 0.9 ? context.cardExpense : context.primary,
                ),
                minHeight: context.h(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          text: label,
          type: UiTextType.bodySmall,
          style: TextStyle(color: context.cardTextSecondary),
        ),
        UiText(
          text: value,
          type: UiTextType.titleMedium,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetProgress progress,
    String currency,
  ) {
    final iconData = CategoryIcons.getIcon(progress.category.icon);
    final categoryColor = Color(
      int.parse(progress.category.color.replaceAll('#', '0xFF')),
    );

    return M3Ecard(
      data: AppCardData(
        leading: Container(
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: categoryColor.withAlpha(40),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Icon(iconData, color: categoryColor, size: context.w(24)),
        ),
        title: progress.category.name,
        subtitle:
            '$currency ${progress.remaining.toStringAsFixed(0)} remaining',
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  text: '$currency ${progress.spentAmount.toStringAsFixed(0)}',
                  type: UiTextType.bodyMedium,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                UiText(
                  text:
                      'of $currency ${progress.budget.amount.toStringAsFixed(0)}',
                  type: UiTextType.bodySmall,
                  style: TextStyle(color: context.textSecondary),
                ),
              ],
            ),
            SizedBox(height: context.h(8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.r(10)),
              child: LinearProgressIndicator(
                value: progress.progress.clamp(0.0, 1.0),
                backgroundColor: context.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(context, progress),
                ),
                minHeight: context.h(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(BuildContext context, BudgetProgress progress) {
    if (progress.isOverBudget) return Colors.red;
    if (progress.isNearLimit) return Colors.orange;
    return context.primary;
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddBudgetSheet(),
    );
  }
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  const _AddBudgetSheet();

  @override
  ConsumerState<_AddBudgetSheet> createState() => __AddBudgetSheetState();
}

class __AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _selectedCategoryId;
  double _alertThreshold = 0.8;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final amount = double.parse(_amountController.text);
      final newBudget = WaltBudget(
        id: 0, // Dao will handle ID
        categoryId: _selectedCategoryId!,
        amount: amount,
        period: 'Monthly',
        alertAt: _alertThreshold,
        createdAt: DateTime.now(),
      );

      ref.read(budgetProvider.notifier).addBudget(newBudget);

      // Trigger a notification if they've already spent enough to trigger the alert
      final progressList = ref.read(budgetProgressProvider);
      final cat = ref
          .read(categoryProvider)
          .value
          ?.firstWhere((c) => c.id == _selectedCategoryId);

      if (cat != null) {
        final spent = progressList
            .where((p) => p.budget.categoryId == _selectedCategoryId)
            .fold(0.0, (sum, p) => sum + p.spentAmount);

        if (spent >= (amount * _alertThreshold)) {
          NotificationService().showBudgetAlert(
            id: _selectedCategoryId!,
            categoryName: cat.name,
            limit: amount,
            spent: spent,
            isOver: spent > amount,
          );
        }
      }

      Navigator.pop(context);
    } else if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final categories =
        categoriesAsync.value?.where((c) => c.type == 'expense').toList() ?? [];

    // Extracted currency using provider selection logic
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    return Container(
      padding: EdgeInsets.only(
        left: context.w(24),
        right: context.w(24),
        top: context.w(24),
        bottom: context.w(24) + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(32)),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(text: 'Add Budget', type: UiTextType.titleLarge),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: context.h(24)),
            InputUI(
              controller: _amountController,
              labelText: 'Budget Amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              hintText: '0.00 ($currency)',
              icon: Icons.account_balance_wallet,
            ),
            SizedBox(height: context.h(20)),
            UiText(
              text: 'Category',
              type: UiTextType.bodyMedium,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: context.h(12)),
            SizedBox(
              height: context.h(100),
              child: categories.isEmpty
                  ? const Center(child: Text('No expense categories found'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: context.w(12)),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategoryId == category.id;
                        final categoryColor = Color(
                          int.parse(category.color.replaceAll('#', '0xFF')),
                        );

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategoryId = category.id),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(context.w(12)),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? categoryColor
                                      : categoryColor.withAlpha(40),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: context.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  CategoryIcons.getIcon(category.icon),
                                  color: isSelected
                                      ? Colors.white
                                      : categoryColor,
                                  size: context.w(24),
                                ),
                              ),
                              SizedBox(height: context.h(4)),
                              SizedBox(
                                width: context.w(70),
                                child: UiText(
                                  text: category.name,
                                  type: UiTextType.bodySmall,
                                  style: TextStyle(
                                    color: isSelected
                                        ? context.primary
                                        : context.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: context.h(20)),
            UiText(
              text: 'Alert at (${(_alertThreshold * 100).toInt()}%)',
              type: UiTextType.bodyMedium,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _alertThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              activeColor: context.primary,
              onChanged: (value) => setState(() => _alertThreshold = value),
            ),
            SizedBox(height: context.h(24)),
            AppButton(
              label: 'Save Budget',
              onPressed: _saveBudget,
              isFullWidth: true,
              type: ButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }
}
