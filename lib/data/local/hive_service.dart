import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
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
    debugPrint('✅ Hive initialized successfully');
  }

  // ====================== CATEGORIES ======================

  /// Helper to open the categories box
  Future<Box<WaltCategory>> _getCategoriesBox() async {
    return await Hive.openBox<WaltCategory>(_categoriesBoxName);
  }

  Future<List<WaltCategory>> getAllCategories() async {
    final box = await _getCategoriesBox();
    return box.values.toList();
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

  Future<void> setDarkMode(bool isDark) async =>
      saveSetting('isDarkMode', isDark);

  bool isDarkMode() {
    final val = getSetting('isDarkMode', defaultValue: false);
    return val is bool ? val : false;
  }

  Future<void> setCurrency(String currency) async =>
      saveSetting('currency', currency);

  String getCurrency() {
    final val = getSetting('currency', defaultValue: 'MAD');
    return val is String ? val : 'MAD';
  }

  Future<void> setOnboardingCompleted(bool completed) async =>
      saveSetting('onboardingCompleted', completed);

  bool isOnboardingCompleted() {
    final val = getSetting('onboardingCompleted', defaultValue: false);
    return val is bool ? val : false;
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
