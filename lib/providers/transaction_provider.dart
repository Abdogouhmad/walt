import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/date_math.dart';
import 'package:walt/data/reports/report_aggregation.dart';

final transactionProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<List<WaltTransaction>>>(
      () => TransactionNotifier(),
    );

class TransactionNotifier extends Notifier<AsyncValue<List<WaltTransaction>>> {
  final TransactionDao _dao = TransactionDao();

  @override
  AsyncValue<List<WaltTransaction>> build() {
    loadTransactions();
    return const AsyncValue.loading();
  }

  Future<void> loadTransactions() async {
    state = await AsyncValue.guard(() => _dao.getAllTransactions());
  }

  /// Writes keep the previous list in state until the reload lands. Dropping to
  /// `AsyncLoading` mid-write made every dependent widget (budget progress,
  /// balance, reports) read an empty list and flash back to zero.
  Future<void> addTransaction(WaltTransaction transaction) async {
    await _dao.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(WaltTransaction transaction) async {
    await _dao.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _dao.deleteTransaction(id);
    await loadTransactions();
  }

  /// Re-inserts a deleted transaction, preserving its identity so an "undo"
  /// restores exactly what was there before.
  Future<void> restoreTransaction(WaltTransaction transaction) async {
    await _dao.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> refresh() => loadTransactions();
}

/// Day the home week-recap has selected. `null` means "no filter" (all recent).
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Recent transactions, newest first, limited to a handful for the home list.
final recentTransactionsProvider = Provider<List<WaltTransaction>>((ref) {
  final transactions = ref.watch(transactionProvider).value ?? const [];
  final selected = ref.watch(selectedDayProvider);
  final maxItems = ref.watch(recentActivityLimitProvider);

  final now = DateTime.now();
  final today = dateOnly(now);
  // Default view: the last three days, so the home list is never empty.
  // With a day selected: that day only, as a half-open window.
  final start = selected == null ? addDays(today, -2) : dateOnly(selected);
  final end = addDays(start, 1);

  final inRange = transactions.where((tx) {
    if (tx.date.isBefore(start) || tx.date.isAfter(end)) return false;
    return true;
  }).toList()..sort((a, b) => b.date.compareTo(a.date));

  return inRange.take(maxItems).toList();
});

/// Home shows at most five recent items.
final recentActivityLimitProvider = StateProvider<int>((ref) => 5);

/// Expense totals per weekday for the week containing [selectedDayProvider],
/// Monday first, always exactly seven entries.
final weekSpendingProvider = Provider<List<double>>((ref) {
  final transactions = ref.watch(transactionProvider).value ?? const [];
  final selected = ref.watch(selectedDayProvider);
  return spendingByWeekday(
    transactions: transactions,
    anchor: selected ?? DateTime.now(),
  );
});

// load the transactions by day like today, yesterday, and date
final transactionsByDayProvider = Provider<Map<String, List<WaltTransaction>>>((
  ref,
) {
  final transactions = ref.watch(transactionProvider).value ?? const [];

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
});

/// Balance summary across every transaction.
final summaryProvider =
    Provider<({double income, double expenses, double balance})>((ref) {
      final transactions = ref.watch(transactionProvider).value ?? const [];
      double income = 0;
      double expenses = 0;
      for (var tx in transactions) {
        if (tx.type.toLowerCase() == 'income') {
          income += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }
      return (income: income, expenses: expenses, balance: income - expenses);
    });
