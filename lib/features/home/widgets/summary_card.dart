import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/text_ui.dart';

// 1. Change this to ConsumerWidget
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Watch the summary provider
    final summary = ref.watch(summaryProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final bgColor = context.primaryCardBackground;
    final textColor = context.cardTextPrimary;
    final secondaryTextColor = context.cardTextSecondary;
    final cardIncome = context.cardIncome;
    final cardExpense = context.cardExpense;

    return Container(
      padding: EdgeInsets.all(context.w(20)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(24)),
        color: bgColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(
            text: "Total balance",
            type: UiTextType.labelMedium,
            style: TextStyle(color: secondaryTextColor),
          ),
          SizedBox(height: context.h(8)),
          UiText(
            // 3. Use summary.balance from the provider
            text: "${summary.balance.toStringAsFixed(2)} $currency",
            type: UiTextType.headlineLarge,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: context.sp(32),
            ),
          ),
          SizedBox(height: context.h(20)),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  context,
                  "Income",
                  summary.income, // From provider
                  Icons.arrow_upward,
                  currency,
                  iconColor: cardIncome,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: _miniCard(
                  context,
                  "Expenses",
                  summary.expenses, // From provider
                  Icons.arrow_downward,
                  currency,
                  iconColor: cardExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Move your _miniCard method here as a private method of the class
  Widget _miniCard(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    String currency, {
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(16)),
        color: Colors.blueGrey.withAlpha(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.w(16), color: iconColor),
              SizedBox(width: context.w(4)),
              Text(
                label,
                style: TextStyle(fontSize: context.sp(12)),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          UiText(
            text: "${value.toStringAsFixed(0)} $currency",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: CardColors(context).cardTextSecondary,
              fontSize: context.sp(14),
            ),
          ),
        ],
      ),
    );
  }
}
