import 'package:flutter/material.dart';
import 'package:walt_ui/walt_ui.dart';

/// One quiet metric tile: an icon, a label, a value (or a shimmer while it
/// loads) and an optional footnote.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.footnote,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String footnote;

  /// `null` renders the loading shimmer instead of a number.
  final String? value;

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
