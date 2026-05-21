import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/models/walt_budget.dart';

class BudgetDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ====================== CREATE ======================
  Future<int> insertBudget(WaltBudget budget) async {
    final db = await _dbHelper.database;

    final Map<String, dynamic> map = {
      'amount': budget.amount,
      'category_id': budget.categoryId,
      'period': budget.period,
      'alert_at': budget.alertAt,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await db.insert('budgets', map);
  }

  // ====================== READ ======================

  // Get all budgets
  Future<List<WaltBudget>> getAllBudgets() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('budgets');

    return maps.map((map) => _mapToBudget(map)).toList();
  }

  // Get budget by ID
  Future<WaltBudget?> getBudgetById(int id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToBudget(maps.first);
  }

  // ====================== UPDATE ======================
  Future<int> updateBudget(WaltBudget budget) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> map = {
      'amount': budget.amount,
      'category_id': budget.categoryId,
      'period': budget.period,
      'alert_at': budget.alertAt,
    };
    return await db.update(
      'budgets',
      map,
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // ====================== DELETE ======================
  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllAmounts(double rate) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE budgets SET amount = amount * ?',
      [rate],
    );
  }

  // Helper method to convert a map to a Budget object
  WaltBudget _mapToBudget(Map<String, dynamic> map) {
    return WaltBudget(
      id: map['id'] as int,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      period: map['period'] as String? ?? 'Monthly',
      alertAt: (map['alert_at'] as num? ?? 0.8).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }
}
