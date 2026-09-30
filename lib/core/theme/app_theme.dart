import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:walt/core/design/spacing.dart';
import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/core/theme/shapes.dart';
import 'package:walt/core/theme/text_theme.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_chart_colors.dart';
import 'package:walt/core/theme/walt_colors.dart';
import 'package:walt/core/theme/walt_palette.dart';

export 'package:walt/core/theme/shapes.dart' show AppShape;
export 'package:walt/core/theme/walt_palette.dart' show WaltPalette;

/// The single place where Walt's `ThemeData` is built (spec §1).
///
/// Both brightnesses share a single builder so a component can never be themed
/// in light but forgotten in dark.
class AppTheme {
  /// Android page transitions honour the system predictive-back gesture
  /// (spec §1.5). Other platforms keep the M3 expressive fade-forwards.
  static const PageTransitionsBuilder _transitions =
      PredictiveBackPageTransitionsBuilder();

  /// The light theme for [settings]. Defaults to the default palette.
  static ThemeData lightTheme([ThemeSettings? settings]) =>
      buildTheme(settings ?? ThemeSettings.defaults, Brightness.light);

  /// The dark theme for [settings]. Defaults to the default palette.
  static ThemeData darkTheme([ThemeSettings? settings]) =>
      buildTheme(settings ?? ThemeSettings.defaults, Brightness.dark);

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final textTheme = AppTextTheme.build(colorScheme);

    const roundedShape = RoundedRectangleBorder(
      borderRadius: AppShape.radiusExtraLarge,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Semantic money colors (income / expense / warning) and the chart series
      // live here rather than being hardcoded at call sites.
      extensions: <ThemeExtension<dynamic>>[
        WaltColors.fromScheme(colorScheme),
        WaltChartColors.fromScheme(colorScheme),
      ],
      // M3 expressive ripple — a soft, gradient ink splash instead of the
      // flat Material ripple. Falls back gracefully where unsupported.
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,

      // ---------------------------------------------------------------------
      // Surfaces — cards, dialogs, sheets share one 28dp radius + flat outline.
      // ---------------------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusExtraLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: roundedShape,
        clipBehavior: Clip.antiAlias,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: AppShape.sheet(),
      ),

      // ---------------------------------------------------------------------
      // Sliver app bars — collapsing large titles with a scrolled-under tint.
      // ---------------------------------------------------------------------
      appBarTheme: AppBarTheme(
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
      ),

      // ---------------------------------------------------------------------
      // Buttons — M3 hierarchy, full-round primary CTAs, springy press states.
      // ---------------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: colorScheme.outline),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(AppShape.stadium),
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppShape.radiusMedium),
          ),
        ),
      ),

      // ---------------------------------------------------------------------
      // Inputs — filled fields with a 16dp radius and a floating label.
      // ---------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppShape.radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppShape.radiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.radiusMedium,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShape.radiusMedium,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShape.radiusMedium,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) =>
              textTheme.bodyMedium?.copyWith(
                color: states.contains(WidgetState.error)
                    ? colorScheme.error
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppShape.radiusFull),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
      ),

      // ---------------------------------------------------------------------
      // Feedback — snackbars float above the nav pill, chips, progress.
      // ---------------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.inversePrimary,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondarySelectedColor: colorScheme.secondaryContainer,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        showCheckmark: false,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: colorScheme.onPrimary,
                )
              : null,
        ),
      ),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
        trackHeight: 8,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppShape.radiusSmall,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(milliseconds: 900),
      ),

      // ---------------------------------------------------------------------
      // Navigation — the custom pill bar is the primary chrome; the M3
      // NavigationBar theme is kept in sync for its large-screen fallback.
      // ---------------------------------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        hoverElevation: 6,
        highlightElevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusExtraLarge,
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // ---------------------------------------------------------------------
      // Menus / pickers / lists / motion.
      // ---------------------------------------------------------------------
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHigh,
          ),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppShape.radiusMedium),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusMedium,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusMedium,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppShape.radiusExtraLarge,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _transitions,
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Builds the `ThemeData` for [settings] at [brightness].
///
/// This is the whole theming contract: the user's palette becomes a scheme, the
/// scheme becomes a theme, and every screen reads roles off that theme. Nothing
/// downstream knows what a palette is, which is why adding one is a single
/// entry in [WaltPalette].
///
/// Memoised on the scheme. `_baseTheme` is a pure function of the `ColorScheme`,
/// and `MaterialApp` asks for *both* brightnesses on every rebuild of the widget
/// that watches the appearance provider — as well as the appearance screen's own
/// preview card. Without the cache that is two full theme constructions (text
/// theme, every component theme, both extensions) per rebuild, for a result that
/// cannot have changed.
///
/// The cache is bounded by construction rather than by eviction: the key is the
/// scheme, and the schemes come from a fixed palette list times two brightnesses
/// times a single AMOLED flag, so it holds at most a few dozen entries and never
/// evicts anything.
ThemeData buildTheme(ThemeSettings settings, Brightness brightness) {
  final colorScheme = AppColorSchemes.of(settings, brightness);
  return _themeCache.putIfAbsent(
    colorScheme,
    () => AppTheme._baseTheme(colorScheme),
  );
}

final Map<ColorScheme, ThemeData> _themeCache = <ColorScheme, ThemeData>{};

/// The system-bar treatment for [colorScheme].
///
/// Walt draws edge to edge, so the bars are always transparent and only the
/// *icon* brightness has to track the theme. Returning this from one place is
/// what keeps the root region and the app bars from disagreeing after a palette
/// swap.
SystemUiOverlayStyle systemOverlayStyle(ColorScheme colorScheme) {
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

/// How a palette or mode change cross-fades.
///
/// Deliberately *not* sprung, unlike the rest of the app's motion: a whole-app
/// recolour that overshoots reads as a glitch, and one that snaps reads as a
/// flicker. `kThemeAnimationDuration` (300ms) with an eased-out curve is the
/// point where the new colours are legible before attention moves on.
const Curve waltThemeAnimationCurve = Curves.easeOutCubic;
