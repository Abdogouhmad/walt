import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/theme/walt_chart_colors.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/state_views.dart';

/// Spending split by category as a donut with the period total in the middle.
/// The per-category list lives in the breakdown section below.
///
/// Nothing is drawn on the slices: no titles, no touch tooltip. A category is
/// identified by its colour, and text over a colour hides the colour.
///
/// Sections are hidden — and therefore the whole donut swaps for an empty
/// state — when the period total is zero. `fl_chart` divides each section's
/// value by the sum to lay it out, so a zero total would produce `0/0 = NaN`
/// and a blank chart.
class CategoryDonut extends ConsumerWidget {
  const CategoryDonut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Built once per frame, not once per slice: `fromScheme` generates a whole
    // series list, and a donut with twelve categories should not solve twelve
    // schemes to draw them.
    final charts = WaltChartColors.of(context);

    return report.when(
      data: (data) {
        if (data.categories.isEmpty || data.totalExpense <= 0) {
          return const EmptyStateView(
            title: 'No expenses for this period',
            icon: Icons.donut_large_rounded,
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 58,
                // `fl_chart` enables its touch system by default, which paints
                // a tooltip over the touched slice. That tooltip is the last
                // place category text was landing on top of a category colour,
                // and it covers the very colour that identifies the slice. The
                // breakdown list below already maps colour to name, so the
                // slices are read from their colour and nothing is drawn on
                // them.
                pieTouchData: PieTouchData(enabled: false),
                sections: [
                  for (final (index, item) in data.categories.indexed)
                    PieChartSectionData(
                      value: item.amount,
                      // Indexed off the same list the breakdown below renders,
                      // so a category with no colour of its own still gets a
                      // distinct slice instead of every slice being `primary`.
                      color: charts.harmonizeCategory(
                        CategoryAvatar.parseHex(item.color),
                        index,
                      ),
                      // Belt and braces: even if a future section sets a
                      // title, it must not render over the colour.
                      title: '',
                      radius: 26,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${data.totalExpense.toStringAsFixed(0)} $currency',
                  maxLines: 1,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const LoadingStateView(),
      error: (error, _) => InlineErrorView(
        message: 'Could not load categories',
        onRetry: () => ref.read(reportProvider.notifier).refresh(),
      ),
    );
  }
}
