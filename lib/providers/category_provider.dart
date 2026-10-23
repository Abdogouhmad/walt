import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/local/budget_dao.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/local/transaction_dao.dart';
import 'package:walt/data/models/walt_category.dart';

final categoryProvider =
    NotifierProvider<CategoryNotifier, AsyncValue<List<WaltCategory>>>(() {
      return CategoryNotifier();
    });

/// A category name that collides with an existing one (case-insensitive).
class CategoryNameTakenException implements Exception {
  const CategoryNameTakenException(this.name);

  final String name;

  @override
  String toString() => 'A category named "$name" already exists';
}

/// Deletion was refused because transactions or budgets still reference the
/// category. Blocking is deliberate: silently reassigning a user's spending to
/// another category would rewrite historical reports without their consent.
class CategoryInUseException implements Exception {
  const CategoryInUseException({
    required this.transactionCount,
    required this.budgetCount,
  });

  final int transactionCount;
  final int budgetCount;

  @override
  String toString() =>
      'Category is in use ($transactionCount transactions, $budgetCount budgets)';
}

/// A default, seeded category. Deleting one would remove the category every
/// new install starts with and make old screenshots/tutorials lie, so the
/// policy refuses and the UI explains instead of hiding the option.
class CategoryDefaultException implements Exception {
  const CategoryDefaultException(this.name);

  final String name;

  @override
  String toString() => '"$name" is a default category and cannot be deleted';
}

/// Empty or otherwise invalid input. Kept separate from name collisions so the
/// editor can point at the right field.
class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CategoryNotifier extends Notifier<AsyncValue<List<WaltCategory>>> {
  final _hive = HiveService.instance;

  /// Default categories seeded on first launch, with bundled artwork.
  static const _defaults = [
    (
      id: 1,
      name: 'Food',
      icon: 'restaurant',
      color: '#C25B3F',
      type: 'expense',
      image: 'assets/categories/food.png',
    ),
    (
      id: 2,
      name: 'Salary',
      icon: 'account_balance_wallet',
      color: '#3F7A5E',
      type: 'income',
      image: 'assets/categories/salary.png',
    ),
    (
      id: 3,
      name: 'Coffee',
      icon: 'coffee',
      color: '#8A6534',
      type: 'expense',
      image: 'assets/categories/coffee.png',
    ),
    (
      id: 4,
      name: 'Transport',
      icon: 'directions_car',
      color: '#4268A8',
      type: 'expense',
      image: 'assets/categories/transport.png',
    ),
    (
      id: 5,
      name: 'Shopping',
      icon: 'shopping_bag',
      color: '#7B5CA6',
      type: 'expense',
      image: 'assets/categories/shopping.png',
    ),
    (
      id: 6,
      name: 'Health',
      icon: 'favorite',
      color: '#A6425B',
      type: 'expense',
      image: 'assets/categories/health.png',
    ),
    (
      id: 7,
      name: 'Utilities',
      icon: 'bolt',
      color: '#A8752E',
      type: 'expense',
      image: 'assets/categories/utilities.png',
    ),
    (
      id: 8,
      name: 'Freelance',
      icon: 'laptop',
      color: '#2F7C78',
      type: 'income',
      image: 'assets/categories/freelance.png',
    ),
    (
      id: 9,
      name: 'Other',
      icon: 'category',
      color: '#5E6B78',
      type: 'expense',
      image: 'assets/categories/other.png',
    ),
  ];

  @override
  AsyncValue<List<WaltCategory>> build() {
    _loadCategories();
    return const AsyncValue.loading();
  }

  Future<void> _loadCategories() async {
    state = await AsyncValue.guard(() async {
      var categories = await _hive.getAllCategories();
      if (categories.isEmpty) {
        debugPrint('⚠️ No categories found — seeding defaults.');
        await _seedDefaults();
        return await _hive.getAllCategories();
      }
      final migrated = _backfillDefaultImages(categories);
      if (migrated) {
        categories = await _hive.getAllCategories();
        await _hive.saveCategories(categories);
      }
      return categories;
    });
  }

  /// Old Hive rows predate category artwork. Defaults can be matched by their
  /// icon key, so an update adds the bundled image without touching custom
  /// categories (which keep their icon fallback until the user edits them).
  bool _backfillDefaultImages(List<WaltCategory> categories) {
    var changed = false;
    final byName = {for (final d in _defaults) d.name.toLowerCase(): d};
    for (final category in categories) {
      if (category.hasImage) continue;
      final def = byName[category.name.toLowerCase()];
      if (def == null || def.icon != category.icon) continue;
      final index = categories.indexOf(category);
      categories[index] = category.copyWith(
        imageSource: CategoryImageSource.asset,
        imagePath: def.image,
      );
      changed = true;
    }
    return changed;
  }

  Future<void> _seedDefaults() async {
    final defaultCategories = _defaults
        .map(
          (d) => WaltCategory(
            id: d.id,
            name: d.name,
            icon: d.icon,
            color: d.color,
            type: d.type,
            isDefault: true,
            imageSource: CategoryImageSource.asset,
            imagePath: d.image,
          ),
        )
        .toList();

    await _hive.saveCategories(defaultCategories);

    debugPrint('✅ Successfully seeded ${defaultCategories.length} categories');
  }

  List<WaltCategory> get _current => state.value ?? const [];

  int _nextId() {
    final ids = _current.map((c) => c.id);
    return ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  void _assertNameAvailable(String name, {int? exceptId}) {
    final needle = name.trim().toLowerCase();
    final clash = _current.any(
      (c) => c.id != exceptId && c.name.trim().toLowerCase() == needle,
    );
    if (clash) throw CategoryNameTakenException(name.trim());
  }

  Future<WaltCategory> createCategory({
    required String name,
    required String type,
    required String color,
    required String icon,
    required CategoryImageSource imageSource,
    required String? imagePath,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const CategoryValidationException('Enter a category name');
    }
    _assertNameAvailable(trimmed);

    final category = WaltCategory(
      id: _nextId(),
      name: trimmed,
      icon: icon,
      color: color,
      type: type,
      isDefault: false,
      imageSource: imageSource,
      imagePath: imagePath,
    );
    final next = [..._current, category];
    await _hive.saveCategories(next);
    state = AsyncData(next);
    return category;
  }

  Future<void> updateCategory(WaltCategory category) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty) {
      throw const CategoryValidationException('Enter a category name');
    }
    _assertNameAvailable(trimmed, exceptId: category.id);
    final cleaned = category.copyWith(name: trimmed);
    final next = [
      for (final existing in _current)
        if (existing.id == cleaned.id) cleaned else existing,
    ];
    await _hive.saveCategories(next);
    state = AsyncData(next);
  }

  /// Deletes a custom category that nothing references.
  ///
  /// Default categories are never deletable, and a category with transactions
  /// or budgets throws [CategoryInUseException]. The UI turns that into an
  /// explanation rather than doing a destructive cascade the user did not ask
  /// for.
  Future<void> deleteCategory(WaltCategory category) async {
    if (category.isDefault) {
      throw CategoryDefaultException(category.name);
    }

    final transactions = await TransactionDao().countForCategory(category.id);
    final budgets = await BudgetDao().countForCategory(category.id);
    if (transactions > 0 || budgets > 0) {
      throw CategoryInUseException(
        transactionCount: transactions,
        budgetCount: budgets,
      );
    }

    final next = _current.where((c) => c.id != category.id).toList();
    await _hive.saveCategories(next);
    state = AsyncData(next);
  }

  Future<void> refresh() async => _loadCategories();
}
