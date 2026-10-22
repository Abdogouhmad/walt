import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/bounded_memo.dart';
import './app_button_theme.dart';
import './color_schemes.dart';
import './feedback_theme.dart';
import './input_theme.dart';
import './navigation_theme.dart';
import './surface_theme.dart';
import './text_theme.dart';
import './theme_settings.dart';
import './walt_chart_colors.dart';
import './walt_colors.dart';
import './walt_palette.dart';

export './walt_palette.dart' show WaltPalette;

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

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final textTheme = AppTextTheme.build(colorScheme);

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

      // Surfaces — cards, dialogs, sheets share one 28dp radius + flat outline.
      cardTheme: SurfaceTheme.card(colorScheme),
      dialogTheme: SurfaceTheme.dialog(colorScheme, textTheme),
      bottomSheetTheme: SurfaceTheme.sheet(colorScheme),
      appBarTheme: SurfaceTheme.appBar(colorScheme, textTheme),

      // Buttons — M3 hierarchy, full-round primary CTAs, springy press states.
      filledButtonTheme: AppButtonTheme.filled(colorScheme, textTheme),
      outlinedButtonTheme: AppButtonTheme.outlined(colorScheme, textTheme),
      textButtonTheme: AppButtonTheme.text(colorScheme, textTheme),
      iconButtonTheme: AppButtonTheme.icon(colorScheme),
      segmentedButtonTheme: AppButtonTheme.segmented(colorScheme),

      // Inputs — filled fields with a 16dp radius and a floating label.
      inputDecorationTheme: InputTheme.field(colorScheme, textTheme),
      searchBarTheme: InputTheme.search(colorScheme, textTheme),

      // Feedback — snackbars float above the nav pill, chips, progress.
      snackBarTheme: FeedbackTheme.snackBar(colorScheme, textTheme),
      chipTheme: FeedbackTheme.chip(colorScheme, textTheme),
      progressIndicatorTheme: FeedbackTheme.progress(colorScheme),
      switchTheme: FeedbackTheme.toggle(colorScheme),
      sliderTheme: FeedbackTheme.slider(colorScheme),
      tooltipTheme: FeedbackTheme.tooltip(colorScheme, textTheme),

      // Navigation — the custom pill bar is the primary chrome; the M3
      // NavigationBar theme is kept in sync for its large-screen fallback.
      navigationBarTheme: NavigationTheme.bar(colorScheme, textTheme),
      floatingActionButtonTheme: NavigationTheme.fab(colorScheme),
      menuTheme: NavigationTheme.menu(colorScheme),
      popupMenuTheme: NavigationTheme.popup(colorScheme),
      listTileTheme: NavigationTheme.listTile(colorScheme),
      dividerTheme: NavigationTheme.divider(colorScheme),
      datePickerTheme: NavigationTheme.datePicker(colorScheme),

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
/// Bounded by eviction rather than by construction: the key is the scheme, and
/// a scheme can come from a *free-form* custom seed — the colour picker
/// produces one distinct seed per pointer move, and each of them used to leave
/// a full `ThemeData` behind for the life of the process.
ThemeData buildTheme(ThemeSettings settings, Brightness brightness) {
  final colorScheme = AppColorSchemes.of(settings, brightness);
  return _themeCache.getOrPut(
    colorScheme,
    () => AppTheme._baseTheme(colorScheme),
  );
}

/// How many themes are kept. Sized like the scheme cache below it, and for the
/// same reason: the built-in palettes need a couple of dozen entries, and the
/// rest is headroom for the custom seeds a drag produces.
const int _themeCacheCapacity = 64;

final BoundedMemo<ColorScheme, ThemeData> _themeCache =
    BoundedMemo<ColorScheme, ThemeData>(_themeCacheCapacity);

/// The system-bar treatment for [colorScheme].
///
/// Walt draws edge to edge, so the bars are always transparent and only the
/// *icon* brightness has to track the theme. Returning this from one place is
/// what keeps the root region and the app bars from disagreeing after a palette
/// swap.
SystemUiOverlayStyle systemOverlayStyle(ColorScheme colorScheme) =>
    SurfaceTheme.systemOverlayStyle(colorScheme);

/// How a palette or mode change cross-fades.
///
/// Deliberately *not* sprung, unlike the rest of the app's motion: a whole-app
/// recolour that overshoots reads as a glitch, and one that snaps reads as a
/// flicker. `kThemeAnimationDuration` (300ms) with an eased-out curve is the
/// point where the new colours are legible before attention moves on.
const Curve waltThemeAnimationCurve = Curves.easeOutCubic;
