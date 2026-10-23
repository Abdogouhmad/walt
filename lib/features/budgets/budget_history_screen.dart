import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/budget_period.dart';
import 'package:walt/features/budgets/widgets/budget_history_chart.dart';
import 'package:walt/features/budgets/widgets/budget_period_card.dart';
import 'package:walt/features/budgets/widgets/budget_period_transactions_sheet.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// One budget's period-by-period history.
///
/// Limits come from snapshots taken when each period was current, so editing
/// the budget today changes the current row but leaves the past alone.
class BudgetHistoryScreen extends ConsumerWidget {
  const BudgetHistoryScreen({super.key, required this.budgetId});

  final int budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressList = ref.watch(budgetProgressProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final historyAsync = ref.watch(budgetHistoryProvider(budgetId));

    BudgetProgress? progress;
    for (final item in progressList) {
      if (item.budget.id == budgetId) {
        progress = item;
        break;
      }
    }

    final summaries = historyAsync.value ?? const <BudgetPeriodSummary>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              progress?.displayName ?? 'Budget history',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (progress != null)
                IconButton(
                  tooltip: 'Edit budget',
                  onPressed: () =>
                      showBudgetSheet(context, budgetToEdit: progress!.budget),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          if (progress == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Budget not found',
                message: 'It may have been deleted.',
                icon: Icons.account_balance_wallet_outlined,
              ),
            )
          else if (historyAsync.isLoading && summaries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingStateView(),
            )
          else if (historyAsync.hasError && summaries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: InlineErrorView(
                  message: 'Could not load budget history',
                  onRetry: () =>
                      ref.invalidate(budgetHistoryProvider(budgetId)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: WaltChrome.constrain(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _HistoryHero(
                        progress: progress,
                        summaries: summaries,
                        currency: currency,
                      ),
                      const SectionHeader(title: 'Periods'),
                      for (final summary in summaries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: BudgetPeriodCard(
                            summary: summary,
                            currency: currency,
                            onTap: () => showBudgetPeriodTransactions(
                              context,
                              budget: progress!.budget,
                              summary: summary,
                            ),
                          ),
                        ),
                      SizedBox(
                        height:
                            MediaQuery.paddingOf(context).bottom +
                            AppSpacing.xl,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The chart card: current spending at the top, per-period bars below.
class _HistoryHero extends StatelessWidget {
  const _HistoryHero({
    required this.progress,
    required this.summaries,
    required this.currency,
  });

  final BudgetProgress progress;
  final List<BudgetPeriodSummary> summaries;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accentFor(context, progress.budget.accentColor);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.18),
                    scheme.surface,
                  ),
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.08),
                    scheme.surface,
                  ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryArtwork(
                    category: progress.categories.isNotEmpty
                        ? progress.categories.first
                        : progress.category,
                    size: 48,
                    radius: AppRadius.md,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          progress.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress.categoryNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${MoneyFormat.withCode(progress.spentAmount, currency: currency)} '
                          'of ${MoneyFormat.withCode(progress.limit, currency: currency)} this period',
                          maxLines: 2,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Spending by period',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${summaries.length} periods',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                BudgetHistoryChart(summaries: summaries, currency: currency),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bars show spending; tap a period to see its transactions.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _accentFor(BuildContext context, String? hex) {
  final scheme = Theme.of(context).colorScheme;
  if (hex == null || hex.trim().isEmpty) return scheme.primary;
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return scheme.primary;
  return Color(0xFF000000 | value);
}
