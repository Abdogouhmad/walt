import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/shared/text_ui.dart';

class BudgetCard extends StatelessWidget {
  final BudgetProgress progress;
  final String currency;

  const BudgetCard({
    super.key,
    required this.progress,
    required this.currency,
  });

  Color _getProgressColor(BuildContext context) {
    if (progress.isOverBudget) {
      return context.colorAppScheme.error;
    }
    if (progress.isNearLimit) {
      return Colors.orangeAccent;
    }
    return context.primary;
  }

  @override
  Widget build(BuildContext context) {
    final iconData = CategoryIcons.getIcon(progress.category.icon);
    final categoryColor = Color(
      int.parse(progress.category.color.replaceAll('#', '0xFF')),
    );
    final progressColor = _getProgressColor(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.h(6)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: context.colorAppScheme.surface,
        borderRadius: BorderRadius.circular(context.r(24)),
        border: Border.all(
          color: context.colorAppScheme.outline.withAlpha(20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Row: Icon, Title, and Remaining Balance
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.w(10)),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: categoryColor,
                  size: context.w(20),
                ),
              ),
              SizedBox(width: context.w(12)),
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
                    SizedBox(height: context.h(2)),
                    UiText(
                      text: '$currency ${progress.remaining.toStringAsFixed(0)} remaining',
                      type: UiTextType.bodySmall,
                      style: TextStyle(
                        color: progress.isOverBudget
                            ? context.colorAppScheme.error
                            : context.textSecondary,
                        fontWeight: progress.isOverBudget ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),

          /// Sleek Modern Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(10)),
            child: LinearProgressIndicator(
              value: progress.progress.clamp(0.0, 1.0),
              backgroundColor: context.colorAppScheme.outline.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: context.h(7),
            ),
          ),
          SizedBox(height: context.h(12)),

          /// Footer Metrics: Spent vs Total Budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, // <-- Added this line to fix the assertion crash
                children: [
                  UiText(
                    text: '$currency ${progress.spentAmount.toStringAsFixed(0)}',
                    type: UiTextType.bodyMedium,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  UiText(
                    text: 'spent',
                    type: UiTextType.labelSmall,
                    style: TextStyle(
                      color: context.textSecondary.withAlpha(140),
                    ),
                  ),
                ],
              ),
              UiText(
                text: 'of $currency ${progress.budget.amount.toStringAsFixed(0)}',
                type: UiTextType.bodySmall,
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
