import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/transactions/widgets/header_list.dart';
import 'package:walt/features/transactions/widgets/tx_list.dart';
import 'package:walt/providers/transaction_provider.dart';
import 'package:walt/providers/category_provider.dart'; // Added this

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txMap = ref.watch(transactionsByDayProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildEmptyState(context),
        data: (categories) {
          if (txMap.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            itemCount: txMap.keys.length,
            itemBuilder: (context, index) {
              final dateKey = txMap.keys.elementAt(index);
              final transactions = txMap[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: HeaderList(date: dateKey),
                  ),
                  ...transactions.map((tx) {
                    // Find category details for this specific transaction
                    final category = categories.firstWhere(
                      (c) => c.id == tx.categoryId,
                      orElse: () => categories.last, // Fallback
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text("No activity found"),
        ],
      ),
    );
  }
}
