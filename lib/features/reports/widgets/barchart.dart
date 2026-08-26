import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/constants/app_colors.dart'; // Ensure these extensions are defined
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/providers/report_provider.dart';

class BarChartWidget extends ConsumerWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final filterIndex = ref.watch(reportFilterProvider);

    return M3Ecard(
      variant: M3ECardVariant.filled,
      padding: const EdgeInsets.all(20),
      data: AppCardData(
        colorCard: context.colorAppScheme.surface,
        title: 'Monthly Overview',
        subtitle: filterIndex == 0
            ? "Expenses over 6 months"
            : "Expenses over 12 months",
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
              child: report.monthlyData.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text("No data available"));
                  }
                  final maxExpense = data.fold(
                    0.0,
                    (max, e) => e.expense > max ? e.expense : max,
                  );
                  return _BarChartContent(
                    data: data.map((e) => e.expense).toList(),
                    labels: data.map((e) => e.month).toList(),
                    maxExpense: maxExpense,
                    selectedIndex: data.length - 1,
                    isYear: filterIndex == 1,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
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
  final double maxExpense;
  final int selectedIndex;
  final bool isYear;

  const _BarChartContent({
    required this.data,
    required this.labels,
    required this.maxExpense,
    required this.selectedIndex,
    required this.isYear,
  });

  @override
  Widget build(BuildContext context) {
    final yAxisMax = maxExpense == 0 ? 1.0 : maxExpense * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yAxisMax,
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
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }
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
                toY: data[i],
                width: isYear ? 25 : 35,
                borderRadius: BorderRadius.circular(100),
                color: isSelected
                    ? context.currentMonthColor
                    : context.otherMonthsColor,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: yAxisMax,
                  color: context.emptyGapBar,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
