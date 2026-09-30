import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/core/widgets/staggered_entry.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/shared/state_views.dart';

/// Home's "Recent" section: the latest few transactions as one grouped list.
///
/// The list follows the week recap: with a day selected in the recap, this
/// shows only that day's transactions. At most five items.
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
                      categories,
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
    List<WaltCategory> categories,
    String currency,
  ) {
    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => categories.first,
    );
    final isIncome = transaction.type.toLowerCase() == 'income';

    return GroupedListTile(
      onTap: () => context.go('/transactions'),
      leading: CategoryAvatar(icon: category.icon, color: category.color),
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
