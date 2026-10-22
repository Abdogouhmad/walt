import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// Small pill showing a label and a value, used for balance breakdowns.
///
/// Lives in the shared kit so the Income/Expenses pills on Home, the report
/// stat tiles and the budget summary all render identically.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.label,
    required this.amount,
    this.icon,
    this.foreground,
    this.background,
    this.compact = false,
  });

  final String label;
  final String amount;
  final IconData? icon;

  /// Typically a semantic colour from `WaltColors` (income / expense).
  final Color? foreground;
  final Color? background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foreground ?? theme.colorScheme.onSurfaceVariant;
    final bg = background ?? theme.colorScheme.surfaceContainerHighest;

    return Semantics(
      label: '$label: $amount',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 14 : 16, color: fg),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: fg),
                  ),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              color: fg,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
