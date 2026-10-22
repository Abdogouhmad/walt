import 'package:flutter/material.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/features/transactions/widgets/tx_list.dart';
import 'package:walt_ui/walt_ui.dart';

/// One day's transactions, under the day's heading.
class ActivityDayGroup extends StatelessWidget {
  const ActivityDayGroup({
    super.key,
    required this.day,
    required this.transactions,
    required this.categoryById,
  });

  final String day;
  final List<WaltTransaction> transactions;
  final Map<int, WaltCategory> categoryById;

  @override
  Widget build(BuildContext context) {
    return WaltChrome.constrain(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: day),
            GroupedList(
              children: [
                for (var i = 0; i < transactions.length; i++)
                  StaggeredEntry(
                    key: ValueKey(transactions[i].id),
                    index: i,
                    child: Builder(
                      builder: (context) {
                        final category =
                            categoryById[transactions[i].categoryId];
                        return TxList(
                          transaction: transactions[i],
                          categoryName: category?.name ?? 'Unknown',
                          categoryIcon: category?.icon ?? 'category',
                          categoryColor: category?.color,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
