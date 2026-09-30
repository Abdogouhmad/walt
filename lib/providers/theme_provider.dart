import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/theme/color_schemes.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_palette.dart';
import 'package:walt/data/local/hive_service.dart';

/// Owns the user's appearance choices and the `ThemeData` they imply.
///
/// A plain `Notifier` rather than a `NotifierProvider.family` or a free
/// `Provider<ThemeData>`: there is exactly one theme, and every screen that
/// needs a colour reads it from `Theme.of(context)`. This provider's only job is
/// the *decision* — which palette, which mode, AMOLED or not — and persisting it.
class ThemeController extends Notifier<ThemeSettings> {
  /// The settings read in `main()` before `runApp`, handed to the initial
  /// build so the very first frame is already correct.
  ///
  /// Null in every other context (tests, deep links), where reading from the
  /// store is both possible and desirable.
  ThemeSettings? bootstrap;

  HiveService get _hive => HiveService.instance;

  @override
  ThemeSettings build() => bootstrap ?? _read();

  ThemeSettings _read() {
    try {
      return ThemeSettings.fromMap(_hive.readThemeSettings());
    } catch (e) {
      // A store that cannot be read is a store that has never been written, as
      // far as the theme is concerned. Refusing to start would be worse than
      // starting in the default palette.
      debugPrint('Could not read theme settings, using defaults: $e');
      return ThemeSettings.defaults;
    }
  }

  /// Applies [next] and writes every appearance key.
  ///
  /// One write for the whole value: the four keys are a single user decision,
  /// and a partial write would let a crash mid-save leave a combination that
  /// was never chosen.
  Future<void> _apply(ThemeSettings next) async {
    state = next;
    try {
      await _hive.setThemePalette(next.palette.name);
      await _hive.setThemeMode(next.mode.name);
      await _hive.setThemeAmoled(next.amoled);
      await _hive.setThemeCustomSeed(next.customSeed?.toARGB32());
    } catch (e) {
      debugPrint('Could not persist theme settings: $e');
    }
  }

  /// Selects a built-in palette, clearing any custom seed.
  ///
  /// The custom seed is dropped on purpose: leaving it set would make the
  /// selection look like it did nothing.
  Future<void> setPalette(WaltPalette palette) =>
      _apply(state.copyWith(palette: palette, customSeed: null));

  /// Selects a user-picked seed, or clears it with `null` to fall back to
  /// [ThemeSettings.palette].
  Future<void> setCustomSeed(Color? seed) => _apply(
    seed == null
        ? state.copyWith(customSeed: null)
        : state.copyWith(customSeed: seed),
  );

  /// Sets light / dark / follow-the-system.
  Future<void> setMode(ThemeMode mode) => _apply(state.copyWith(mode: mode));

  /// Toggles pure-black surfaces. Only observable while dark is in effect, but
  /// the preference itself is remembered, so a user who enables it in dark mode
  /// and then switches back to light still gets AMOLED when they return.
  Future<void> setAmoled(bool value) => _apply(state.copyWith(amoled: value));

  /// Back to Emerald, system brightness, no AMOLED, no custom seed.
  Future<void> reset() => _apply(ThemeSettings.defaults);

  /// The scheme [palette] produces in [brightness].
  ///
  /// Used by the appearance screen so a swatch and the live preview can be drawn
  /// in the brightness the user is currently looking at, without applying the
  /// choice first.
  ColorScheme schemeFor(WaltPalette palette, Brightness brightness) =>
      AppColorSchemes.forPalette(palette, brightness: brightness);

  /// The scheme the *current* settings produce in [brightness].
  ColorScheme schemeAt(Brightness brightness) =>
      AppColorSchemes.of(state, brightness);
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
