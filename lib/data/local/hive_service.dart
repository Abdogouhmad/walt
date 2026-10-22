import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import 'package:walt/data/local/hive_theme_settings.dart';
import 'package:walt/hive_registrar.g.dart';

export 'hive_categories.dart';
export 'hive_theme_settings.dart';

class HiveService {
  // Use a specific name for the box storing JSON maps
  static const String settingsBoxName = 'settings_box';

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

    instance._settingsBox = await Hive.openBox(settingsBoxName);
    // Appearance keys changed shape in this release; cleaned up before the
    // first frame so the theme is read from a settled store.
    await instance.migrateThemeSettings();
    debugPrint('✅ Hive initialized successfully');
  }

  // ====================== SETTINGS ======================

  Future<void> _ensureSettingsBoxOpen() async {
    if (!_settingsBox.isOpen) {
      _settingsBox = await Hive.openBox(settingsBoxName);
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
}
