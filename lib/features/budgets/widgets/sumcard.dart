import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/core/widgets/thick_progress.dart';
import 'package:walt/data/reports/budget_aggregation.dart';

/// The Budgets hero: the period's total spent against the total budget, with a
/// progress bar and a status chip. Typed [BudgetSummary] — no stringly-typed map.
class BudgetSumCard extends StatelessWidget {
  final BudgetSummary summary;
  final String currency;
  final String month;

  const BudgetSumCard({
    super.key,
    required this.summary,
    required this.currency,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    final isOverBudget = summary.isOver;
    final tone = isOverBudget ? walt.expense : scheme.primary;
    final ratio = summary.totalBudget > 0
        ? (summary.totalSpent / summary.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: AmountText(
                amount: summary.totalSpent,
                currency: currency,
                hero: true,
                showSign: false,
                color: scheme.onSurface,
                animate: true,
                fractionDigits: 0,
                style: theme.textTheme.displayMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'of $currency ${summary.totalBudget.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ThickProgress(value: ratio, color: tone, height: 8),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              summary.remainingDays == 1
                  ? '1 day remaining'
                  : '${summary.remainingDays} days remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            StatPill(
              label: isOverBudget ? 'Over budget' : 'On track',
              amount: '${summary.percent.toStringAsFixed(0)}%',
              icon: isOverBudget
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              compact: true,
              foreground: isOverBudget
                  ? scheme.onErrorContainer
                  : scheme.onTertiaryContainer,
              background: isOverBudget
                  ? walt.expenseContainer
                  : walt.incomeContainer,
            ),
          ],
        ),
      ],
    );
  }
}
