import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';

/// The one, consistent determinate progress bar in Walt: a clipped `LinearProgressIndicator`
/// with fully rounded ends and an M3 `strokeCap`.
///
/// Before this existed every screen hand-rolled the same
/// `ClipRRect + LinearProgressIndicator + AlwaysStoppedAnimation` block with a
/// slightly different radius/height (budget card, budget summary, reports). All
/// bar-like indicators should flow through here so sizing and corner style stay
/// identical app-wide (spec §1).
class RoundedProgressBar extends StatelessWidget {
  /// 0.0–1.0 clamped progress.
  final double value;

  /// Fill color (e.g. `colorScheme.primary`, `colorScheme.error`).
  final Color color;

  /// Track color behind the fill.
  final Color backgroundColor;

  /// Bar thickness.
  final double height;

  const RoundedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor = const Color(0x00000000),
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveBackground = backgroundColor == const Color(0x00000000)
        ? scheme.surfaceContainerHighest
        : backgroundColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: effectiveBackground,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}