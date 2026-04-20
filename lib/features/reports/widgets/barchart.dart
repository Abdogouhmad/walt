import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart'; // Ensure these extensions are defined
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';

class BarChartWidget extends ConsumerWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Centralize data
    final barData = [0.4, 0.55, 1.0, 0.5, 0.6, 0.3];
    final labels = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'];

    return M3Ecard(
      variant: M3ECardVariant.filled,
      padding: const EdgeInsets.all(20),
      data: AppCardData(
        colorCard: context.colorAppScheme.surface,
        title: 'Monthly Overview',
        subtitle: "Expenses over 6 months",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: context.colorAppScheme.secondary.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.7,
              child: _BarChartContent(
                data: barData,
                labels: labels,
                selectedIndex: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartContent extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final int selectedIndex;

  const _BarChartContent({
    required this.data,
    required this.labels,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
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
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                // Fix: Wrapped in block braces to satisfy linter
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }

                // Fix: Added required 'meta' argument
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: context.labelBarColor,
                      fontWeight: index == selectedIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final isSelected = i == selectedIndex;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 1.0,
                width: 22,
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? context.currentMonthColor
                    : context.emptyGapBar,
                rodStackItems: isSelected
                    ? []
                    : [
                        BarChartRodStackItem(
                          0,
                          data[i],
                          context.otherMonthsColor,
                        ),
                      ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
