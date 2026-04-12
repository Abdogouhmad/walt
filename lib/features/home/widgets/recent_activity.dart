import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/shared/text_ui.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:walt/providers/transaction_provider.dart'; // Ensure this is imported

class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specialized provider for the last 2 days
    final transactions = ref.watch(recentTransactionsProvider);

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
              : ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _transactionTile(context, tx);
                  },
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
          Icon(
            Icons.history_rounded,
            size: 48,
            color: context.listSubLabel.withAlpha(1),
          ),
          const SizedBox(height: 12),
          Text(
            "No activity in the last 2 days",
            style: TextStyle(color: context.listSubLabel),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(BuildContext context, WaltTransaction tx) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final amount = '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} MAD';
    final formattedDate = DateFormat('MMM dd, yyyy').format(tx.date);
    final paymentMethod = _paymentLabel(tx.categoryId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: context.listContainer,
        child: Icon(_categoryIcon(tx.categoryId), color: context.listIconBk),
      ),
      title: Text(
        tx.merchant ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$formattedDate • ${_categoryLabel(tx.categoryId)}',
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
            paymentMethod,
            style: TextStyle(fontSize: 10, color: context.listSubLabel),
          ),
        ],
      ),
      onTap: () => context.go('/transactions'),
    );
  }

  // --- Helper Methods ---

  IconData _categoryIcon(int categoryId) {
    return switch (categoryId) {
      1 => Icons.shopping_basket_outlined,
      2 => Icons.work_outline,
      3 => Icons.restaurant_outlined,
      4 => Icons.directions_car_outlined,
      _ => Icons.attach_money,
    };
  }

  String _categoryLabel(int categoryId) {
    return switch (categoryId) {
      1 => 'Shopping',
      2 => 'Work',
      3 => 'Food',
      4 => 'Travel',
      _ => 'Other',
    };
  }

  String _paymentLabel(int categoryId) {
    return switch (categoryId) {
      1 => 'DEBIT CARD',
      2 => 'DIRECT DEP.',
      3 => 'MOBILE PAY',
      4 => 'CREDIT',
      _ => 'CASH',
    };
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
