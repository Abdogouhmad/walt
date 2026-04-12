import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:walt/data/models/walt_category.dart';

class HiveService {
  // Use a specific name for the box storing JSON maps
  static const String _categoriesBoxName = 'categories_json_box';
  static const String _settingsBoxName = 'settings_box';

  static final HiveService instance = HiveService._init();
  HiveService._init();

  /// Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    // Note: No need to register WaltCategoryAdapter anymore 
    // since we are storing as Maps/JSON.
    debugPrint('✅ Hive initialized successfully');
  }

  // ====================== CATEGORIES ======================

  /// Helper to open the categories box (stores as Map)
  Future<Box<dynamic>> _getCategoriesBox() async {
    return await Hive.openBox(_categoriesBoxName);
  }

  /// Save all categories
  Future<void> saveCategories(List<WaltCategory> categories) async {
    final box = await _getCategoriesBox();
    await box.clear();

    // Map the list to a Map for putAll (more efficient than a loop)
    final Map<String, dynamic> data = {
      for (var cat in categories) cat.id.toString(): cat.toJson()
    };
    
    await box.putAll(data);
    debugPrint('✅ ${categories.length} categories cached in Hive');
  }

  /// Get all cached categories
  Future<List<WaltCategory>> getAllCategories() async {
    final box = await _getCategoriesBox();
    
    try {
      return box.values.map((json) {
        // Ensure the data is treated as a Map<String, dynamic>
        return WaltCategory.fromJson(Map<String, dynamic>.from(json as Map));
      }).toList();
    } catch (e) {
      debugPrint('❌ Error parsing categories from Hive: $e');
      return [];
    }
  }

  // ====================== SETTINGS ======================
  
  Future<Box> get settingsBox async {
    return await Hive.openBox(_settingsBoxName);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final box = await settingsBox;
    await box.put(key, value);
  }

  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final box = await settingsBox;
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> setDarkMode(bool isDark) async =>
      saveSetting('isDarkMode', isDark);
  
  Future<bool> isDarkMode() async {
    final val = await getSetting('isDarkMode', defaultValue: false);
    return val as bool;
  }

  Future<void> setCurrency(String currency) async =>
      saveSetting('currency', currency);
  
  Future<String> getCurrency() async {
    final val = await getSetting('currency', defaultValue: 'MAD');
    return val as String;
  }

  Future<void> setOnboardingCompleted(bool completed) async =>
      saveSetting('onboardingCompleted', completed);
  
  Future<bool> isOnboardingCompleted() async {
    final val = await getSetting('onboardingCompleted', defaultValue: false);
    return val as bool;
  }

  // ====================== UTILITY ======================
  
  Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(_categoriesBoxName);
    await Hive.deleteBoxFromDisk(_settingsBoxName);
    debugPrint('🗑️ Hive boxes cleared');
  }

  Future<void> close() async => Hive.close();
}