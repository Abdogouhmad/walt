// lib/features/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/core/widgets/walt_chrome.dart';
import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/budgets/widgets/sumcard.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt/shared/state_views.dart';

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
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Budgets'),
              actions: [ProfileAppBarAction()],
            ),
            if (budgetsAsync.isLoading && budgetsProgress.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingStateView(),
              )
            else if (budgetsAsync.hasError && budgetsProgress.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InlineErrorView(
                    message: 'Error loading budgets',
                    onRetry: () => ref.read(budgetProvider.notifier).refresh(),
                  ),
                ),
              )
            else if (budgetsProgress.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: WaltChrome.scrollBottomPadding(context),
                  ),
                  child: const EmptyStateView(
                    title: 'No budgets set yet',
                    message:
                        'Create a budget to keep your spending in check and reach your goals faster.',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: WaltChrome.constrain(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BudgetSumCard(
                          currency: currency,
                          summary: summary,
                          month: thisMonth,
                        ),
                        SectionHeader(
                          title: 'Active budgets',
                          trailing: Text(
                            '${budgetsProgress.length} total',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        GroupedList(
                          children: [
                            for (final progress in budgetsProgress)
                              Dismissible(
                                key: Key('budget_${progress.budget.id}'),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) =>
                                    _handleDelete(context, ref, progress),
                                background: _deleteBackground(context),
                                child: BudgetCard(
                                  progress: progress,
                                  currency: currency,
                                  onTap: () => showBudgetSheet(
                                    context,
                                    budgetToEdit: progress.budget,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height:
                              WaltChrome.scrollBottomPadding(context) -
                              AppSpacing.lg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
    );
  }

  void _handleDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) {
    ref.read(budgetProvider.notifier).deleteBudget(progress.budget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Budget for ${progress.category.name} deleted'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(budgetProvider.notifier).addBudget(progress.budget);
          },
        ),
      ),
    );
  }
}
