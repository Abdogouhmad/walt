import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/providers/report_provider.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/shared/m3e_card.dart';
import 'package:walt/shared/text_ui.dart';

/// Pair of summary metric cards ("Average daily" / "Saving rate").
///
/// Both cards are the same shell — icon, label, value (async), footnote —
/// so they share one [_MetricCard] builder instead of two near-identical
/// hand-rolled widgets (spec §1.3).
class SecondaryReportCardUi extends ConsumerWidget {
  const SecondaryReportCardUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final currency = ref.watch(settingsProvider).currency;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_today_rounded,
            label: "Average daily",
            value: _amount(context, report.averageDailySpending, currency),
            footnote: "Current Month",
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.savings_rounded,
            label: "saving rate",
            value: _percent(context, report.savingRate),
            footnote: "Selected Period",
          ),
        ),
      ],
    );
  }

  Widget _amount(BuildContext ctx, AsyncValue<double> v, String currency) =>
      _value(
        ctx,
        v.when(
          data: (m) => UiText(
            text: "${m.toStringAsFixed(0)} $currency",
            type: UiTextType.headlineSmall,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (_, _) =>
              const UiText(text: "Error", type: UiTextType.headlineSmall),
        ),
      );

  Widget _percent(BuildContext ctx, AsyncValue<double> v) => _value(
    ctx,
    v.when(
      data: (p) => UiText(
        text: "${p.toStringAsFixed(0)}%",
        type: UiTextType.headlineSmall,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      loading: () => const CircularProgressIndicator(strokeWidth: 2),
      error: (_, _) =>
          const UiText(text: "Error", type: UiTextType.headlineSmall),
    ),
  );

  Widget _value(BuildContext ctx, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: child,
  );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final String footnote;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return M3Ecard(
      variant: M3ECardVariant.filled,
      padding: const EdgeInsets.all(AppSpacing.lg),
      data: AppCardData(
        title: null,
        colorCard: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.surface),
          side: BorderSide(color: scheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            UiText(
              text: label.toUpperCase(),
              type: UiTextType.labelSmall,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            value,
            UiText(
              text: footnote,
              type: UiTextType.labelSmall,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}