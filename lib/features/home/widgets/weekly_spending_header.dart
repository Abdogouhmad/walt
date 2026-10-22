import 'package:flutter/material.dart';

import 'package:walt_ui/walt_ui.dart';

/// The card's heading: the week title, the selected day's hint, and the
/// week's total spend.
class WeeklySpendingHeader extends StatelessWidget {
  const WeeklySpendingHeader({
    super.key,
    required this.subtitle,
    required this.total,
  });

  /// Either the "tap a day to filter" hint or the selected day's label.
  final String subtitle;

  /// The week's total spend, already formatted for display.
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This week', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                // The hint is longer than the date it is replaced by, and
                // a second line here would make the whole card jump 16px
                // the first time a day is selected.
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          total,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
