import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';

class PieChartWidget extends ConsumerWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define your data in a list to map through it (Cleaner & easier to maintain)
    final chartData = [
      _ChartData(40, 'Food', context.colorAppScheme.primary),
      _ChartData(30, 'Transport', context.colorAppScheme.secondary),
      _ChartData(20, 'Entertainment', context.colorAppScheme.tertiary),
      _ChartData(10, 'Others', context.colorAppScheme.error),
    ];

    return M3Ecard(
      variant: M3ECardVariant.filled,
      padding: const EdgeInsets.all(20),
      data: AppCardData(
        colorCard: context.colorAppScheme.surface,
        title: 'Monthly Overview',
        subtitle: 'By Category',
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: context.colorAppScheme.secondary.withAlpha(50),
            width: 1,
          ), // Subtle border for better definition
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AspectRatio ensures the chart is a square without hardcoded height
            AspectRatio(
              aspectRatio:
                  1.3, // Slightly wider than tall looks better with center text
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: double
                      .infinity, // Set to infinity with an AspectRatio/Expanded wrapper
                  sections: chartData
                      .map((data) => _buildSection(data))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 2. Legend Section (Mapped for scalability)
            ...chartData.map(
              (data) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _LegendItem(color: data.color, text: data.label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildSection(_ChartData data) {
    return PieChartSectionData(
      value: data.value,
      color: data.color,
      title: '${data.value.toInt()}%',
      radius: 40, // Slightly smaller radius for a cleaner "donut" look
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

// 3. Extracted Legend Item for better performance and reusability
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Simple data class to hold the logic
class _ChartData {
  final double value;
  final String label;
  final Color color;
  _ChartData(this.value, this.label, this.color);
}
