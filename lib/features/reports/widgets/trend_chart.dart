import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/reports/widgets/trend_chart_data.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt_ui/walt_ui.dart';

/// Spending over time for the selected period, as a bar chart filling its
/// container. The bucket count follows the period: 7 days for a week, one per
/// day for a month, 12 for a year.
///
/// Tapping a bar selects it — it turns `primary` while the rest sit in
/// `primaryContainer` — and the hero total above the chart switches to that
/// bucket's spending.
class TrendChart extends ConsumerWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final selectedIndex = ref.watch(reportSelectedBucketProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);

    return report.when(
      data: (data) {
        final buckets = data.buckets;
        if (buckets.isEmpty || !data.hasExpense) {
          return const EmptyStateView(
            title: 'No spending in this period',
            icon: Icons.bar_chart_rounded,
          );
        }

        return BarChart(
          buildTrendChartData(
            buckets: buckets,
            selectedIndex: selectedIndex,
            scheme: theme.colorScheme,
            tooltipStyle: theme.textTheme.labelMedium!,
            axisLabelStyle: theme.textTheme.labelSmall,
            currency: currency,
            onSelect: (index) {
              ref.read(reportSelectedBucketProvider.notifier).state = index;
            },
          ),
        );
      },
      loading: () => const LoadingStateView(),
      error: (error, _) => InlineErrorView(
        message: 'Could not load the trend',
        onRetry: () => ref.read(reportProvider.notifier).refresh(),
      ),
    );
  }
}
