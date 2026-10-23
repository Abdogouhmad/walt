import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/transactions/widgets/transaction_detail_sheet.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// Home's "Recent" section: the latest few transactions as one grouped list.
///
/// The list follows the week recap: with a day selected in the recap, this
/// shows only that day's transactions. At most five items.
///
/// A row opens that transaction's details rather than the Activity tab: the
/// tab shows a *list*, and sending someone who tapped one row to a list of
/// fifty threw away the row they were asking about.
class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    if (transactions.isEmpty) {
      return _empty(context, selectedDay != null);
    }

    return categoriesAsync.maybeWhen(
      data: (categories) {
        if (categories.isEmpty) return _empty(context, selectedDay != null);

        // Index the categories once instead of scanning the list for every row.
        final categoryById = {for (final c in categories) c.id: c};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(
              title: selectedDay == null ? 'Recent' : _dayLabel(selectedDay),
              trailing: TextButton(
                onPressed: () => context.go('/transactions'),
                child: const Text('See all'),
              ),
            ),
            GroupedList(
              children: [
                for (var i = 0; i < transactions.length; i++)
                  StaggeredEntry(
                    key: ValueKey(transactions[i].id),
                    index: i,
                    child: _tile(
                      context,
                      transactions[i],
                      categoryById,
                      currency,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
      orElse: () => _empty(context, selectedDay != null),
    );
  }

  Widget _empty(BuildContext context, bool filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: EmptyStateView(
        title: filtered ? 'Nothing on this day' : 'No recent activity',
        message: filtered
            ? 'Pick another day, or add a transaction.'
            : 'Add a transaction to start tracking your spending.',
        icon: Icons.receipt_long_outlined,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    WaltTransaction transaction,
    Map<int, WaltCategory> categoryById,
    String currency,
  ) {
    // A deleted or not-yet-loaded category must not borrow another category's
    // name and icon: that labels someone's spending as the wrong thing. Build a
    // neutral stand-in for the id the transaction actually points at.
    final category =
        categoryById[transaction.categoryId] ??
        WaltCategory(
          id: transaction.categoryId,
          name: 'Uncategorized',
          icon: 'category',
          color:
              '#${(Theme.of(context).colorScheme.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          type: transaction.type,
        );
    final isIncome = transaction.type.toLowerCase() == 'income';

    return GroupedListTile(
      onTap: () => showTransactionDetailSheet(context, transaction),
      leading: CategoryArtwork(category: category, size: 40),
      title: Text(transaction.merchant ?? 'Unknown'),
      subtitle: Text(category.name),
      trailing: AmountText(
        amount: transaction.amount,
        currency: currency,
        isIncome: isIncome,
      ),
    );
  }

  static String _dayLabel(DateTime day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[day.weekday - 1];
  }
}
