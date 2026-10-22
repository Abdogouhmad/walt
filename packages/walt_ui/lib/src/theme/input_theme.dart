import 'package:flutter/material.dart';

import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// The input family: text fields and the search bar.
///
/// Both are *filled* rather than outlined, so a form reads as one block of
/// paper instead of a row of boxes.
class InputTheme {
  const InputTheme._();

  /// Text fields: filled, 16dp radius, floating label.
  static InputDecorationTheme field(ColorScheme colorScheme, TextTheme t) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: t.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) =>
              t.bodyMedium?.copyWith(
                color: states.contains(WidgetState.error)
                    ? colorScheme.error
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(),
        ),
      );

  /// The search bar: the same fill as a field, but pill-shaped.
  static SearchBarThemeData search(
    ColorScheme colorScheme,
    TextTheme t,
  ) => SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
    elevation: const WidgetStatePropertyAll(0),
    side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outlineVariant)),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.rPill),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
    textStyle: WidgetStatePropertyAll(t.bodyMedium),
  );
}
