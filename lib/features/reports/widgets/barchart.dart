import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/core/constants/app_colors.dart';
//import 'package:walt/shared/text_ui.dart';

class BarChartWidget extends ConsumerWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return M3Ecard(
      variant: M3ECardVariant.outlined,
      data: AppCardData(
        colorCard: context.colorAppScheme.surface,
        title: 'Monthly Overview',
        subtitle: "Exprenses over 6 months",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SizedBox(height: 200, child: _BarChart())],
        ),
      ),
      padding: const EdgeInsets.all(16),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart();

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'][value.toInt()],
                style: TextStyle(fontSize: 11, color: context.labelBarColor),
              ),
            ),
          ),
        ),
        barGroups: List.generate(6, (i) {
          final isSelected = i == 2;
          final fillValue = [0.4, 0.55, 1.0, 0.5, 0.6, 0.3][i];

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 1.0,
                width: 28,
                borderRadius: BorderRadius.circular(50),
                color: isSelected
                    ? context.currentMonthColor
                    : context.emptyGapBar,
                rodStackItems: isSelected
                    ? []
                    : [
                        BarChartRodStackItem(
                          0,
                          fillValue,
                          context.otherMonthsColor,
                          // BorderRadius.circular(50),
                        ),
                      ],
              ),
            ],
          );
        }),
        maxY: 1.0,
        groupsSpace: 12,
      ),
    );
  }
}
