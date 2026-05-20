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
    final percentage = (progress.progress * 100).toInt();

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.h(8)),
      padding: EdgeInsets.all(context.w(18)),
      decoration: BoxDecoration(
        color: context.colorAppScheme.surface,
        borderRadius: BorderRadius.circular(context.r(28)),
        border: Border.all(
          color: progress.isOverBudget 
              ? context.colorAppScheme.error.withAlpha(50)
              : context.colorAppScheme.outline.withAlpha(25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Row: Icon, Title, and Percentage
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.w(12)),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(context.r(16)),
                ),
                child: Icon(
                  iconData,
                  color: categoryColor,
                  size: context.w(22),
                ),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: progress.category.name,
                      type: UiTextType.bodyLarge,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    UiText(
                      text: progress.isOverBudget 
                          ? 'Exceeded by $currency ${(progress.spentAmount - progress.budget.amount).toStringAsFixed(0)}'
                          : '$currency ${progress.remaining.toStringAsFixed(0)} left',
                      type: UiTextType.bodySmall,
                      style: TextStyle(
                        color: progress.isOverBudget
                            ? context.colorAppScheme.error
                            : context.textSecondary,
                        fontWeight: progress.isOverBudget ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UiText(
                    text: '$percentage%',
                    type: UiTextType.bodyMedium,
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (progress.isOverBudget)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colorAppScheme.error,
                      size: context.w(16),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.h(20)),

          /// Progress Bar
          Stack(
            children: [
              Container(
                height: context.h(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colorAppScheme.outline.withAlpha(30),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: context.h(10),
                width: (MediaQuery.of(context).size.width - context.w(68)) * 
                       progress.progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(context.r(10)),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withAlpha(60),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),

          /// Footer Metrics: Spent vs Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  UiText(
                    text: '$currency ${progress.spentAmount.toStringAsFixed(0)}',
                    type: UiTextType.bodyMedium,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  UiText(
                    text: 'spent',
                    type: UiTextType.labelSmall,
                    style: TextStyle(
                      color: context.textSecondary.withAlpha(160),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: context.colorAppScheme.outline.withAlpha(20),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: UiText(
                  text: 'Limit $currency ${progress.budget.amount.toStringAsFixed(0)}',
                  type: UiTextType.labelSmall,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
