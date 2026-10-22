import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';
import './pill_option.dart';

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
                  curve: AppSpring.spatialCurve,
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
                        child: PillOption<T>(
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
