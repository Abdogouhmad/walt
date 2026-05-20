import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';
// import 'package:walt/shared/text_ui.dart';
// import 'package:walt/shared/text_ui.dart';

class BudgetSumCard extends StatelessWidget {
  final Map<String, double> summary;
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
    final totalBudget = summary['totalBudget'] ?? 0.0;
    final totalSpent = summary['totalSpent'] ?? 0.0;
    final percentage = summary['percentage'] ?? 0.0;

    final usedPercent = (percentage * 100).toStringAsFixed(0);
    final remainingDays = summary['remainingDays'] ?? 0.0;

    return M3Ecard(
      padding: const EdgeInsets.all(16),
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: context.cardTextPrimary.withAlpha(200), width: 0.8)),
        title: "Total Budget Spent",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── MAIN AMOUNT
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$currency ${totalSpent.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: context.cardTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: " / ${totalBudget.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── CHIP (% USED)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.secondaryButton,
                borderRadius: BorderRadius.circular(20),
              ),
              child: UiText(
               text: "$usedPercent% USED",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
                type: UiTextType.labelMedium,
              ),
            ),

            const SizedBox(height: 12),

            // ── FOOTER
            UiText(
              text: "${remainingDays.toInt()} days remaining in $month",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              type: UiTextType.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
