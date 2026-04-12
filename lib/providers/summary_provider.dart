import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/providers/transaction_provider.dart';

class TransactionSummary {
  final double income;
  final double expenses;
  final double balance;

  TransactionSummary({
    required this.income,
    required this.expenses,
    required this.balance,
  });
}

final summaryProvider = Provider<TransactionSummary>((ref) {
  // 1. Watch the transactionProvider
  final transactionsAsync = ref.watch(transactionProvider);

  // 2. Extract the list or default to empty
  final transactions = transactionsAsync.value ?? [];

  double income = 0;
  double expenses = 0;

  for (var tx in transactions) {
    // Using lowercase to prevent "Income" vs "income" bugs
    if (tx.type.toLowerCase() == 'income') {
      income += tx.amount;
    } else {
      expenses += tx.amount;
    }
  }

  return TransactionSummary(
    income: income,
    expenses: expenses,
    balance: income - expenses,
  );
});
