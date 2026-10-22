import 'package:flutter/material.dart';
import 'package:walt/features/budgets/widgets/budget_section_label.dart';
import 'package:walt_ui/walt_ui.dart';

/// The alert-threshold control: a slider plus a live "% spent" badge.
class BudgetAlertSlider extends StatelessWidget {
  const BudgetAlertSlider({
    super.key,
    required this.threshold,
    required this.onChanged,
  });

  /// Fraction of the limit at which the alert fires (0.5 – 1.0).
  final double threshold;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const BudgetSectionLabel('ALERT THRESHOLD'),
            StatusBadge(
              label: '${(threshold * 100).toInt()}% spent',
              variant: StatusBadgeVariant.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.16),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: threshold,
            min: .5,
            max: 1,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
