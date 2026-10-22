import 'package:flutter/material.dart';

import '../tokens/motion.dart';

/// Prev / label / next control that walks through reporting periods. The "next"
/// arrow disables itself once the user reaches the current period.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous period',
          onPressed: onPrevious,
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: AppMotion.short,
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
        _NavArrow(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next period',
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}
