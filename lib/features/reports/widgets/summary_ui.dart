import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/amount_text.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/core/widgets/wavy_progress.dart';
import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/state_views.dart';

/// Reports hero: the total for the selected period, plus the Week/Month/Year
/// switcher and the period navigator that walks backwards through history.
class SummaryReportUi extends ConsumerWidget {
  const SummaryReportUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final period = ref.watch(reportPeriodProvider);
    final range = ref.watch(reportRangeProvider);
    final selectedBucket = ref.watch(reportSelectedBucketProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total spending',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        report.when(
          data: (data) {
            // With a bar selected the hero shows that bucket's total, which is
            // what makes "tap a bar to see that bucket's total" legible.
            final showingBucket = selectedBucket != null;
            final total = reportSelectedTotal(data, selectedBucket);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AmountText(
                  amount: total,
                  currency: currency,
                  hero: true,
                  showSign: false,
                  color: scheme.onSurface,
                  animate: true,
                  style: theme.textTheme.displayMedium,
                ),
                if (showingBucket)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      data.buckets[selectedBucket].label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 160,
            height: 56,
            child: WavyProgressIndicator(height: 8),
          ),
          error: (error, _) => InlineErrorView(
            message: 'Could not load total spending',
            onRetry: () => ref.read(reportProvider.notifier).refresh(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PillSwitcher<ReportPeriod>(
          value: period,
          options: ReportPeriod.values,
          labelBuilder: (p) => p.label,
          semanticLabel: 'Report period',
          onChanged: (p) {
            ref.read(reportPeriodProvider.notifier).state = p;
            ref.read(reportSelectedBucketProvider.notifier).state = null;
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        PeriodNavigator(
          label: range.label(),
          canGoNext: canGoToNextPeriod(range),
          onPrevious: () => navigatePeriod(ref, -1),
          onNext: () => navigatePeriod(ref, 1),
        ),
      ],
    );
  }
}
