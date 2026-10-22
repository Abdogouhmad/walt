// lib/features/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/features/budgets/widgets/budget_delete_action.dart';
import 'package:walt/features/budgets/widgets/budget_delete_background.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/budgets/widgets/sumcard.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/profile_app_bar_action.dart';
import 'package:walt_ui/walt_ui.dart';

/// Shared month-name formatter — built once, not on every header rebuild.
final _monthNameFormat = DateFormat('MMMM');

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProvider);
    final budgetsProgress = ref.watch(budgetProgressProvider);
    final summary = ref.watch(budgetSummaryProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    final thisMonth = _monthNameFormat.format(DateTime.now());

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
                                onDismissed: (_) => deleteBudgetWithUndo(
                                  context,
                                  ref,
                                  progress,
                                ),
                                background: const BudgetDeleteBackground(),
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
}
