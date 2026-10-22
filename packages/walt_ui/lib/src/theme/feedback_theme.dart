import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// The feedback family: snackbars, chips, progress, switches, sliders and
/// tooltips.
///
/// Everything the user is told with, in one place, so a warning never comes
/// out in a different colour from the next one.
class FeedbackTheme {
  const FeedbackTheme._();

  /// Snackbars: floating, so they clear the floating nav pill.
  static SnackBarThemeData snackBar(ColorScheme colorScheme, TextTheme t) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: t.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.inversePrimary,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      );

  /// Chips: tonal, no checkmark — selection is carried by the fill.
  static ChipThemeData chip(ColorScheme colorScheme, TextTheme t) =>
      ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: t.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        secondarySelectedColor: colorScheme.secondaryContainer,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        showCheckmark: false,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
      );

  /// Progress: one track, one indicator, 6dp thick.
  static ProgressIndicatorThemeData progress(ColorScheme colorScheme) =>
      ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 6,
      );

  /// Switches: the selected thumb carries the error colour's counterpart —
  /// an icon, so the state survives a greyscale print.
  static SwitchThemeData toggle(ColorScheme colorScheme) => SwitchThemeData(
    thumbIcon: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary)
          : null,
    ),
  );

  /// Sliders: a chunky 8dp track and a visible value bubble.
  static SliderThemeData slider(ColorScheme colorScheme) =>
      const SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
        trackHeight: 8,
      );

  /// Tooltips: inverse surface, small radius, quick to appear.
  static TooltipThemeData tooltip(ColorScheme colorScheme, TextTheme t) =>
      TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppRadius.rSm,
        ),
        textStyle: t.bodySmall?.copyWith(color: colorScheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(milliseconds: 900),
      );
}
