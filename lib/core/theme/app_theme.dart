import 'package:flutter/material.dart';

import 'package:walt/core/design/radius.dart';
import 'package:walt/core/design/spacing.dart';

/// Fallback seed color when the platform can't provide a dynamic scheme
/// (older Android or non-Material-You devices). Walt's deep slate brand tone.
///
/// This is the **only** hardcoded color constant allowed in the app — every
/// other surface derives from the resolved [ColorScheme] (spec §1.1).
const Color kBrandSeedColor = Color(0xFF1F2937);

/// Corner profile mandated by the design system: 28dp for large *surfaces*
/// (cards, sheets, dialogs) and 16dp for *fields and buttons*.
final BorderRadius kSurfaceRadius = BorderRadius.circular(AppRadius.surface);
final BorderRadius kFieldRadius = BorderRadius.circular(AppRadius.field);

class AppTheme {
  /// Kept as an alias so existing call sites (`ColorScheme.fromSeed(...)`)
  /// still read naturally; prefer [kBrandSeedColor].
  static const Color brandColor = kBrandSeedColor;

  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final colorScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(seedColor: kBrandSeedColor, brightness: Brightness.light);
    return _baseTheme(colorScheme);
  }

  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    final colorScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(seedColor: kBrandSeedColor, brightness: Brightness.dark);
    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    // M3 default typography re-tinted to the resolved scheme. Walt ships no
    // custom font yet, so the platform default (Roboto) is used app-wide.
    final textTheme = (colorScheme.brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    final roundedShape = RoundedRectangleBorder(borderRadius: kSurfaceRadius);
    final fieldBorder = OutlineInputBorder(borderRadius: kFieldRadius);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // M3 expressive ripple — a soft, gradient ink splash instead of the
      // flat Material ripple. Falls back gracefully where unsupported.
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      // App-wide motion: the M3 expressive fade-forwards page transition.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      // ---------------------------------------------------------------------
      // Surfaces — cards, dialogs, sheets share one 28dp radius + flat outline.
      // ---------------------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: kSurfaceRadius,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: roundedShape,
        clipBehavior: Clip.antiAlias,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.surface)),
        ),
      ),

      // ---------------------------------------------------------------------
      // Buttons — 16dp radius, M3 hover/pressed overlays, no drop shadow.
      // ---------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: kFieldRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: kFieldRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: kFieldRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: kFieldRadius),
          ),
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
      ),

      // ---------------------------------------------------------------------
      // Inputs — 16dp outlined fields.
      // ---------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + AppSpacing.sm,
        ),
        border: fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder:
            fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder:
            fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) =>
              textTheme.bodyMedium?.copyWith(
                color: states.contains(WidgetState.error)
                    ? colorScheme.error
                    : colorScheme.primary,
              ) ??
              const TextStyle(),
        ),
      ),

      // ---------------------------------------------------------------------
      // Navigation — M3 bars with colour-scheme-tinted indicators.
      // ---------------------------------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: kFieldRadius),
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (states) =>
              textTheme.labelMedium?.copyWith(
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      // ---------------------------------------------------------------------
      // Feedback — snackbars, chips, progress, switches.
      // ---------------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        secondarySelectedColor: colorScheme.secondaryContainer,
        iconTheme: IconThemeData(color: colorScheme.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => Icon(
            Icons.circle,
            size: 16,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: kFieldRadius),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(milliseconds: 900),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        hoverElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: kSurfaceRadius),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // ---------------------------------------------------------------------
      // Menus / pickers / lists.
      // ---------------------------------------------------------------------
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainer),
          elevation: const WidgetStatePropertyAll(4),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: kSurfaceRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: kSurfaceRadius),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: kSurfaceRadius),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}