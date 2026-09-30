import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/providers/transaction_provider.dart';

/// Granularity the reports screen is showing (Week / Month / Year).
final reportPeriodProvider = StateProvider<ReportPeriod>(
  (ref) => ReportPeriod.month,
);

/// The concrete period being displayed. Navigation shifts this by whole
/// periods; the navigator refuses to move past the current period.
final reportAnchorProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Index of the highlighted bar in the spending-over-time chart, or null when
/// the user has not tapped one.
final reportSelectedBucketProvider = StateProvider<int?>((ref) => null);

/// The resolved range for the current period + anchor.
final reportRangeProvider = Provider<ReportRange>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final anchor = ref.watch(reportAnchorProvider);
  return ReportRange.forPeriod(period, anchor);
});

/// Shared, always-fresh transaction list used by the reports aggregation.
///
/// Derived from [transactionProvider] rather than read from the DAO directly,
/// so every add/edit/delete automatically rebuilds Reports. Querying the DAO
/// here produced a second, permanently cached snapshot that went stale the
/// moment the user changed a transaction.
final reportTransactionsProvider = Provider<List<WaltTransaction>>((ref) {
  return ref.watch(transactionProvider).value ?? const [];
});

final reportProvider =
    AsyncNotifierProvider.autoDispose<ReportNotifier, ReportAggregation>(
      ReportNotifier.new,
    );

class ReportNotifier extends AsyncNotifier<ReportAggregation> {
  final HiveService _hive = HiveService.instance;

  @override
  Future<ReportAggregation> build() async {
    // Re-run whenever the period, the anchor or the underlying data changes.
    final range = ref.watch(reportRangeProvider);
    final transactions = ref.watch(reportTransactionsProvider);

    final categories = await _hive.getAllCategories();
    return aggregateReport(
      range: range,
      transactions: transactions,
      categories: {for (final c in categories) c.id: c},
    );
  }

  /// Manual reload used by the error state's retry button.
  ///
  /// Re-runs the same pure aggregation against the current transaction state
  /// rather than re-querying the DAO, so a retry can never disagree with what
  /// the auto-updating path would produce.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final range = ref.read(reportRangeProvider);
      final categories = await _hive.getAllCategories();
      return aggregateReport(
        range: range,
        transactions: ref.read(reportTransactionsProvider),
        categories: {for (final c in categories) c.id: c},
      );
    });
  }
}

/// Moves the visible period by [delta] and clears any bar selection.
/// Returns false when the move would leave the present, so the caller can keep
/// the button disabled instead of silently clamping.
bool navigatePeriod(WidgetRef ref, int delta) {
  final range = ref.read(reportRangeProvider);
  final target = range.shift(delta);
  final now = DateTime.now();
  // Never travel past the current period.
  if (target.start.isAfter(ReportRange.forPeriod(range.period, now).start)) {
    return false;
  }
  ref.read(reportAnchorProvider.notifier).state = target.anchor;
  ref.read(reportSelectedBucketProvider.notifier).state = null;
  return true;
}

/// Whether the "next period" arrow should be enabled.
bool canGoToNextPeriod(ReportRange range) {
  final now = DateTime.now();
  return range
      .shift(1)
      .start
      .isBefore(ReportRange.forPeriod(range.period, now).start);
}

/// Total for the tapped bar, or the period total when nothing is selected.
double reportSelectedTotal(ReportAggregation data, int? selectedIndex) {
  if (selectedIndex == null) return data.totalExpense;
  if (selectedIndex < 0 || selectedIndex >= data.buckets.length) {
    return data.totalExpense;
  }
  return data.buckets[selectedIndex].expense;
}
