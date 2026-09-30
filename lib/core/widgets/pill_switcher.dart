import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/motion.dart';

/// Animated `Week | Month | Year`-style selector.
///
/// A full-round container holding a sliding pill: the selected option sits on a
/// `secondaryContainer` background that springs to its new position, and the
/// label colour inverts to match. Selection fires a haptic click and announces
/// itself through semantics.
///
/// Generic over the option type so callers keep their own enum:
/// ```dart
/// PillSwitcher<ReportPeriod>(
///   value: period,
///   options: ReportPeriod.values,
///   labelBuilder: (p) => p.label,
///   onChanged: (p) => ref.read(reportPeriodProvider.notifier).state = p,
/// )
/// ```
class PillSwitcher<T> extends StatelessWidget {
  const PillSwitcher({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.iconBuilder,
    this.semanticLabel,
  });

  final T value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final IconData? Function(T option)? iconBuilder;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty, 'PillSwitcher needs at least one option');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final index = options.indexOf(value);
    // A value outside `options` (e.g. after a data change) must not divide by
    // zero — clamp to the first option.
    final safeIndex = index < 0 ? 0 : index;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = (constraints.maxWidth - 8) / options.length;
            return Stack(
              children: [
                // Sliding selected pill.
                AnimatedPositioned(
                  // Spring easing on an explicit tween: the pill overshoots
                  // slightly as it settles on the new option.
                  duration: AppMotion.medium,
                  curve: AppSpring.curve(AppSpring.spatial),
                  left: segmentWidth * safeIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: RepaintBoundary(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Expanded(
                        child: _PillOption(
                          option: options[i],
                          label: labelBuilder(options[i]),
                          icon: iconBuilder?.call(options[i]),
                          selected: i == index,
                          onTap: () {
                            if (options[i] == value) return;
                            HapticFeedback.selectionClick();
                            onChanged(options[i]);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PillOption<T> extends StatelessWidget {
  const _PillOption({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final T option;
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

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
                    style:
                        (compact
                                ? theme.textTheme.labelMedium
                                : theme.textTheme.labelMedium)
                            ?.copyWith(color: fg),
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

/// The one card surface the app uses: a single elevation level, tonal
/// `surfaceContainer` fill, no border and no drop shadow.
/// The app's one and only card elevation, as tonal steps of `surfaceContainer`.
///
/// A single enum rather than a pile of booleans: "tonal" and "highlight" were
/// two independent flags describing one axis, which is how a screen ends up
/// asking for both at once.
enum AppCardLevel {
  /// Recessed: grouped-list rows and inline detail.
  lowest,

  /// The default resting surface.
  low,

  /// Raised one step, for a panel that needs to sit above its neighbours.
  high,

  /// The screen's single hero, tinted with the primary container.
  primary,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.card,
    this.level = AppCardLevel.low,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Which of the app's single card elevation the surface sits at.
  ///
  /// One level of nesting, never two: a card inside a card reads as a card
  /// inside a card, not as hierarchy. [AppCardLevel.primary] is reserved for
  /// the one hero per screen — two heroes is the same as none.
  final AppCardLevel level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: switch (level) {
          AppCardLevel.primary => scheme.primaryContainer,
          AppCardLevel.high => scheme.surfaceContainerHigh,
          AppCardLevel.low => scheme.surfaceContainerLow,
          AppCardLevel.lowest => scheme.surfaceContainerLowest,
        },
        borderRadius: shape,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
