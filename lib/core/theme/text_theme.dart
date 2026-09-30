import 'package:flutter/material.dart';

/// Walt's type scale (spec §1.3).
///
/// The base is the Material 3 scale shipped with Flutter. On top of it:
///   * `display*` and `headline*` are pushed to a heavier weight (w600–w700)
///     and slightly tightened, which is where the app's "expressive" accent
///     lives (hero balances, section titles, nav labels).
///   * `body*` and `label*` stay quiet at w400/w500 so they never compete.
///   * [tabular] enables tabular figures — essential for money columns, where
///     digits must not shift horizontally as values animate.
abstract final class AppTextTheme {
  const AppTextTheme._();

  /// The bundled variable font family.
  ///
  /// Bundled, never fetched: the app has to render correctly offline and on
  /// first launch, and a runtime download would mean a fallback face — and a
  /// visibly different layout — on exactly the users with the slowest
  /// connections.
  static const String fontFamily = 'RobotoFlex';

  /// Digits that all occupy the same advance width.
  ///
  /// Used by the hero balance, list amounts and budget figures so a changing
  /// number never reflows the layout around it.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];

  /// The `WALT` wordmark in the home app bar.
  ///
  /// Lives here rather than as an inline `copyWith` on the home screen: a
  /// tracked-out all-caps lockup is a type decision, and if a screen is the
  /// only place that knows about it, the next screen that needs a wordmark
  /// will invent a slightly different one.
  static TextStyle? wordmark(TextTheme theme) => theme.titleLarge?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    fontVariations: const [
      FontVariation('wght', 700),
      FontVariation('opsz', 22),
    ],
  );

  /// Roboto Flex exposes a continuous `opsz` axis. Wiring it to the rendered
  /// size lets the font swap in the sturdier, more open letterforms that stay
  /// legible at large sizes and the tighter, denser ones that survive at small
  /// sizes — one axis doing work that otherwise needs separate families.
  ///
  /// Applied per slot via `fontVariations` rather than a blanket
  /// `FontFeature`, because the value is a point size, not a boolean.
  static TextTheme build(ColorScheme scheme) {
    // Start from the *geometry* theme, not `material2021().black`.
    //
    // `Typography` splits a text theme in two: `black`/`white` carry colour
    // only, while `englishLike`/`dense`/`tall` carry the sizes and weights.
    // `ThemeData` merges them for you; reading `.black` directly hands back a
    // theme whose `fontSize` is null everywhere, which silently drops the whole
    // scale and lets every role fall back to the ambient default. Taking the
    // geometry explicitly is what makes the pinned sizes below real.
    final geometry = Typography.englishLike2021;
    final base = geometry.apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    /// Re-tones one slot of the scale.
    ///
    /// [opsz] is in points, matching the `TextStyle.fontSize` that Flutter will
    /// render at, so the axis tracks the real optical size instead of a guessed
    /// bucket. [wght] is pinned through `fontWeight`; Roboto Flex also has
    /// `GRAD`, which is left at its default so the weights stay on the
    /// familiar Material curve.
    ///
    /// Passing [size] sets `fontSize` *and* drives `opsz` from the same number.
    /// Deriving the axis from the size that actually renders is the only way to
    /// keep the two from drifting: the axis and the glyphs are then describing
    /// the same point size, and a spec row that says 44 is honoured as 44
    /// rather than as Material's nearby 45.
    TextStyle? emph(
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

    return base.copyWith(
      // ── Display: the hero-balance tier. Heaviest and tightest. ───────────
      displayLarge: emph(
        base.displayLarge,
        FontWeight.w700,
        spacing: -1.2,
        size: 72,
      ),
      displayMedium: emph(
        base.displayMedium,
        FontWeight.w700,
        spacing: -1.0,
        size: 44,
      ),
      displaySmall: emph(
        base.displaySmall,
        FontWeight.w700,
        spacing: -0.6,
        size: 36,
      ),

      // ── Headline: screen and section titles. ────────────────────────────
      headlineLarge: emph(
        base.headlineLarge,
        FontWeight.w700,
        spacing: -0.8,
        size: 34,
      ),
      headlineMedium: emph(
        base.headlineMedium,
        FontWeight.w600,
        spacing: -0.6,
        size: 28,
      ),
      headlineSmall: emph(
        base.headlineSmall,
        FontWeight.w600,
        spacing: -0.4,
        size: 24,
      ),

      // ── Title: list item headers. ───────────────────────────────────────
      titleLarge: emph(
        base.titleLarge,
        FontWeight.w600,
        spacing: -0.2,
        size: 22,
      ),
      titleMedium: emph(base.titleMedium, FontWeight.w600, size: 16),
      titleSmall: emph(base.titleSmall, FontWeight.w600, size: 14),

      // ── Body + label: deliberately quiet. ───────────────────────────────
      bodyLarge: emph(base.bodyLarge, FontWeight.w400, size: 16, spacing: 0.15),
      bodyMedium: emph(
        base.bodyMedium,
        FontWeight.w400,
        size: 14,
        spacing: 0.25,
      ),
      bodySmall: emph(base.bodySmall, FontWeight.w400, size: 12, spacing: 0.4),
      labelLarge: emph(
        base.labelLarge,
        FontWeight.w600,
        size: 14,
        spacing: 0.1,
      ),
      labelMedium: emph(
        base.labelMedium,
        FontWeight.w500,
        size: 12,
        spacing: 0.5,
      ),
      // Material's labelSmall is 11pt; the spec's floor is 12. Bumping the size
      // is better than clamping the user's text scale, which is the control
      // they actually asked for.
      labelSmall: emph(
        base.labelSmall,
        FontWeight.w500,
        size: 12,
        spacing: 0.5,
      ),
    );
  }
}
