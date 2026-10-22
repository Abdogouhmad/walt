import 'package:flutter/material.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// One option inside a [PillSwitcher]: its label, an optional icon and the
/// press handling.
class PillOption<T> extends StatelessWidget {
  final T option;
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const PillOption({
    super.key,
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Animated between the two role colours so the inversion feels springy.
    final color = AnimatedSwitcher(
      duration: AppMotion.short,
      child: Text(
        label,
        key: ValueKey('$option-$selected'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Flexible(child: color),
            ],
          ),
        ),
      ),
    );
  }
}
