import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:walt/data/models/budget_period.dart';
import 'package:walt/data/reports/budget_window.dart';
import 'package:walt_ui/walt_ui.dart';

final _weekLabel = DateFormat('MMM d');
final _monthLabel = DateFormat('MMM');
final _yearLabel = DateFormat('yyyy');

/// Short axis label for one period.
String budgetPeriodLabel(BudgetPeriod period, DateTime start) =>
    switch (period) {
      BudgetPeriod.weekly => _weekLabel.format(start),
      BudgetPeriod.monthly => _monthLabel.format(start),
      BudgetPeriod.yearly => _yearLabel.format(start),
    };

/// Full label for a period card.
String budgetPeriodTitle(BudgetPeriod period, DateTime start) =>
    switch (period) {
      BudgetPeriod.weekly => 'Week of ${_weekLabel.format(start)}',
      BudgetPeriod.monthly => DateFormat('MMMM yyyy').format(start),
      BudgetPeriod.yearly => _yearLabel.format(start),
    };

/// Spending per period as a bar chart.
///
/// Bars are spending, not percentage: the point of history is to compare the
/// actual amounts month to month, and a percentage bar would hide that a 50%
/// month and a 50% month can be wildly different sums. The period's limit is
/// shown in the tooltip because it can change between periods.
class BudgetHistoryChart extends StatelessWidget {
  const BudgetHistoryChart({
    super.key,
    required this.summaries,
    required this.currency,
    this.height = 168,
  });

  final List<BudgetPeriodSummary> summaries;
  final String currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final walt = WaltColors.of(context);

    // The provider returns newest first; a chart reads left-to-right in time.
    final periods = summaries.take(8).toList(growable: false).reversed.toList();
    if (periods.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No periods yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxSpent = periods.fold<double>(
      0,
      (max, p) => p.spent > max ? p.spent : max,
    );
    final maxLimit = periods.fold<double>(
      0,
      (max, p) => p.limit > max ? p.limit : max,
    );
    final peak = maxSpent > maxLimit ? maxSpent : maxLimit;
    final maxY = peak <= 0 ? 1.0 : peak * 1.2;
    // `reservedSize` is in logical pixels, so it has to grow with the user's
    // text scale or the date labels are clipped at large sizes.
    final labelHeight = MediaQuery.textScalerOf(context).scale(11) + 12;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) {
                final index = group.x;
                if (index < 0 || index >= periods.length) return null;
                final period = periods[index];
                return BarTooltipItem(
                  '${budgetPeriodTitle(period.window.period, period.window.start)}\n'
                  '${MoneyFormat.withCode(period.spent, currency: currency)} '
                  'of ${MoneyFormat.withCode(period.limit, currency: currency)}',
                  theme.textTheme.labelSmall!.copyWith(
                    color: scheme.onInverseSurface,
                  ),
                );
              },
            ),
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
                reservedSize: labelHeight,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= periods.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      budgetPeriodLabel(
                        periods[index].window.period,
                        periods[index].window.start,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(periods.length, (index) {
            final period = periods[index];
            final isCurrent = period.isCurrent;
            final color = period.isOver
                ? walt.expense
                : (isCurrent ? scheme.primary : scheme.primaryContainer);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: period.spent,
                  width: periods.length <= 6 ? 20 : 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xs),
                  ),
                  color: color,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
