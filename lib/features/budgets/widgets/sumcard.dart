import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/progress_bar.dart';
import 'package:walt/shared/status_badge.dart';
import 'package:walt/shared/text_ui.dart';

/// Big summary card at the top of the Budgets screen: month, total spent vs
/// budget, a shared [RoundedProgressBar] and status pills.
class BudgetSumCard extends StatelessWidget {
  final Map<String, dynamic> summary;
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
    final scheme = Theme.of(context).colorScheme;
    final totalBudget = (summary['totalBudget'] ?? 0.0).toDouble();
    final totalSpent = (summary['totalSpent'] ?? 0.0).toDouble();
    final percentage = (summary['percentage'] ?? 0.0).toDouble();
    final remainingDays = (summary['remainingDays'] ?? 0.0).toInt();
    final usedPercent = (percentage * 100).toStringAsFixed(0);
    final isOverBudget = totalSpent > totalBudget;

    return M3Ecard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      data: AppCardData(
        colorCard: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.surface),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: "Monthly Budget",
                      type: UiTextType.labelLarge,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    UiText(
                      text: month,
                      type: UiTextType.titleLarge,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                StatusBadge(
                  label: "$usedPercent% used",
                  variant: StatusBadgeVariant.accent,
                  icon: Icons.percent,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: UiText(
                    text: "$currency ${totalSpent.toStringAsFixed(0)}",
                    type: UiTextType.headlineMedium,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xs,
                    left: AppSpacing.xs,
                  ),
                  child: UiText(
                    text: "/ $currency ${totalBudget.toStringAsFixed(0)}",
                    type: UiTextType.bodyMedium,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            RoundedProgressBar(
              value: percentage,
              color: isOverBudget ? scheme.error : scheme.primary,
              height: 8,
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  text: "$remainingDays days remaining",
                  type: UiTextType.labelSmall,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                StatusBadge(
                  label: isOverBudget ? "Over budget" : "On track",
                  variant: isOverBudget
                      ? StatusBadgeVariant.error
                      : StatusBadgeVariant.success,
                  icon: isOverBudget
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}