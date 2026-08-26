import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/text_ui.dart';

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
    final totalBudget = (summary['totalBudget'] ?? 0.0).toDouble();

    final totalSpent = (summary['totalSpent'] ?? 0.0).toDouble();

    final percentage = (summary['percentage'] ?? 0.0).toDouble();

    final remainingDays = (summary['remainingDays'] ?? 0.0).toInt();

    final usedPercent = (percentage * 100).toStringAsFixed(0);

    final isOverBudget = totalSpent > totalBudget;

    return Container(
      padding: EdgeInsets.all(context.w(24)),
      decoration: BoxDecoration(
        color: context.colorAppScheme.surface,
        borderRadius: BorderRadius.circular(context.r(32)),
        border: Border.all(color: context.primary.withAlpha(100), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ─── HEADER
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
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: context.h(4)),

                  UiText(
                    text: month,
                    type: UiTextType.titleLarge,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              /// percent chip
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  color: context.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(context.r(14)),
                ),
                child: UiText(
                  text: "$usedPercent% used",
                  type: UiTextType.labelSmall,
                  style: TextStyle(
                    color: context.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(28)),

          /// ─── MAIN AMOUNT
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
                padding: EdgeInsets.only(
                  bottom: context.h(4),
                  left: context.w(6),
                ),
                child: UiText(
                  text: "/ $currency ${totalBudget.toStringAsFixed(0)}",
                  type: UiTextType.bodyMedium,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(20)),

          /// ─── PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(20)),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: context.h(8),
              backgroundColor: context.primary.withAlpha(100),
              valueColor: AlwaysStoppedAnimation(
                isOverBudget ? Colors.red : context.primary,
              ),
            ),
          ),

          SizedBox(height: context.h(16)),

          /// ─── FOOTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UiText(
                text: "$remainingDays days remaining",
                type: UiTextType.labelSmall,
                style: TextStyle(color: context.textSecondary),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(10),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Colors.red.withAlpha(100)
                      : context.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: UiText(
                  text: isOverBudget ? "Over budget" : "On track",
                  type: UiTextType.labelSmall,
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : context.primary,
                    fontWeight: FontWeight.bold,
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
