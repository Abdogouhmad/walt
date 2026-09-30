import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/state_views.dart';

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
    final scheme = theme.colorScheme;

    return report.when(
      data: (data) {
        final buckets = data.buckets;
        if (buckets.isEmpty || !data.hasExpense) {
          return EmptyStateView(
            title: 'No spending in this period',
            icon: Icons.bar_chart_rounded,
          );
        }

        final maxY = buckets.fold<double>(
          0,
          (max, b) => b.expense > max ? b.expense : max,
        );
        // A flat-zero or tiny series still needs headroom, and `maxY` of 0
        // would make fl_chart divide by zero.
        final yAxisMax = maxY <= 0 ? 1.0 : maxY * 1.25;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: yAxisMax,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, _, rod, _) {
                  final i = group.x;
                  if (i < 0 || i >= buckets.length) return null;
                  return BarTooltipItem(
                    '${buckets[i].label}  ${_short(rod.toY)} $currency',
                    theme.textTheme.labelMedium!.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  );
                },
              ),
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) return;
                final touched = response?.spot;
                if (touched == null) {
                  // Tapping the empty plot area clears the selection.
                  ref.read(reportSelectedBucketProvider.notifier).state = null;
                  return;
                }
                final next = touched.touchedBarGroupIndex;
                if (next < 0 || next >= buckets.length) return;
                ref.read(reportSelectedBucketProvider.notifier).state =
                    next == selectedIndex ? null : next;
              },
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    // 31 daily bars cannot all carry a label legibly.
                    final stride = buckets.length > 16 ? 5 : 1;
                    if (index % stride != 0 && index != buckets.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(
                        buckets[index].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(buckets.length, (i) {
              final isSelected = selectedIndex == null || i == selectedIndex;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: buckets[i].expense,
                    width: barWidth(buckets.length),
                    // Only the top of the bar is rounded — a full-round rod on a
                    // zero-height bar would draw a dot.
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xs),
                    ),
                    color: isSelected
                        ? scheme.primary
                        : scheme.primaryContainer,
                  ),
                ],
              );
            }),
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

  static double barWidth(int bucketCount) {
    if (bucketCount <= 7) return 22;
    if (bucketCount <= 12) return 14;
    if (bucketCount <= 16) return 9;
    return 5;
  }

  static String _short(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
