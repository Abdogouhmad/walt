import 'package:flutter/material.dart';

import 'package:walt/core/theme/shapes.dart';

/// The one progress treatment used across Walt (budgets, category breakdown,
/// budgets summary): a thick, fully-rounded track with a rounded fill.
///
/// Hand-rolled rather than `LinearProgressIndicator` so the radius and the
/// min-height are identical everywhere and no annual-opt-in flags leak in.
class ThickProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color? trackColor;

  /// What a screen reader announces before the percentage. Null falls back to
  /// Flutter's generic "progress indicator", which is already an improvement on
  /// silence; set it where the bar means something specific ("Budget used").
  final String? semanticsLabel;

  const ThickProgress({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.trackColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final track =
        trackColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final radius = BorderRadius.circular(AppShape.full);
    final progress = value.clamp(0.0, 1.0);

    // Hand-rolled from a `Stack`, not a `LinearProgressIndicator`, which means
    // the accessibility semantics the indicator used to provide have to be
    // restored by hand — a bare `Container` reports nothing to a screen reader,
    // so a budget bar would be announced as an empty group of boxes.
    return Semantics(
      label: semanticsLabel,
      value: '${(progress * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(color: track, borderRadius: radius),
              ),
              Container(
                height: height,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ],
          );
        },
      ),
    );
  }
}
