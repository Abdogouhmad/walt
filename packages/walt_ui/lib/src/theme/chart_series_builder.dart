import 'package:flutter/material.dart';

import './chart_series.dart';
import './color_math.dart';
import './walt_chart_colors.dart';
import './walt_colors.dart';

/// Builds the chart series colours for [scheme].
///
/// The scheme's accent family, made legible on this scheme's surface and
/// ordered so no two neighbouring series look alike.
///
/// Both steps matter, and neither is something a hand-picked colour list can
/// do. Tonal-spot hands out a `*Container` role that is deliberately a pale
/// tint — fine as a chip background, invisible as a chart fill on a light
/// surface. And the tone-shifted variants sit one small step from the accent
/// they were derived from, so a naive order puts a wedge next to its own
/// parent.
WaltChartColors buildChartColors(ColorScheme scheme) {
  final semantic = WaltColors.fromScheme(scheme);
  final isDark = scheme.brightness == Brightness.dark;

  final primary = HSLColor.fromColor(scheme.primary);
  final secondary = HSLColor.fromColor(scheme.secondary);
  final tertiary = HSLColor.fromColor(scheme.tertiary);

  // Light surfaces need deeper fills and dark surfaces need lifted ones, so
  // the shifted variants move in opposite directions in the two modes.
  double shift(double value) =>
      (value + (isDark ? 0.16 : -0.12)).clamp(0.08, 0.92);

  // Shifted variants first, containers last: the order below is only a
  // starting set, but the accents have the most colour in them and so make
  // the best seeds for the legibility pass.
  final candidates = <Color>[
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    primary.withLightness(shift(primary.lightness)).toColor(),
    secondary.withLightness(shift(secondary.lightness)).toColor(),
    tertiary.withLightness(shift(tertiary.lightness)).toColor(),
    scheme.primaryContainer,
    scheme.secondaryContainer,
    scheme.tertiaryContainer,
  ];

  // A slice has to be visible against the surface it is drawn on. 3:1 is the
  // WCAG non-text threshold, and the containers routinely arrive far below
  // it in light mode. Solving them one at a time, each told about the ones
  // already accepted, is what keeps two roles from both being pushed down the
  // same ramp onto the same fill.
  final legible = <Color>[];
  for (final candidate in candidates) {
    legible.add(
      ColorMath.ensureContrast(
        candidate,
        scheme.surface,
        minRatio: 3,
        avoid: legible,
      ),
    );
  }

  return WaltChartColors(
    categorical: spreadOutSeries(legible),
    positive: semantic.income,
    negative: semantic.expense,
    track: scheme.surfaceContainerHighest,
    grid: scheme.outlineVariant,
  );
}
