import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/budget_period_snapshot_dao.dart';
import 'package:walt/data/models/budget_period.dart';
import 'package:walt/data/models/walt_budget.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/reports/date_math.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/transaction_provider.dart';

final budgetProvider =
    NotifierProvider<BudgetNotifier, AsyncValue<List<WaltBudget>>>(
      () => BudgetNotifier(),
    );

class BudgetNotifier extends Notifier<AsyncValue<List<WaltBudget>>> {
  final BudgetDao _dao = BudgetDao();
  final BudgetPeriodSnapshotDao _snapshots = BudgetPeriodSnapshotDao();

  @override
  AsyncValue<List<WaltBudget>> build() {
    _loadBudgets();
    return const AsyncValue.loading();
  }

  Future<void> _loadBudgets() async {
    state = await AsyncValue.guard(() async {
      final budgets = await _dao.getAllBudgets();
      // Snapshot the current limit before the cards render. This is what makes
      // an edit next month unable to rewrite what this month allowed. A failure
      // here must not hide the budgets, so each write is best-effort.
      //
      // One anchor for the whole batch keeps every budget in the same period,
      // and running the writes together avoids a per-budget round-trip on the
      // first load after a restart.
      final now = DateTime.now();
      await Future.wait([
        for (final budget in budgets) _ensureSnapshot(budget, now),
      ]);
      return budgets;
    });
  }

  Future<void> _ensureSnapshot(WaltBudget budget, DateTime now) async {
    try {
      await _snapshots.ensureCurrentSnapshot(
        budgetId: budget.id,
        window: BudgetWindow.forPeriod(BudgetPeriodX.parse(budget.period), now),
        limit: budget.amount,
      );
    } catch (e) {
      debugPrint('BudgetNotifier: could not snapshot ${budget.id} — $e');
    }
  }

  /// Mutations keep the previous list visible while the write happens, so
  /// dependent providers (progress, alerts) never see a transient empty state
  /// and the budget cards don't flash back to 0%.
  Future<void> addBudget(WaltBudget budget) async {
    await _dao.insertBudget(budget);
    await _loadBudgets();
  }

  Future<void> updateBudget(WaltBudget budget) async {
    await _dao.updateBudget(budget);
    // Keep the current period's history in sync without touching older rows.
    try {
      await _snapshots.replaceCurrentSnapshot(
        budgetId: budget.id,
        window: BudgetWindow.forPeriod(
          BudgetPeriodX.parse(budget.period),
          DateTime.now(),
        ),
        limit: budget.amount,
      );
    } catch (e) {
      debugPrint('BudgetNotifier: could not update snapshot ${budget.id} — $e');
    }
    await _loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await _dao.deleteBudget(id);
    await _loadBudgets();
  }

  Future<void> refresh() => _loadBudgets();

  /// Pin/unpin from a card without writing the whole budget, which would race
  /// an open edit sheet.
  Future<void> togglePinned(int id) async {
    final current = state.value ?? const <WaltBudget>[];
    final matches = current.where((b) => b.id == id);
    if (matches.isEmpty) return;
    final budget = matches.first;

    final nextPinned = !budget.isPinned;
    final nextOrder = nextPinned
        ? current.where((b) => b.isPinned).fold<int>(-1, (order, b) {
                return math.max(order, b.pinOrder);
              }) +
              1
        : 0;

    await _dao.setPinned(id: id, isPinned: nextPinned, pinOrder: nextOrder);
    await _loadBudgets();
  }

  /// Persists the order of the pinned section. Only called with the complete
  /// pinned list, so a reorder can never leave two budgets on one index.
  Future<void> reorderPinned(List<int> orderedIds) async {
    await _dao.reorderPinned(orderedIds);
    await _loadBudgets();
  }
}

/// A budget joined with its categories and its consumption for the current
/// period window.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.categories,
    required this.calculation,
    required this.now,
  });

  final WaltBudget budget;
  final List<WaltCategory> categories;
  final BudgetCalculation calculation;
  final DateTime now;

  /// The first selected category, used as the legacy category when a caller
  /// only needs one.
  WaltCategory get category => categories.isNotEmpty
      ? categories.first
      : WaltCategory(
          id: budget.categoryId,
          name: 'Unknown',
          icon: 'help_outline',
          // No stored accent: the artwork falls back to the theme palette.
          color: '',
          type: 'expense',
        );

  /// The user's label, falling back to the category names so budgets created
  /// before names existed still read as something meaningful.
  String get displayName {
    final name = budget.name.trim();
    if (name.isNotEmpty) return name;
    if (categories.isEmpty) return 'Budget';
    return categories.map((c) => c.name).join(', ');
  }

  String get categoryNames => categories.isEmpty
      ? category.name
      : categories.map((c) => c.name).join(', ');

  double get spentAmount => calculation.spent;
  double get limit => calculation.limit;
  double get progress => calculation.ratio;
  double get rawProgress => calculation.rawRatio;
  double get remaining => calculation.remaining;
  bool get isOverBudget => calculation.isExceeded;
  bool get isNearLimit => calculation.isNearLimit;

  /// Days left in the current window, including today. Counting today matters:
  /// on the last day there is still one day to spend, and the bar should say
  /// "1 day left" rather than "0".
  int get daysLeft => math.max(
    1,
    calculation.window.dayCount - calculation.window.elapsedDays(now) + 1,
  );

  int get totalDays => calculation.window.dayCount;

  bool get isLastDay => daysLeft == 1;

  /// How much can still be spent per remaining day. Zero once the limit is
  /// reached or spent.
  double get dailyAllowance {
    if (limit <= 0 || remaining <= 0) return 0;
    return remaining / daysLeft;
  }

  /// Where "today" sits inside the window, for the marker on the wave bar.
  double get todayFraction {
    if (totalDays <= 0) return 0;
    return (calculation.window.elapsedDays(now) / totalDays).clamp(0.0, 1.0);
  }
}

