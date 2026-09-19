import 'package:flutter/material.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/progress_bar.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/text_ui.dart';

/// One budget row in the Budgets screen: category icon, remaining balance,
/// an [RoundedProgressBar] and spent-vs-total footer.
class BudgetCard extends StatelessWidget {
  final BudgetProgress progress;
  final String currency;

  const BudgetCard({super.key, required this.progress, required this.currency});

  Color _trackColor(BuildContext context) {
    if (progress.isOverBudget) return Theme.of(context).colorScheme.error;
    if (progress.isNearLimit) return Colors.orangeAccent;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconData = CategoryIcons.getIcon(progress.category.icon);
    final categoryColor = Color(
      int.parse(progress.category.color.replaceAll('#', '0xFF')),
    );
    final trackColor = _trackColor(context);

    return M3Ecard(
      variant: M3ECardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      data: AppCardData(
        colorCard: scheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: categoryColor,
                    size: AppSpacing.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        text: progress.category.name,
                        type: UiTextType.bodyMedium,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      UiText(
                        text:
                            '$currency ${progress.remaining.toStringAsFixed(0)} remaining',
                        type: UiTextType.bodySmall,
                        style: TextStyle(
                          color: progress.isOverBudget
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                          fontWeight: progress.isOverBudget
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress.isOverBudget)
                  StatusBadge(
                    label: 'Over',
                    variant: StatusBadgeVariant.error,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            RoundedProgressBar(
              value: progress.progress,
              color: trackColor,
              height: 6,
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    UiText(
                      text:
                          '$currency ${progress.spentAmount.toStringAsFixed(0)}',
                      type: UiTextType.bodyMedium,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    UiText(
                      text: 'spent',
                      type: UiTextType.labelSmall,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                UiText(
                  text:
                      'of $currency ${progress.budget.amount.toStringAsFixed(0)}',
                  type: UiTextType.bodySmall,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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