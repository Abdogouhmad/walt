import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/data/models/walt_category.dart';
import 'package:walt/hive_registrar.g.dart';

class HiveService {
  // Use a specific name for the box storing JSON maps
  static const String _categoriesBoxName = 'categories_json_box';
  static const String _settingsBoxName = 'settings_box';

  static final HiveService instance = HiveService._init();
  HiveService._init();

  late Box _settingsBox;

  /// Initialize Hive
  static Future<void> init() async {
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
    }

    // Register adapters
    Hive.registerAdapters();

    instance._settingsBox = await Hive.openBox(_settingsBoxName);
    // Appearance keys changed shape in this release; cleaned up before the
    // first frame so the theme is read from a settled store.
    await instance.migrateThemeSettings();
    debugPrint('✅ Hive initialized successfully');
  }

  // ====================== CATEGORIES ======================

  /// Helper to open the categories box
  Future<Box> _getCategoriesBox() async {
    return await Hive.openBox(_categoriesBoxName);
  }

  Future<List<WaltCategory>> getAllCategories() async {
    final box = await _getCategoriesBox();
    final List<WaltCategory> categories = [];

    for (var value in box.values) {
      if (value is WaltCategory) {
        categories.add(value);
      } else if (value is Map) {
        try {
          // If it was stored as a Map (JSON), convert it
          final category = WaltCategory.fromJson(
            Map<String, dynamic>.from(value),
          );
          categories.add(category);
        } catch (e) {
          debugPrint('❌ Error parsing category from Map: $e');
        }
      } else {
        debugPrint('⚠️ Unknown category type in Hive: ${value.runtimeType}');
      }
    }
    return categories;
  }

  Future<void> saveCategories(List<WaltCategory> categories) async {
    final box = await _getCategoriesBox();
    await box.clear();

    final Map<int, WaltCategory> categoryMap = {
      for (var c in categories) c.id: c,
    };

    await box.putAll(categoryMap);
  }

  // ====================== SETTINGS ======================

  Future<void> _ensureSettingsBoxOpen() async {
    if (!_settingsBox.isOpen) {
      _settingsBox = await Hive.openBox(_settingsBoxName);
    }
  }

  /// Opens the settings box on demand so callers that run before (or instead
  /// of) `HiveService.init()` — background checks, notification evaluators —
  /// can still read and write.
  Future<void> ensureSettingsOpen() => _ensureSettingsBoxOpen();

  /// Direct access to the settings box, for bulk reads/writes (e.g. scanning
  /// recorded budget-alert keys).
  Box get settingsBox => _settingsBox;

  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureSettingsBoxOpen();
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    // getSetting is synchronous in Hive, so we assume it's open
    // or we'd have to make this async, which changes the API.
    // Given init() opens it, it should be open unless closed manually.
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // ====================== APPEARANCE ======================
  //
  // Values are stored as plain primitives (enum *names*, ARGB ints) rather than
  // as the theme model, so this layer stays independent of `core/theme` and a
  // rename in the model can never break reading a user's saved choice.
  // `ThemeSettings` owns the encoding; see `providers/theme_provider.dart`.

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
  /// Called from [init] so it happens before the first frame. The old
  /// camelCase `themeMode` is *carried over* — a user's light/dark choice is
  /// still a valid choice — whereas the dynamic-colour flag is dropped, because
  /// there is no longer a wallpaper to honour and the palette has a default.
  Future<void> migrateThemeSettings() async {
    await _ensureSettingsBoxOpen();

    if (!_settingsBox.containsKey(ThemeSettings.keyMode)) {
      final legacyMode = _settingsBox.get(_legacyThemeModeKey);
      if (legacyMode is String) {
        await _settingsBox.put(ThemeSettings.keyMode, legacyMode);
      }
    }
    if (_settingsBox.containsKey(_legacyThemeModeKey)) {
      await _settingsBox.delete(_legacyThemeModeKey);
    }

    for (final key in _removedDynamicColorKeys) {
      if (_settingsBox.containsKey(key)) {
        await _settingsBox.delete(key);
      }
    }
  }

  /// `themeMode` predates the snake_case appearance keys.
  static const String _legacyThemeModeKey = 'themeMode';

  /// Every spelling the Material You toggle has been stored under. Walt draws
  /// its colours from the user's palette now, so all of them are dead weight.
  static const List<String> _removedDynamicColorKeys = <String>[
    'dynamicColor',
    'useDynamicColor',
    'dynamic_color',
  ];

  // ====================== OTHER SETTINGS ======================

  Future<void> setCurrency(String currency) async =>
      saveSetting('currency', currency);

  String getCurrency() {
    final val = getSetting('currency', defaultValue: 'MAD');
    return val is String ? val : 'MAD';
  }

  Future<void> setUserName(String name) async => saveSetting('userName', name);

  String getUserName() {
    final val = getSetting('userName', defaultValue: 'User');
    return val is String ? val : 'User';
  }

  Future<void> setProfilePicPath(String path) async =>
      saveSetting('profilePicPath', path);

  String? getProfilePicPath() {
    final val = getSetting('profilePicPath');
    return val is String ? val : null;
  }

  Future<void> setOnboardingCompleted(bool completed) async =>
      saveSetting('onboardingCompleted', completed);

  bool isOnboardingCompleted() {
    final val = getSetting('onboardingCompleted', defaultValue: false);
    return val is bool ? val : false;
  }

  /// A stored boolean flag, falling back to [defaultValue] if the key is absent
  /// *or holds anything else*.
  ///
  /// Every flag read goes through here rather than a cast. Hive is untyped: a
  /// value written by an older build, a partially-migrated box or a hand-edited
  /// file can turn up as an int or a string, and `value as bool` throws on those.
  /// That throw used to land in `_loadSettings`' catch-all, which reset the
  /// user's *entire* settings state — a corrupt `reduceTransparency` silently
  /// threw away their name, avatar and currency. One bad key now costs one flag.
  bool getFlag(String key, {required bool defaultValue}) {
    final val = getSetting(key);
    if (val is bool) return val;
    // A flag stored as 0/1 is a common older encoding; accept it rather than
    // resetting the user's preference over a representation change.
    if (val is int) return val != 0;
    return defaultValue;
  }

  // ====================== UTILITY ======================

  Future<void> clearAll() async {
    if (!_settingsBox.isOpen) {
      _settingsBox = await Hive.openBox(_settingsBoxName);
    }
    await _settingsBox.clear();

    final categoryBox = await _getCategoriesBox();
    await categoryBox.clear();

    debugPrint('🗑️ Hive boxes cleared');
  }

  Future<void> close() async => Hive.close();
}
