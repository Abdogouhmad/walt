import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:walt/core/design/motion.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/features/reports/widgets/category_breakdown.dart';
import 'package:walt/features/reports/widgets/category_donut.dart';
import 'package:walt/features/reports/widgets/trend_chart.dart';

/// Which visualisation the report's main chart shows.
final reportChartModeProvider = StateProvider<int>((ref) => 0);

/// The report's single main chart: a pill toggle, the chart itself in a tonal
/// card, then the category legend. Switching periods cross-fades the content.
class ReportChartSection extends ConsumerWidget {
  const ReportChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(reportChartModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillSwitcher<int>(
          value: mode,
          options: const [0, 1],
          labelBuilder: (m) => m == 0 ? 'Trend' : 'Categories',
          iconBuilder: (m) =>
              m == 0 ? Icons.bar_chart_rounded : Icons.donut_large_rounded,
          semanticLabel: 'Chart type',
          onChanged: (m) =>
              ref.read(reportChartModeProvider.notifier).state = m,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 240,
            // 200ms is under the 300ms ceiling: long enough to read as a
            // transition, short enough not to feel like a wait.
            child: AnimatedSwitcher(
              duration: AppMotion.short,
              child: mode == 0
                  ? const TrendChart(key: ValueKey('trend'))
                  : const CategoryDonut(key: ValueKey('categories')),
            ),
          ),
        ),
        const CategoryBreakdown(),
      ],
    );
  }
}
