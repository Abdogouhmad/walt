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

/// Shared day-header formatter.
///
/// Built once rather than per transaction: the grouping provider walks the
/// whole list on every change and `DateFormat` construction is not free.
final _dayHeaderFormat = DateFormat('MMM dd, yyyy');

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

  Future<void> refresh() => loadTransactions();
}

/// Day the home week-recap has selected. `null` means "no filter" (all recent).
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Account card selected on Home, or `null` for every account.
///
/// Home is a summary, not a ledger: picking an account narrows the balance,
/// the week chart and the recent list together so the three never disagree
/// about which slice of spending the user is looking at.
final homeAccountIdProvider = StateProvider<int?>((ref) => null);

/// Transactions in the account currently selected on Home.
final homeTransactionsProvider = Provider<List<WaltTransaction>>((ref) {
  final transactions = ref.watch(transactionProvider).value ?? const [];
  final accountId = ref.watch(homeAccountIdProvider);
  if (accountId == null) return transactions;
  return transactions
      .where((tx) => tx.accountId == accountId)
      .toList(growable: false);
});

/// Recent transactions, newest first, limited to a handful for the home list.
///
/// No day selected means "the latest transactions", full stop — not a window
/// around today. A window here silently hides the list from anyone whose newest
/// entry is older than it, which reads as an empty home screen while the Activity
/// tab lists the very same rows.
final recentTransactionsProvider = Provider<List<WaltTransaction>>((ref) {
  final transactions = ref.watch(homeTransactionsProvider);
  final selected = ref.watch(selectedDayProvider);
  final maxItems = ref.watch(recentActivityLimitProvider);

  // `transactionProvider` is loaded with `ORDER BY date DESC`, and
  // `homeTransactionsProvider` only filters that list, so the newest rows are
  // already at the front. Sorting the whole history on every rebuild was
  // O(n log n) work to show five rows; stopping at the limit makes it O(k).
  if (selected == null) {
    return transactions.take(maxItems).toList(growable: false);
  }

  final selectedDay = dateOnly(selected);
  final recent = <WaltTransaction>[];
  for (final tx in transactions) {
    // A day selected in the recap filters to that day. Matching on the calendar
    // day (not the instant) is what keeps this working: transactions are stamped
    // with the moment they were added, so they carry a time-of-day, and comparing
    // against a midnight boundary would drop them.
    if (daysBetween(selectedDay, dateOnly(tx.date)) != 0) continue;
    recent.add(tx);
    if (recent.length == maxItems) break;
  }
  return recent;
});

/// Home shows at most five recent items.
final recentActivityLimitProvider = StateProvider<int>((ref) => 5);

/// Expense totals per weekday for the week containing [selectedDayProvider],
/// Monday first, always exactly seven entries.
final weekSpendingProvider = Provider<List<double>>((ref) {
  final transactions = ref.watch(homeTransactionsProvider);
  final selected = ref.watch(selectedDayProvider);
  return spendingByWeekday(
    transactions: transactions,
    anchor: selected ?? DateTime.now(),
  );
});

/// Balance, income and expenses for the account selected on Home.
final homeSummaryProvider =
    Provider<({double income, double expenses, double balance})>((ref) {
      final transactions = ref.watch(homeTransactionsProvider);
      double income = 0;
      double expenses = 0;
      for (final tx in transactions) {
        if (tx.isIncome) {
          income += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }
      return (income: income, expenses: expenses, balance: income - expenses);
    });

// load the transactions by day like today, yesterday, and date
final transactionsByDayProvider = Provider<Map<String, List<WaltTransaction>>>((
  ref,
) {
  final transactions = ref.watch(transactionProvider).value ?? const [];

  // The DAO returns newest first and every mutation reloads through it, so the
  // list is already in the order the Activity screen renders. Re-sorting (and
  // copying) the entire history on every change was redundant work per rebuild.
  final Map<String, List<WaltTransaction>> grouped = {};
  final now = DateTime.now();
  final today = dateOnly(now);
  final yesterday = addDays(today, -1);

  for (final tx in transactions) {
    final txDate = dateOnly(tx.date);
    String key;

    if (txDate.isAtSameMomentAs(today)) {
      key = 'Today';
    } else if (txDate.isAtSameMomentAs(yesterday)) {
      key = 'Yesterday';
    } else {
      key = _dayHeaderFormat.format(tx.date);
    }

    (grouped[key] ??= []).add(tx);
  }
  return grouped;
});
