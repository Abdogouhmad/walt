import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/models/walt_category.dart';

final categoryProvider =
    NotifierProvider<CategoryNotifier, AsyncValue<List<WaltCategory>>>(() {
      return CategoryNotifier();
    });

class CategoryNotifier extends Notifier<AsyncValue<List<WaltCategory>>> {
  final _hive = HiveService.instance;

  // Default categories seeded on first launch
  static const _defaults = [
    (
      id: 1,
      name: 'Food',
      icon: 'restaurant',
      color: '#FF6B6B',
      type: 'expense',
    ),
    (
      id: 2,
      name: 'Salary',
      icon: 'account_balance_wallet',
      color: '#6BCB77',
      type: 'income',
    ),
    (id: 3, name: 'Coffee', icon: 'coffee', color: '#FFD93D', type: 'expense'),
    (
      id: 4,
      name: 'Transport',
      icon: 'directions_car',
      color: '#4D96FF',
      type: 'expense',
    ),
    (
      id: 5,
      name: 'Shopping',
      icon: 'shopping_bag',
      color: '#C77DFF',
      type: 'expense',
    ),
    (
      id: 6,
      name: 'Health',
      icon: 'favorite',
      color: '#FF4D6D',
      type: 'expense',
    ),
    (id: 7, name: 'Utilities', icon: 'bolt', color: '#F4A261', type: 'expense'),
    (
      id: 8,
      name: 'Freelance',
      icon: 'laptop',
      color: '#2EC4B6',
      type: 'income',
    ),
    (id: 9, name: 'Other', icon: 'category', color: '#ADB5BD', type: 'expense'),
  ];

  @override
  AsyncValue<List<WaltCategory>> build() {
    _loadCategories();
    return const AsyncValue.loading();
  }

  Future<void> _loadCategories() async {
    state = const AsyncValue.loading();

    final categories = await _hive.getAllCategories();

    if (categories.isEmpty) {
      debugPrint('⚠️ No categories found — seeding defaults.');
      await _seedDefaults();
      final seeded = await _hive.getAllCategories();
      state = AsyncValue.data(seeded);
    } else {
      state = AsyncValue.data(categories);
    }
  }

  Future<void> _seedDefaults() async {
    // 1. Convert the list of tuples into a List of WaltCategory objects
    final defaultCategories = _defaults
        .map(
          (d) => WaltCategory(
            id: d.id,
            name: d.name,
            icon: d.icon,
            color: d.color,
            type: d.type,
            isDefault: true,
          ),
        )
        .toList();

    // 2. Save the entire list at once.
    // This calls box.clear() once, then adds all 9 categories.
    await _hive.saveCategories(defaultCategories);

    debugPrint('✅ Successfully seeded ${defaultCategories.length} categories');
  }

  Future<void> refresh() async => _loadCategories();
}
