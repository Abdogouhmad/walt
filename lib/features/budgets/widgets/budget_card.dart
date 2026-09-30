import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/core/widgets/thick_progress.dart';
import 'package:walt/providers/budget_provider.dart';

/// One budget row: category, remaining balance, a thick progress bar and the
/// spent-vs-total footer (spec §4).
class BudgetCard extends StatelessWidget {
  final BudgetProgress progress;
  final String currency;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.progress,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    final isOver = progress.isOverBudget;
    final isNear = progress.isNearLimit && !isOver;

    final tone = isOver
        ? walt.expense
        : (isNear ? walt.warning : scheme.primary);
    final container = isOver
        ? walt.expenseContainer
        : (isNear ? walt.warningContainer : scheme.primaryContainer);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(
                  icon: progress.category.icon,
                  color: progress.category.color,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progress.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // `titleMedium` is already the w600 slot of the scale;
                        // restating the weight here would be a second source of
                        // truth for the same decision.
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOver
                            ? '$currency ${(-progress.remaining).toStringAsFixed(0)} over'
                            : '$currency ${progress.remaining.toStringAsFixed(0)} left',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOver
                              ? walt.expense
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOver || isNear)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: container,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      isOver ? 'Over' : 'Near limit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isOver
                            ? scheme.onErrorContainer
                            : scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ThickProgress(value: progress.progress, color: tone, height: 8),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AmountText(
                  amount: progress.spentAmount,
                  currency: currency,
                  color: scheme.onSurface,
                  fractionDigits: 0,
                ),
                Text(
                  'of $currency ${progress.budget.amount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
