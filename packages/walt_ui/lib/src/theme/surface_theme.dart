import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/radius.dart';

/// The surface family: cards, dialogs, sheets and app bars.
///
/// They are themed together on purpose. A card, a dialog and a sheet are the
/// same idea at three sizes, and letting them drift apart is how an app ends
/// up with a card radius that does not match its dialog radius.
class SurfaceTheme {
  const SurfaceTheme._();

  /// Cards: flat, no elevation, one radius.
  static CardThemeData card(ColorScheme colorScheme) => CardThemeData(
    elevation: 0,
    color: colorScheme.surfaceContainerLow,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
  );

  /// Dialogs: a step above a card, with a tinted fill.
  static DialogThemeData dialog(ColorScheme colorScheme, TextTheme textTheme) =>
      DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        clipBehavior: Clip.antiAlias,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      );

  /// Bottom sheets: opaque, flat, and shaped like the app's cards.
  static BottomSheetThemeData sheet(ColorScheme colorScheme) =>
      BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: AppRadius.sheet(),
      );

  /// App bars: collapsing large titles with a scrolled-under tint.
  static AppBarTheme appBar(ColorScheme colorScheme, TextTheme textTheme) =>
      AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle(colorScheme),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      );

  /// The system-bar treatment for [colorScheme].
  ///
  /// Walt draws edge to edge, so the bars are always transparent and only the
  /// *icon* brightness has to track the theme. Returning this from one place is
  /// what keeps the root region and the app bars from disagreeing after a
  /// palette swap.
  static SystemUiOverlayStyle systemOverlayStyle(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
