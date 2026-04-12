import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/text_ui.dart';

// 1. Change this to ConsumerWidget
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Watch the summary provider
    final summary = ref.watch(summaryProvider);
    final bgColor = context.primaryCardBackground;
    final textColor = context.cardTextPrimary;
    final secondaryTextColor = context.cardTextSecondary;
    final cardIncome = context.cardIncome;
    final cardExpense = context.cardExpense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 8),
          UiText(
            // 3. Use summary.balance from the provider
            text: "${summary.balance.toStringAsFixed(2)} MAD",
            type: UiTextType.headlineLarge,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  context,
                  "Income",
                  summary.income, // From provider
                  Icons.arrow_upward,
                  iconColor: cardIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniCard(
                  context,
                  "Expenses",
                  summary.expenses, // From provider
                  Icons.arrow_downward,
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
    IconData icon, {
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blueGrey.withAlpha(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          const SizedBox(height: 6),
          UiText(
            text: "${value.toStringAsFixed(0)} MAD",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SummaryCardColors(context).cardTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
