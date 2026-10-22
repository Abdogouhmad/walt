import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:walt/data/reports/report_models.dart';
import 'package:walt_ui/walt_ui.dart';

/// Builds the bar chart's data for [buckets].
///
/// [selectedIndex] is the currently tapped bar, or `null` when nothing is
/// selected — in which case every bar is drawn in the "selected" colour.
/// [onSelect] receives the tapped bar's index, or `null` when the selection
/// was cleared.
BarChartData buildTrendChartData({
  required List<PeriodBucket> buckets,
  required int? selectedIndex,
  required ColorScheme scheme,
  required TextStyle tooltipStyle,
  required TextStyle? axisLabelStyle,
  required String currency,
  required void Function(int? index) onSelect,
}) {
  final maxY = buckets.fold<double>(
    0,
    (max, b) => b.expense > max ? b.expense : max,
  );
  // A flat-zero or tiny series still needs headroom, and `maxY` of 0
  // would make fl_chart divide by zero.
  final yAxisMax = maxY <= 0 ? 1.0 : maxY * 1.25;

  return BarChartData(
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
            '${buckets[i].label}  ${shortAmount(rod.toY)} $currency',
            tooltipStyle.copyWith(color: scheme.onInverseSurface),
          );
        },
      ),
      touchCallback: (event, response) {
        if (!event.isInterestedForInteractions) return;
        final touched = response?.spot;
        if (touched == null) {
          // Tapping the empty plot area clears the selection.
          onSelect(null);
          return;
        }
        final next = touched.touchedBarGroupIndex;
        if (next < 0 || next >= buckets.length) return;
        onSelect(next == selectedIndex ? null : next);
      },
    ),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                style: axisLabelStyle?.copyWith(color: scheme.onSurfaceVariant),
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
            width: trendBarWidth(buckets.length),
            // Only the top of the bar is rounded — a full-round rod on a
            // zero-height bar would draw a dot.
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xs),
            ),
            color: isSelected ? scheme.primary : scheme.primaryContainer,
          ),
        ],
      );
    }),
  );
}

/// Bar width for a chart with [bucketCount] bars.
double trendBarWidth(int bucketCount) {
  if (bucketCount <= 7) return 22;
  if (bucketCount <= 12) return 14;
  if (bucketCount <= 16) return 9;
  return 5;
}

/// A short, tooltip-friendly rendering of [value].
String shortAmount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
