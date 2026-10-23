import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt_ui/walt_ui.dart';

/// The category legend beneath the chart: one grouped row per category with
/// icon, name, amount, share percentage and a thin rounded progress bar.
class CategoryBreakdown extends ConsumerWidget {
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final charts = WaltChartColors.of(context);
    final categoryById = {
      for (final category
          in ref.watch(categoryProvider).value ?? const <WaltCategory>[])
        category.id: category,
    };

    return report.when(
      data: (data) {
        if (data.categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyStateView(
              title: 'Nothing to break down yet',
              icon: Icons.pie_chart_outline_rounded,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              title: 'By category',
              padding: EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
            ),
            GroupedList(
              children: [
                for (final (index, item) in data.categories.indexed)
                  GroupedListTile(
                    leading: CategoryArtwork(
                      category:
                          categoryById[item.categoryId] ??
                          WaltCategory(
                            id: item.categoryId,
                            name: item.name,
                            icon: item.icon,
                            color: item.color,
                            type: 'expense',
                          ),
                      size: 40,
                      seriesIndex: index,
                    ),
                    title: Text(item.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ThickProgress(
                            // `percent` is pre-guarded, never NaN.
                            value: item.percent,
                            // Same index, same scheme and therefore the same
                            // colour the donut slice above uses.
                            color: charts.harmonizeCategory(
                              CategoryAvatar.parseHex(item.color),
                              index,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${(item.percent * 100).toStringAsFixed(1)}% of spend',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: AmountText(
                      amount: item.amount,
                      currency: currency,
                      color: scheme.onSurface,
                    ),
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
