import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/core/utils/category_icon.dart';

class PieChartWidget extends ConsumerWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);

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
        child: report.categoryData.when(
          data: (data) {
            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No expenses for this period"),
                ),
              );
            }

            final total = data.fold(0.0, (sum, item) => sum + item.amount);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. AspectRatio ensures the chart is a square without hardcoded height
                AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: double.infinity,
                      sections: data.map((item) {
                        final percentage = (item.amount / total) * 100;
                        final color = CategoryIcons.getColor(item.icon);
                        return _buildSection(item.amount, percentage, color);
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 2. Legend Section
                ...data.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _LegendItem(
                      color: CategoryIcons.getColor(item.icon),
                      text: item.name == 'Unknown'
                          ? CategoryIcons.getName(item.icon)
                          : item.name,
                      amount: item.amount,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }

  PieChartSectionData _buildSection(
    double value,
    double percentage,
    Color color,
  ) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: 40, // Slightly smaller radius for a cleaner "donut" look
      titleStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

// 3. Extracted Legend Item for better performance and reusability
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.text,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),
        Text(
          "${amount.toStringAsFixed(2)} MAD",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
