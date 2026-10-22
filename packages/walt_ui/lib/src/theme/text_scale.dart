import 'package:flutter/material.dart';

import './text_emphasis.dart';

/// The bundled variable font family.
const String waltFontFamily = 'RobotoFlex';

/// Builds Walt's type scale for [scheme].
///
/// Roboto Flex exposes a continuous `opsz` axis. Wiring it to the rendered
/// size lets the font swap in the sturdier, more open letterforms that stay
/// legible at large sizes and the tighter, denser ones that survive at small
/// sizes — one axis doing work that otherwise needs separate families.
///
/// Applied per slot via `fontVariations` rather than a blanket `FontFeature`,
/// because the value is a point size, not a boolean.
TextTheme buildTextScale(ColorScheme scheme) {
  // Start from the *geometry* theme, not `material2021().black`.
  //
  // `Typography` splits a text theme in two: `black`/`white` carry colour
  // only, while `englishLike`/`dense`/`tall` carry the sizes and weights.
  // `ThemeData` merges them for you; reading `.black` directly hands back a
  // theme whose `fontSize` is null everywhere, which silently drops the whole
  // scale and lets every role fall back to the ambient default. Taking the
  // geometry explicitly is what makes the pinned sizes below real.
  const geometry = Typography.englishLike2021;
  final base = geometry.apply(
    fontFamily: waltFontFamily,
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return base.copyWith(
    // ── Display: the hero-balance tier. Heaviest and tightest. ───────────
    displayLarge: emphasize(
      base.displayLarge,
      FontWeight.w700,
      spacing: -1.2,
      size: 72,
    ),
    displayMedium: emphasize(
      base.displayMedium,
      FontWeight.w700,
      spacing: -1.0,
      size: 44,
    ),
    displaySmall: emphasize(
      base.displaySmall,
      FontWeight.w700,
      spacing: -0.6,
      size: 36,
    ),

    // ── Headline: screen and section titles. ────────────────────────────
    headlineLarge: emphasize(
      base.headlineLarge,
      FontWeight.w700,
      spacing: -0.8,
      size: 34,
    ),
    headlineMedium: emphasize(
      base.headlineMedium,
      FontWeight.w600,
      spacing: -0.6,
      size: 28,
    ),
    headlineSmall: emphasize(
      base.headlineSmall,
      FontWeight.w600,
      spacing: -0.4,
      size: 24,
    ),

    // ── Title: list item headers. ───────────────────────────────────────
    titleLarge: emphasize(
      base.titleLarge,
      FontWeight.w600,
      spacing: -0.2,
      size: 22,
    ),
    titleMedium: emphasize(base.titleMedium, FontWeight.w600, size: 16),
    titleSmall: emphasize(base.titleSmall, FontWeight.w600, size: 14),

    // ── Body + label: deliberately quiet. ───────────────────────────────
    bodyLarge: emphasize(
      base.bodyLarge,
      FontWeight.w400,
      size: 16,
      spacing: 0.15,
    ),
    bodyMedium: emphasize(
      base.bodyMedium,
      FontWeight.w400,
      size: 14,
      spacing: 0.25,
    ),
    bodySmall: emphasize(
      base.bodySmall,
      FontWeight.w400,
      size: 12,
      spacing: 0.4,
    ),
    labelLarge: emphasize(
      base.labelLarge,
      FontWeight.w600,
      size: 14,
      spacing: 0.1,
    ),
    labelMedium: emphasize(
      base.labelMedium,
      FontWeight.w500,
      size: 12,
      spacing: 0.5,
    ),
    // Material's labelSmall is 11pt; the spec's floor is 12. Bumping the size
    // is better than clamping the user's text scale, which is the control
    // they actually asked for.
    labelSmall: emphasize(
      base.labelSmall,
      FontWeight.w500,
      size: 12,
      spacing: 0.5,
    ),
  );
}
