import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/core/utils/category_icon.dart';
import 'package:hooks_riverpod/legacy.dart';

// Use a single provider for the filter index (0 = 6 Months, 1 = 1 Year)
final reportFilterProvider = StateProvider<int>((ref) => 0);

final reportProvider =
    NotifierProvider.autoDispose<ReportNotifier, ReportState>(() {
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

class CategoryData {
  final String name;
  final double amount;
  final String color;
  final String icon;

  CategoryData({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

class ReportState {
  final AsyncValue<double> totalSpending;
  final AsyncValue<List<MonthlyData>> monthlyData;
  final AsyncValue<double> averageDailySpending;
  final AsyncValue<double> savingRate;
  final AsyncValue<List<CategoryData>> categoryData;

  ReportState({
    this.totalSpending = const AsyncValue.loading(),
    this.monthlyData = const AsyncValue.loading(),
    this.averageDailySpending = const AsyncValue.loading(),
    this.savingRate = const AsyncValue.loading(),
    this.categoryData = const AsyncValue.loading(),
  });

  ReportState copyWith({
    AsyncValue<double>? totalSpending,
    AsyncValue<List<MonthlyData>>? monthlyData,
    AsyncValue<double>? averageDailySpending,
    AsyncValue<double>? savingRate,
    AsyncValue<List<CategoryData>>? categoryData,
  }) {
    return ReportState(
      totalSpending: totalSpending ?? this.totalSpending,
      monthlyData: monthlyData ?? this.monthlyData,
      averageDailySpending: averageDailySpending ?? this.averageDailySpending,
      savingRate: savingRate ?? this.savingRate,
      categoryData: categoryData ?? this.categoryData,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  final _dao = TransactionDao();
  final _hive = HiveService.instance;

  @override
  ReportState build() {
    // Watch the filter provider to rebuild this provider when it changes
    final filterIndex = ref.watch(reportFilterProvider);

    // Initial state
    state = ReportState();

    // Trigger load data
    _loadReportData(filterIndex);

    return state;
  }

  Future<void> _loadReportData(int filterIndex) async {
    try {
      state = state.copyWith(
        totalSpending: const AsyncValue.loading(),
        monthlyData: const AsyncValue.loading(),
        averageDailySpending: const AsyncValue.loading(),
        savingRate: const AsyncValue.loading(),
        categoryData: const AsyncValue.loading(),
      );

      final now = DateTime.now();
      final monthsToLoad = filterIndex == 0 ? 6 : 12;

      // Calculate start of the range
      final startDate = DateTime(now.year, now.month - monthsToLoad + 1, 1);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final transactions = await _dao.getTransactionsBetween(startDate, endDate);
      final categories = await _hive.getAllCategories();
      final categoryMap = {for (var c in categories) c.id: c};

      double totalExpense = 0;
      double totalIncome = 0;

      final monthlyMap = <String, MonthlyData>{};
      
      // Pre-populate with all months in range
      for (int i = 0; i < monthsToLoad; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, "0")}';
        monthlyMap[monthKey] = MonthlyData(
          month: _getShortMonthName(date),
          expense: 0.0,
          income: 0.0,
        );
      }

      final categorySpendingMap = <int, double>{};

      for (var t in transactions) {
        final monthKey =
            '${t.date.year}-${t.date.month.toString().padLeft(2, "0")}';

        if (monthlyMap.containsKey(monthKey)) {
          final current = monthlyMap[monthKey]!;
          if (t.type == 'expense') {
            totalExpense += t.amount;
            monthlyMap[monthKey] = current.copyWith(
              expense: current.expense + t.amount,
            );
            categorySpendingMap[t.categoryId] =
                (categorySpendingMap[t.categoryId] ?? 0) + t.amount;
          } else {
            totalIncome += t.amount;
            monthlyMap[monthKey] = current.copyWith(
              income: current.income + t.amount,
            );
          }
        }
      }

      // Sort by key (chronological) to ensure latest month is on the right
      final sortedKeys = monthlyMap.keys.toList()..sort();
      final monthlyList = sortedKeys.map((key) => monthlyMap[key]!).toList();

      // Average daily spending (for the current month)
      final currentMonthTransactions = transactions.where(
        (t) => t.date.month == now.month && t.date.year == now.year,
      );
      final currentMonthExpense = currentMonthTransactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
      final daysInCurrentMonth = now.day;
      final avgDaily =
          daysInCurrentMonth > 0 ? currentMonthExpense / daysInCurrentMonth : 0.0;

      // Saving rate
      final savingRate =
          totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;

      // Category data
      final categoryDataList =
          categorySpendingMap.entries.map((e) {
            final cat = categoryMap[e.key];
            if (cat != null) {
              return CategoryData(
                name: CategoryIcons.getName(cat.icon),
                amount: e.value,
                color: cat.color, // keep original hex just in case
                icon: cat.icon,
              );
            } else {
              // Fallback to unknown
              return CategoryData(
                name: 'Unknown',
                amount: e.value,
                color: '#CCCCCC',
                icon: 'category',
              );
            }
          }).toList();

      state = state.copyWith(
        totalSpending: AsyncValue.data(totalExpense),
        monthlyData: AsyncValue.data(monthlyList),
        averageDailySpending: AsyncValue.data(avgDaily),
        savingRate: AsyncValue.data(savingRate),
        categoryData: AsyncValue.data(categoryDataList),
      );
    } catch (e, st) {
      state = state.copyWith(
        totalSpending: AsyncValue.error(e, st),
        monthlyData: AsyncValue.error(e, st),
        averageDailySpending: AsyncValue.error(e, st),
        savingRate: AsyncValue.error(e, st),
        categoryData: AsyncValue.error(e, st),
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
  }
}
