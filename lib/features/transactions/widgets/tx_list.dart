import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

/// One transaction row inside a [GroupedList], with swipe-to-delete and undo.
class TxList extends ConsumerWidget {
  final WaltTransaction transaction;
  final String categoryName;
  final String categoryIcon;
  final String? categoryColor;

  const TxList({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type.toLowerCase() == 'income';
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    return Slidable(
      key: Key(transaction.id.toString()),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.24,
        dismissible: DismissiblePane(
          onDismissed: () => _handleDelete(context, ref),
        ),
        children: [
          SlidableAction(
            onPressed: (context) => _handleDelete(context, ref),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
      child: GroupedListTile(
        leading: CategoryAvatar(icon: categoryIcon, color: categoryColor),
        title: Text(transaction.merchant ?? 'Unknown Merchant'),
        subtitle: Text(
          '$categoryName • ${DateFormat('HH:mm').format(transaction.date)}',
        ),
        trailing: AmountText(
          amount: transaction.amount,
          currency: currency,
          isIncome: isIncome,
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final txToDelete = transaction;

    ref.read(transactionProvider.notifier).deleteTransaction(txToDelete.id);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted ${txToDelete.merchant ?? 'transaction'}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(transactionProvider.notifier).addTransaction(txToDelete);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}
