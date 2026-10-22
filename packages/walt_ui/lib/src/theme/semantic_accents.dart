import 'package:flutter/material.dart';

import './color_math.dart';
import './walt_colors.dart';

/// The fixed semantic hues. Chroma is left to [ColorMath.ensureContrast],
/// which only ever moves lightness, so these stay recognisable in every
/// palette.
const double incomeHue = 145;
const double expenseHue = 15;
const double warningHue = 45;

/// How far each accent is allowed to drift toward the palette. Income and
/// expense are small because their hue carries meaning; the warning is larger
/// because "amber" is a mood, not a fact about the user's money.
const double incomeHarmonize = 0.12;
const double expenseHarmonize = 0.12;
const double warningHarmonize = 0.25;

/// A semantic accent: harmonised toward the palette, hue re-asserted, tone
/// solved for legibility on [background].
Color semanticAccent(
  ColorScheme scheme,
  double hue,
  Color background,
  double harmonize,
) {
  final base = ColorMath.harmonize(
    HSLColor.fromAHSL(1, hue, 0.62, 0.32).toColor(),
    scheme.primary,
    harmonize,
  );
  final rehued = HSLColor.fromColor(base).withHue(hue).toColor();
  return ColorMath.ensureContrast(rehued, background);
}

/// Builds the semantic palette for [scheme].
///
/// [surface] is the background the accents are read against; pass
/// `surfaceContainer` for text and icons, `surface` for full-bleed fills.
WaltColors buildSemanticColors(ColorScheme scheme, {Color? surface}) {
  final background = surface ?? scheme.surfaceContainer;

  return WaltColors(
    income: semanticAccent(scheme, incomeHue, background, incomeHarmonize),
    expense: semanticAccent(scheme, expenseHue, background, expenseHarmonize),
    warning: semanticAccent(scheme, warningHue, background, warningHarmonize),
    incomeContainer: semanticContainer(scheme, incomeHue, background),
    expenseContainer: semanticContainer(scheme, expenseHue, background),
    warningContainer: semanticContainer(scheme, warningHue, background),
  );
}

/// A quiet fill in the same hue, stepped away from [background] so it reads as
/// a recessive tint rather than as another accent.
Color semanticContainer(ColorScheme scheme, double hue, Color background) {
  final hsl = HSLColor.fromColor(
    ColorMath.harmonize(
      HSLColor.fromAHSL(1, hue, 0.62, 0.5).toColor(),
      scheme.primary,
      0.12,
    ),
  ).withHue(hue);
  final onLightBackground = ColorMath.luminance(background) > 0.5;
  return hsl
      .withLightness(onLightBackground ? 0.9 : 0.28)
      .withSaturation(hsl.saturation * 0.55)
      .toColor();
}
