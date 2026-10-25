import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:walt/data/models/budget_period.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/budgets/widgets/budget_history_chart.dart';
import 'package:walt/features/transactions/widgets/activity_day_group.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt_ui/walt_ui.dart';

final _dayKey = DateFormat('MMM d, yyyy');

/// Opens the transactions that make up one period's spending.
Future<void> showBudgetPeriodTransactions(
  BuildContext context, {
  required WaltBudget budget,
  required BudgetPeriodSummary summary,
}) {
  return showWaltModal<void>(
    context,
    heightFactor: 0.9,
    content: BudgetPeriodTransactionsSheet(budget: budget, summary: summary),
  );
}

/// A period's transactions, grouped by day.
///
/// The list is filtered from the same rules the progress ring uses — expenses,
/// one of the budget's categories, inside the period window — so the rows add
/// up to exactly the number on the card that was tapped.
class BudgetPeriodTransactionsSheet extends ConsumerWidget {
  const BudgetPeriodTransactionsSheet({
    super.key,
    required this.budget,
    required this.summary,
  });

  final WaltBudget budget;
  final BudgetPeriodSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions =
        ref.watch(transactionProvider).value ?? const <WaltTransaction>[];
    final categories = ref.watch(categoryProvider).value ?? const [];
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final categoryIds = budget.effectiveCategoryIds.toSet();
    final filtered = transactions.where((tx) {
      if (!tx.isExpense) return false;
      if (!categoryIds.contains(tx.categoryId)) return false;
      return summary.window.contains(tx.date);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final byDay = <String, List<WaltTransaction>>{};
    for (final tx in filtered) {
      (byDay[_dayKey.format(tx.date)] ??= []).add(tx);
    }
    final categoryById = {for (final c in categories) c.id: c};

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: waltModalPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    budgetPeriodTitle(
                      summary.window.period,
                      summary.window.start,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${MoneyFormat.withCode(summary.spent, currency: currency)} '
                    'of ${MoneyFormat.withCode(summary.limit, currency: currency)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyStateView(
              title: 'No transactions',
              message:
                  'Nothing was recorded in this period for these categories.',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          for (final entry in byDay.entries)
            ActivityDayGroup(
              day: entry.key,
              transactions: entry.value,
              categoryById: categoryById,
            ),
      ],
    );
  }
}
