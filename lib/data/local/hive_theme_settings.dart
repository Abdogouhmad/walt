import 'package:walt/data/local/hive_service.dart';
import 'package:walt_ui/walt_ui.dart';

/// `themeMode` predates the snake_case appearance keys.
const String legacyThemeModeKey = 'themeMode';

/// Every spelling the Material You toggle has been stored under. Walt draws
/// its colours from the user's palette now, so all of them are dead weight.
const List<String> removedDynamicColorKeys = <String>[
  'dynamicColor',
  'useDynamicColor',
  'dynamic_color',
];

/// Appearance storage.
///
/// Values are stored as plain primitives (enum *names*, ARGB ints) rather than
/// as the theme model, so this layer stays independent of the theme package and
/// a rename in the model can never break reading a user's saved choice.
/// `ThemeSettings` owns the encoding; see `providers/theme_provider.dart`.
extension HiveThemeSettings on HiveService {
  /// Chosen palette, as a [WaltPalette] enum name.
  Future<void> setThemePalette(String name) =>
      saveSetting(ThemeSettings.keyPalette, name);

  /// Light / dark / system, as a [ThemeMode] enum name.
  Future<void> setThemeMode(String mode) =>
      saveSetting(ThemeSettings.keyMode, mode);

  /// Pure-black surfaces in dark mode.
  Future<void> setThemeAmoled(bool value) =>
      saveSetting(ThemeSettings.keyAmoled, value);

  /// A user-picked seed as a 32-bit ARGB int, or `null` for "use the palette".
  Future<void> setThemeCustomSeed(int? argb) =>
      saveSetting(ThemeSettings.keyCustomSeed, argb);

  /// The stored appearance values, in the shape [ThemeSettings.fromMap] reads.
  ///
  /// A key that was never written is absent rather than defaulted, so
  /// "not stored" stays distinguishable from "stored as the default" and a
  /// removed palette or a renamed mode falls back on its own.
  Map<String, dynamic> readThemeSettings() => <String, dynamic>{
    ThemeSettings.keyPalette: getSetting(ThemeSettings.keyPalette),
    ThemeSettings.keyMode: getSetting(ThemeSettings.keyMode),
    ThemeSettings.keyAmoled: getSetting(ThemeSettings.keyAmoled),
    ThemeSettings.keyCustomSeed: getSetting(ThemeSettings.keyCustomSeed),
  };

  /// One-time cleanup of appearance keys whose meaning changed, and removal of
  /// the Material You preference Walt no longer supports.
  ///
  /// Called from [HiveService.init] so it happens before the first frame. The
  /// old camelCase `themeMode` is *carried over* — a user's light/dark choice
  /// is still a valid choice — whereas the dynamic-colour flag is dropped,
  /// because there is no longer a wallpaper to honour and the palette has a
  /// default.
  Future<void> migrateThemeSettings() async {
    await ensureSettingsOpen();
    final box = settingsBox;

    if (!box.containsKey(ThemeSettings.keyMode)) {
      final legacyMode = box.get(legacyThemeModeKey);
      if (legacyMode is String) {
        await box.put(ThemeSettings.keyMode, legacyMode);
      }
    }
    if (box.containsKey(legacyThemeModeKey)) {
      await box.delete(legacyThemeModeKey);
    }

    for (final key in removedDynamicColorKeys) {
      if (box.containsKey(key)) {
        await box.delete(key);
      }
    }
  }
}
