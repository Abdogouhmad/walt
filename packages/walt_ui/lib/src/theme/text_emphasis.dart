import 'package:flutter/material.dart';

/// Re-tones one slot of the type scale.
///
/// [opsz] is in points, matching the `TextStyle.fontSize` that Flutter will
/// render at, so the axis tracks the real optical size instead of a guessed
/// bucket. [wght] is pinned through `fontWeight`; Roboto Flex also has `GRAD`,
/// which is left at its default so the weights stay on the familiar Material
/// curve.
///
/// Passing [size] sets `fontSize` *and* drives `opsz` from the same number.
/// Deriving the axis from the size that actually renders is the only way to
/// keep the two from drifting: the axis and the glyphs are then describing the
/// same point size, and a spec row that says 44 is honoured as 44 rather than
/// as Material's nearby 45.
TextStyle? emphasize(
  TextStyle? s,
  FontWeight weight, {
  double spacing = -0.5,
  double? size,
  double? opticalSize,
}) {
  if (s == null) return null;
  final resolved = size ?? opticalSize ?? s.fontSize ?? 14;
  return s.copyWith(
    fontSize: size ?? s.fontSize,
    fontWeight: weight,
    letterSpacing: spacing,
    fontVariations: <FontVariation>[
      FontVariation('wght', weight.value.toDouble()),
      FontVariation('opsz', resolved.clamp(8, 144)),
    ],
  );
}
