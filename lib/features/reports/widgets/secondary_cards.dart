import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/widgets/category_icon.dart';
import 'package:walt/core/widgets/pill_switcher.dart';
import 'package:walt/core/widgets/wavy_progress.dart';
import 'package:walt/data/reports/report_aggregation.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';

/// The report's totals row: total spent, average per day and the biggest
/// category. Three quiet tiles sharing one builder.
class SecondaryReportCardUi extends ConsumerWidget {
  const SecondaryReportCardUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final range = ref.watch(reportRangeProvider);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));

    return report.when(
      data: (data) => Column(
        children: [
          // `CrossAxisAlignment.start`, not `stretch`. This Column lives in a
          // sliver, so it hands its children unbounded height, and stretching a
          // Row's children asks each tile to fill infinity — which throws
          // "BoxConstraints forces an infinite height" and leaves the whole
          // flex unlaid out. Letting the tiles size to their own content also
          // keeps them from being stretched taller than the taller sibling.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total spent',
                  footnote: range.label(),
                  value: '${_short(data.totalExpense)} $currency',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Average / day',
                  footnote: range.period.label,
                  value: '${_short(data.averageDailyExpense)} $currency',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              children: [
                CategoryAvatar(
                  icon: data.biggestCategory?.icon ?? 'category',
                  color: data.biggestCategory?.color,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Biggest category',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        data.biggestCategory?.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  data.biggestCategory == null
                      ? '—'
                      : '${_short(data.biggestCategory!.amount)} $currency',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      // `CrossAxisAlignment.stretch` is deliberately not used here. This Row is
      // a loading placeholder that can be handed unbounded height (it sits under
      // `WaltChrome.constrain`), and stretching asks each tile to fill that
      // height — which resolves to infinity and throws an invalid
      // `BoxConstraints`. Two tiles of differing content height are better
      // served by letting them size to their own content and aligning at the
      // top, which is what the loaded state above already does.
      loading: () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: _MetricTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total spent',
              footnote: '',
              value: null,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: _MetricTile(
              icon: Icons.calendar_today_rounded,
              label: 'Average / day',
              footnote: '',
              value: null,
            ),
          ),
        ],
      ),
      error: (error, _) => AppCard(
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(child: Text('Could not load this period')),
            TextButton(
              onPressed: () => ref.read(reportProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String footnote;
  final String? value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.footnote,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (value == null)
            const SizedBox(
              width: 72,
              height: 24,
              child: WavyProgressIndicator(height: 6),
            )
          else
            Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          if (footnote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              footnote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
