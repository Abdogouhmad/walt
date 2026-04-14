import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/providers/category_provider.dart'; // Import category provider
import 'package:walt/core/utils/category_icon.dart'; // Import mapper

class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);
    // Access categories to map IDs to Names/Icons
    final categoriesAsync = ref.watch(categoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleUi(
          context,
          'Recent Transactions',
          onTap: () => context.go('/transactions'),
        ),
        Expanded(
          child: transactions.isEmpty
              ? _buildEmptyState(context)
              : categoriesAsync.when(
                  data: (categories) => ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      // Find category details from the provider
                      final category = categories.firstWhere(
                        (c) => c.id == tx.categoryId,
                        orElse: () => categories.last, // Fallback to 'Other'
                      );
                      return _transactionTile(
                        context,
                        tx,
                        category.name,
                        category.icon,
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _buildEmptyState(context),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 48, color: context.listSubLabel),
          const SizedBox(height: 12),
          Text(
            "No activity in the last 2 days",
            style: TextStyle(color: context.listSubLabel),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(
    BuildContext context,
    WaltTransaction tx,
    String catName,
    String catIcon,
  ) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final amount = '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} MAD';
    final formattedDate = DateFormat('MMM dd, yyyy').format(tx.date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: context.listContainer,
        child: Icon(CategoryIcons.getIcon(catIcon), color: context.listIconBk),
      ),
      title: Text(
        tx.merchant ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$formattedDate • $catName',
        style: TextStyle(color: context.listSubLabel, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(
              color: isIncome ? context.listIncome : context.listExpense,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tx.type
                .toUpperCase(), // Showing type instead of hardcoded payment label
            style: TextStyle(fontSize: 10, color: context.listSubLabel),
          ),
        ],
      ),
      onTap: () => context.go('/transactions'),
    );
  }
}

Widget _titleUi(
  BuildContext context,
  String title, {
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UiText(
          text: title,
          type: UiTextType.titleLarge,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.listTitle,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: UiText(
            text: "View All",
            type: UiTextType.labelLarge,
            style: TextStyle(
              color: context.listColorLinks,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
