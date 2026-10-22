import 'package:flutter/material.dart';

import './text_scale.dart';

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
  static const String fontFamily = waltFontFamily;

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

  /// The full type scale for [scheme].
  static TextTheme build(ColorScheme scheme) => buildTextScale(scheme);
}
