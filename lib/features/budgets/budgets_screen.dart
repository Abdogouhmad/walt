// lib/features/budgets/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/features/budgets/widgets/budget_card.dart';
import 'package:walt/features/budgets/widgets/budget_sheet.dart';
import 'package:walt/features/budgets/widgets/empty_state.dart';
import 'package:walt/features/budgets/widgets/sumcard.dart';
import 'package:walt/providers/budget_progress_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/text_ui.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsProgress = ref.watch(budgetProgressProvider);
    final summary = ref.watch(budgetSummaryProvider);

    final currency = ref.watch(
      settingsProvider.select((s) => s.currency),
    );

    final thisMonth = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BudgetSumCard(
                currency: currency,
                summary: summary,
                month: thisMonth,
              ),

              SizedBox(height: context.h(24)),

              UiText(
                text: 'Active Budgets',
                type: UiTextType.titleLarge,
                style: TextStyle(
                  color: context.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: context.h(16)),

              if (budgetsProgress.isEmpty)
                EmptyState(
                  title: 'No budgets set yet',
                  subtitle:
                      'Create a budget to keep your spending in check.',
                  icon: Icons.account_balance_wallet_outlined,
                  topPadding: context.h(40),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgetsProgress.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: context.h(12)),
                  itemBuilder: (context, index) {
                    final progress = budgetsProgress[index];

                    return BudgetCard(
                      progress: progress,
                      currency: currency,
                    );
                  },
                ),

              SizedBox(height: context.h(100)),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetBottomSheet(context),
        backgroundColor: context.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAddBudgetBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BudgetSheet(),
    );
  }
}
