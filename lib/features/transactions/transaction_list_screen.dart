import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/features/transactions/widgets/header_list.dart';
import 'package:walt/features/transactions/widgets/tx_list.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/shared/state_views.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txMap = ref.watch(transactionsByDayProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      body: categoriesAsync.maybeWhen(
        data: (categories) {
          if (txMap.isEmpty || categories.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: txMap.keys.length,
            itemBuilder: (context, index) {
              final dateKey = txMap.keys.elementAt(index);
              final transactions = txMap[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: HeaderList(date: dateKey),
                  ),
                  ...transactions.map((tx) {
                    final category = categories.firstWhere(
                      (c) => c.id == tx.categoryId,
                      orElse: () => categories.first,
                    );

                    return TxList(
                      transaction: tx,
                      categoryName: category.name,
                      categoryIcon: category.icon,
                    );
                  }),
                ],
              );
            },
          );
        },
        orElse: () => _buildEmptyState(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateView(
      title: "No activity found",
      message: "Your transactions will appear here once you add them.",
      icon: Icons.history_rounded,
    );
  }
}
