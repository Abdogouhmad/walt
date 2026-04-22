import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_transaction.dart';

final transactionProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<List<WaltTransaction>>>(
      () => TransactionNotifier(),
    );

class TransactionNotifier extends Notifier<AsyncValue<List<WaltTransaction>>> {
  final _dao = TransactionDao();

  @override
  AsyncValue<List<WaltTransaction>> build() {
    loadTransactions();
    return const AsyncValue.loading();
  }

  Future<void> loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _dao.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadTransactions();
}

final recentTransactionsProvider = Provider<List<WaltTransaction>>((ref) {
  final transactionsAsync = ref.watch(transactionProvider);

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      final now = DateTime.now();
      // Start of the day 2 days ago (midnight)
      final twoDaysAgo = DateTime(now.year, now.month, now.day - 2);

      return transactions.where((tx) => tx.date.isAfter(twoDaysAgo)).toList();
    },
    orElse: () => [],
  );
});

// load the transactions by day like today, yesterday, and date
final transactionsByDayProvider = Provider<Map<String, List<WaltTransaction>>>((
  ref,
) {
  final transactionsAsync = ref.watch(transactionProvider);

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      // Sort transactions by date descending (newest first)
      final sortedTransactions = List<WaltTransaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      final Map<String, List<WaltTransaction>> grouped = {};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      for (var tx in sortedTransactions) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        String key;

        if (txDate.isAtSameMomentAs(today)) {
          key = 'Today';
        } else if (txDate.isAtSameMomentAs(yesterday)) {
          key = 'Yesterday';
        } else {
          key = DateFormat('MMM dd, yyyy').format(tx.date);
        }

        grouped.putIfAbsent(key, () => []).add(tx);
      }
      return grouped;
    },
    orElse: () => {},
  );
});
// Summary Provider (Kept as you have it)
final summaryProvider =
    Provider<({double income, double expenses, double balance})>((ref) {
      final transactionsAsync = ref.watch(transactionProvider);
      return transactionsAsync.maybeWhen(
        data: (transactions) {
          double income = 0;
          double expenses = 0;
          for (var tx in transactions) {
            if (tx.type.toLowerCase() == 'income') {
              income += tx.amount;
            } else {
              expenses += tx.amount;
            }
          }
          return (
            income: income,
            expenses: expenses,
            balance: income - expenses,
          );
        },
        orElse: () => (income: 0.0, expenses: 0.0, balance: 0.0),
      );
    });
