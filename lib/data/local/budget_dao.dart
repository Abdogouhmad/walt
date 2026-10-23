import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/models/walt_budget.dart';

class BudgetDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ====================== CREATE ======================
  Future<int> insertBudget(WaltBudget budget) async {
    final db = await _dbHelper.database;

    final Map<String, dynamic> map = {
      // Preserve an explicit id so "Undo" from a delete restores the same row
      // (and anything that still refers to it keeps referring to the same
      // budget). New budgets pass 0 and let SQLite assign the id.
      if (budget.id > 0) 'id': budget.id,
      'amount': budget.amount,
      'category_id': budget.effectiveCategoryIds.first,
      'category_ids': _encodeCategoryIds(budget.effectiveCategoryIds),
      'period': budget.period,
      'alert_at': budget.alertAt,
      'name': budget.name.trim(),
      'is_pinned': budget.isPinned ? 1 : 0,
      'pin_order': budget.pinOrder,
      'accent_color': budget.accentColor,
      'created_at': (budget.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };

    return await db.insert('budgets', map);
  }

  // ====================== READ ======================

  // Get all budgets, pinned first in the user's chosen order.
  Future<List<WaltBudget>> getAllBudgets() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      orderBy: 'is_pinned DESC, pin_order ASC, id ASC',
    );

    return maps.map(_mapToBudget).toList();
  }

  Future<WaltBudget?> getBudget(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToBudget(maps.first);
  }

  // ====================== UPDATE ======================
  Future<int> updateBudget(WaltBudget budget) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> map = {
      'amount': budget.amount,
      'category_id': budget.effectiveCategoryIds.first,
      'category_ids': _encodeCategoryIds(budget.effectiveCategoryIds),
      'period': budget.period,
      'alert_at': budget.alertAt,
      'name': budget.name.trim(),
      'is_pinned': budget.isPinned ? 1 : 0,
      'pin_order': budget.pinOrder,
      'accent_color': budget.accentColor,
    };
    return await db.update(
      'budgets',
      map,
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  /// Pin-only write, used by the card's pin button and Home's prompt. Writing
  /// the whole budget from a tap would race an open edit sheet.
  Future<void> setPinned({
    required int id,
    required bool isPinned,
    required int pinOrder,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'budgets',
      {'is_pinned': isPinned ? 1 : 0, 'pin_order': pinOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Persists a reorder in one transaction. [orderedIds] is the complete
  /// pinned list in its new order; anything not pinned is left alone.
  Future<void> reorderPinned(List<int> orderedIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'budgets',
          {'pin_order': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  // ====================== DELETE ======================
  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'budget_period_snapshots',
      where: 'budget_id = ?',
      whereArgs: [id],
    );
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllAmounts(double rate) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('UPDATE budgets SET amount = amount * ?', [rate]);
  }

  /// How many budgets consume [categoryId]. Used before deleting a custom
  /// category, so a budget can never be left pointing at a missing category.
  Future<int> countForCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'budgets',
      columns: ['category_id', 'category_ids'],
    );
    var count = 0;
    for (final row in rows) {
      final ids = _decodeCategoryIds(
        row['category_ids'] as String?,
        fallback: row['category_id'] as int?,
      );
      if (ids.contains(categoryId)) count++;
    }
    return count;
  }

  // Helper method to convert a map to a Budget object
  WaltBudget _mapToBudget(Map<String, dynamic> map) {
    final categoryIds = _decodeCategoryIds(
      map['category_ids'] as String?,
      fallback: map['category_id'] as int?,
    );
    return WaltBudget(
      id: map['id'] as int,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int? ?? categoryIds.first,
      categoryIds: categoryIds,
      period: map['period'] as String? ?? 'Monthly',
      alertAt: (map['alert_at'] as num? ?? 0.8).toDouble(),
      name: (map['name'] as String?) ?? '',
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      pinOrder: map['pin_order'] as int? ?? 0,
      accentColor: map['accent_color'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  static String _encodeCategoryIds(List<int> ids) => ids.toSet().join(',');

  static List<int> _decodeCategoryIds(String? raw, {int? fallback}) {
    final parsed = <int>[];
    if (raw != null && raw.trim().isNotEmpty) {
      for (final part in raw.split(',')) {
        final id = int.tryParse(part.trim());
        if (id != null) parsed.add(id);
      }
    }
    if (parsed.isEmpty && fallback != null) parsed.add(fallback);
    return parsed.toSet().toList(growable: false);
  }
}
