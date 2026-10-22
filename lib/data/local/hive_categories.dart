import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/models/walt_category.dart';

/// The box that stores categories.
const String categoriesBoxName = 'categories_json_box';

/// Category storage.
///
/// Split out of [HiveService] so the store's core (the settings box, the
/// flags) stays small enough to read in one go.
extension HiveCategories on HiveService {
  Future<Box> _openCategoriesBox() => Hive.openBox(categoriesBoxName);

  Future<List<WaltCategory>> getAllCategories() async {
    final box = await _openCategoriesBox();
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
    final box = await _openCategoriesBox();
    await box.clear();

    final Map<int, WaltCategory> categoryMap = {
      for (var c in categories) c.id: c,
    };

    await box.putAll(categoryMap);
  }
}