final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetProvider).value ?? const <WaltBudget>[];
  final categories =
      ref.watch(categoryProvider).value ?? const <WaltCategory>[];
  final transactions = ref.watch(transactionProvider).value ?? const [];
  final now = ref.watch(budgetClockProvider);

  final byId = {for (final c in categories) c.id: c};

  // Bucket expenses once. A transaction explicitly booked against a budget
  // belongs only to that budget; everything else keeps the legacy
  // category-based attribution. Handing each budget just its slice turns what
  // used to be a full scan of the history per budget — O(budgets ×
  // transactions) — into a single pass, O(transactions).
  final linkedByBudget = <int, List<WaltTransaction>>{};
  final unassignedByCategory = <int, List<WaltTransaction>>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    final budgetId = t.budgetId;
    if (budgetId != null) {
      (linkedByBudget[budgetId] ??= []).add(t);
    } else {
      (unassignedByCategory[t.categoryId] ??= []).add(t);
    }
  }

  return budgets.map((budget) {
    final ids = budget.effectiveCategoryIds;
    final budgetCategories = [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    final relevant = <WaltTransaction>[
      ...?linkedByBudget[budget.id],
      for (final id in ids) ...?unassignedByCategory[id],
    ];

    return BudgetProgress(
      budget: budget,
      categories: budgetCategories,
      calculation: calculateBudget(
        budget: budget,
        transactions: relevant,
        now: now,
      ),
      now: now,
    );
  }).toList();
});

/// Pinned budgets in the user's chosen order, for the Home summary.
final pinnedBudgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  return ref
      .watch(budgetProgressProvider)
      .where((p) => p.budget.isPinned)
      .toList(growable: false);
});

/// Typed replacement for the old stringly-typed `Map<String, dynamic>` summary.
final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final progress = ref.watch(budgetProgressProvider);
  final now = ref.watch(budgetClockProvider);
  return summariseBudgets(
    progress.map((p) => p.calculation).toList(),
    now: now,
  );
});

/// Injectable clock so tests and rollover checks are deterministic.
final budgetClockProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Real per-period history for one budget.
///
/// The limit of a past period comes from its snapshot; spending is always
/// recomputed from transactions, so correcting a transaction updates the chart
/// without rewriting the limit that period was measured against.
final budgetHistoryProvider = FutureProvider.autoDispose
    .family<List<BudgetPeriodSummary>, int>((ref, budgetId) async {
      final now = ref.watch(budgetClockProvider);
      final transactions =
          ref.watch(transactionProvider).value ?? const <WaltTransaction>[];
      final budgets = ref.watch(budgetProvider).value ?? const <WaltBudget>[];

      final matches = budgets.where((b) => b.id == budgetId);
      if (matches.isEmpty) return const [];
      final budget = matches.first;

      final period = BudgetPeriodX.parse(budget.period);
      final currentWindow = BudgetWindow.forPeriod(period, now);

      final dao = BudgetPeriodSnapshotDao();
      await dao.ensureCurrentSnapshot(
        budgetId: budget.id,
        window: currentWindow,
        limit: budget.amount,
      );
      final snapshots = await dao.getSnapshotsForBudget(budget.id);
      final limitsByStart = {
        for (final s in snapshots) s.start.millisecondsSinceEpoch: s.limit,
      };

      final maxPeriods = switch (period) {
        BudgetPeriod.weekly => 10,
        BudgetPeriod.monthly => 12,
        BudgetPeriod.yearly => 5,
      };

      // Stop at the period containing the earliest matching transaction, but
      // always show the current one and at least a handful of empty periods.
      final matching = transactions.where(
        (t) => transactionCountsForBudget(t, budget),
      );
      DateTime? earliest;
      for (final t in matching) {
        if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
      }

      final summaries = <BudgetPeriodSummary>[];
      for (var i = 0; i < maxPeriods; i++) {
        final window = _shiftedWindow(period, currentWindow, -i);
        final isCurrent = window.start == currentWindow.start;
        final limit = isCurrent
            ? budget.amount
            : limitsByStart[window.start.millisecondsSinceEpoch] ??
                  budget.amount;
        final spent = spendingInWindow(
          budget: budget,
          transactions: transactions,
          window: window,
        );
        summaries.add(
          BudgetPeriodSummary(
            window: window,
            limit: limit,
            spent: spent,
            isCurrent: isCurrent,
          ),
        );

        if (i >= 5 &&
            earliest != null &&
            window.start.isBefore(dateOnly(earliest))) {
          break;
        }
      }

      return summaries;
    });

BudgetWindow _shiftedWindow(
  BudgetPeriod period,
  BudgetWindow current,
  int delta,
) {
  switch (period) {
    case BudgetPeriod.weekly:
      return BudgetWindow(
        period: period,
        start: addDays(current.start, delta * 7),
        endExclusive: addDays(current.start, (delta + 1) * 7),
      );
    case BudgetPeriod.monthly:
      return BudgetWindow(
        period: period,
        start: DateTime(current.start.year, current.start.month + delta, 1),
        endExclusive: DateTime(
          current.start.year,
          current.start.month + delta + 1,
          1,
        ),
      );
    case BudgetPeriod.yearly:
      return BudgetWindow(
        period: period,
        start: DateTime(current.start.year + delta, 1, 1),
        endExclusive: DateTime(current.start.year + delta + 1, 1, 1),
      );
  }
}
