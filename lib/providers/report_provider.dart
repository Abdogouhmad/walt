import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:hooks_riverpod/legacy.dart';

// Use a single provider for the filter index (0 = 6 Months, 1 = 1 Year)
final reportFilterProvider = StateProvider<int>((ref) => 0);

final reportProvider = NotifierProvider.autoDispose<ReportNotifier, ReportState>(() {
  return ReportNotifier();
});

class MonthlyData {
  final String month;
  final double expense;
  final double income;

  MonthlyData({
    required this.month,
    required this.expense,
    required this.income,
  });

  MonthlyData copyWith({double? expense, double? income}) {
    return MonthlyData(
      month: month,
      expense: expense ?? this.expense,
      income: income ?? this.income,
    );
  }
}

class ReportState {
  final AsyncValue<double> totalSpending;
  final AsyncValue<List<MonthlyData>> monthlyData;

  ReportState({
    this.totalSpending = const AsyncValue.loading(),
    this.monthlyData = const AsyncValue.loading(),
  });

  ReportState copyWith({
    AsyncValue<double>? totalSpending,
    AsyncValue<List<MonthlyData>>? monthlyData,
  }) {
    return ReportState(
      totalSpending: totalSpending ?? this.totalSpending,
      monthlyData: monthlyData ?? this.monthlyData,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  final _dao = TransactionDao();

  @override
  ReportState build() {
    // Re-run the data load whenever the filter changes
    ref.listen(reportFilterProvider, (previous, next) {
      _loadReportData();
    });

    // Trigger initial load after the first frame
    Future.microtask(() => _loadReportData());

    return ReportState();
  }

  Future<void> _loadReportData() async {
    final filterIndex = ref.read(reportFilterProvider);

    try {
      state = state.copyWith(
        totalSpending: const AsyncValue.loading(),
        monthlyData: const AsyncValue.loading(),
      );

      final now = DateTime.now();
      final monthsToLoad = filterIndex == 0 ? 6 : 12;

      // Calculate start of the range
      final startDate = DateTime(now.year, now.month - monthsToLoad + 1, 1);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final transactions = await _dao.getTransactionsBetween(
        startDate,
        endDate,
      );

      final totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthlyMap = <String, MonthlyData>{};
      for (var t in transactions) {
        final monthKey =
            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';

        if (!monthlyMap.containsKey(monthKey)) {
          monthlyMap[monthKey] = MonthlyData(
            month: _getShortMonthName(t.date),
            expense: 0.0,
            income: 0.0,
          );
        }

        final current = monthlyMap[monthKey]!;
        if (t.type == 'expense') {
          monthlyMap[monthKey] = current.copyWith(
            expense: current.expense + t.amount,
          );
        } else {
          monthlyMap[monthKey] = current.copyWith(
            income: current.income + t.amount,
          );
        }
      }

      final monthlyList = monthlyMap.values.toList();

      state = state.copyWith(
        totalSpending: AsyncValue.data(totalExpense),
        monthlyData: AsyncValue.data(monthlyList),
      );
    } catch (e, st) {
      state = state.copyWith(
        totalSpending: AsyncValue.error(e, st),
        monthlyData: AsyncValue.error(e, st),
      );
    }
  }

  String _getShortMonthName(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[date.month - 1];
  }

  void changeFilter(int index) {
    ref.read(reportFilterProvider.notifier).state = index;
    // Data is reloaded automatically by the listener in build()
  }
}
