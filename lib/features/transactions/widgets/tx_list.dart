import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/transactions/widgets/transaction_detail_sheet.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// Shared time formatter — `DateFormat('HH:mm')` per row per rebuild is
/// wasteful on a long list.
final _timeFormat = DateFormat('HH:mm');

/// One transaction row inside a [GroupedList], with swipe-to-delete and undo.
///
/// Tapping the row opens the transaction's details — the row only carries a
/// merchant, a category, a time and an amount, which is what a scanned list
/// needs and not what a *read* one does.
class TxList extends ConsumerWidget {
  final WaltTransaction transaction;
  final WaltCategory category;

  const TxList({super.key, required this.transaction, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.isIncome;
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
        onTap: () => showTransactionDetailSheet(context, transaction),
        leading: CategoryArtwork(category: category, size: 40),
        title: Text(transaction.merchant ?? 'Unknown Merchant'),
        subtitle: Text(
          '${category.name} • ${_timeFormat.format(transaction.date)}',
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
