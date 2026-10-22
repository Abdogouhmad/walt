import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// The button family: filled, outlined, text, icon and segmented.
///
/// One hierarchy, one shape. The three text buttons differ only in fill and
/// outline, so they are themed together rather than each drifting on its own.
class AppButtonTheme {
  const AppButtonTheme._();

  /// The primary call to action: full-round, flat, no shadow.
  static FilledButtonThemeData filled(ColorScheme colorScheme, TextTheme t) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  /// The secondary action: an outline instead of a fill.
  static OutlinedButtonThemeData outlined(
    ColorScheme colorScheme,
    TextTheme t,
  ) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      side: BorderSide(color: colorScheme.outline),
      shape: const StadiumBorder(),
      textStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  /// The tertiary action: no chrome at all beyond the label.
  static TextButtonThemeData text(ColorScheme colorScheme, TextTheme t) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const StadiumBorder(),
          textStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  /// Icon buttons: 48dp square, stadium-shaped, with a themed overlay.
  static IconButtonThemeData icon(ColorScheme colorScheme) =>
      IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: const WidgetStatePropertyAll(AppRadius.stadium),
          // Subtle hover + pressed tint that follows the color scheme instead
          // of the default grey overlay.
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? colorScheme.primary.withValues(alpha: 0.08)
                : states.contains(WidgetState.pressed)
                ? colorScheme.primary.withValues(alpha: 0.12)
                : null,
          ),
        ),
      );

  /// Segmented buttons: one step tighter than the text buttons.
  static SegmentedButtonThemeData segmented(ColorScheme colorScheme) =>
      const SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 44)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
        ),
      );
}
