// lib/features/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/budgets/widgets/empty_state.dart';
import 'package:walt/features/budgets/widgets/sumcard.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/text_ui.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProvider);
    final budgetsProgress = ref.watch(budgetProgressProvider);
    final summary = ref.watch(budgetSummaryProvider);

    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    final thisMonth = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: context.h(16)),
                UiText(
                  text: 'Error loading budgets',
                  type: UiTextType.titleMedium,
                ),
                TextButton(
                  onPressed: () => ref.read(budgetProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (_) {
            if (budgetsProgress.isEmpty && !budgetsAsync.isLoading) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(context.w(16)),
                child: Column(
                  children: [
                    BudgetSumCard(
                      currency: currency,
                      summary: summary,
                      month: thisMonth,
                    ),
                    EmptyState(
                      title: 'No budgets set yet',
                      subtitle:
                          'Create a budget to keep your spending in check and reach your goals faster.',
                      icon: Icons.account_balance_wallet_outlined,
                      topPadding: context.h(60),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(budgetProvider.notifier).refresh(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.w(16)),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetSumCard(
                      currency: currency,
                      summary: summary,
                      month: thisMonth,
                    ),

                    SizedBox(height: context.h(32)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        UiText(
                          text: 'Active Budgets',
                          type: UiTextType.titleLarge,
                          style: TextStyle(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        UiText(
                          text: '${budgetsProgress.length} total',
                          type: UiTextType.labelSmall,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),

                    SizedBox(height: context.h(20)),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgetsProgress.length,
                      itemBuilder: (context, index) {
                        final progress = budgetsProgress[index];

                        return Dismissible(
                          key: Key('budget_${progress.budget.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref
                                .read(budgetProvider.notifier)
                                .deleteBudget(progress.budget.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Budget for ${progress.category.name} deleted',
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref
                                        .read(budgetProvider.notifier)
                                        .addBudget(progress.budget);
                                  },
                                ),
                              ),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: context.w(20)),
                            decoration: BoxDecoration(
                              color: context.colorAppScheme.error,
                              borderRadius: BorderRadius.circular(
                                context.r(24),
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _showEditBudgetBottomSheet(
                              context,
                              progress.budget,
                            ),
                            child: BudgetCard(
                              progress: progress,
                              currency: currency,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: context.h(100)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: AppButton(
        type: ButtonType.fab,
        icon: Icons.add,
        onPressed: () => _showAddBudgetBottomSheet(context),
      ),
    );
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BudgetSheet(),
    );
  }

  void _showEditBudgetBottomSheet(BuildContext context, WaltBudget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetSheet(budgetToEdit: budget),
    );
  }
}
