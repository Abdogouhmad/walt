import 'package:walt/data/models/walt_transaction.dart';
import 'database_helper.dart';

class TransactionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ====================== CREATE ======================
  Future<int> insertTransaction(WaltTransaction transaction) async {
    final db = await _dbHelper.database;

    return await db.insert('transactions', {
      'amount': transaction.amount,
      'type': transaction.type,
      'category_id': transaction.categoryId,
      'account_id': transaction.accountId,
      'note': transaction.note,
      'merchant': transaction.merchant,
      'date': transaction.date.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ====================== READ ======================

  // Get all transactions (newest first)
  Future<List<WaltTransaction>> getAllTransactions() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  // Get transactions for a specific month (useful for reports)
  Future<List<WaltTransaction>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;

    // Half-open range: `>= first of month` and `< first of next month`. The
    // previous `<= lastDay - 1 day` form stopped at midnight on the final day,
    // so every transaction *during* the last day of the month was dropped from
    // reports and exports.
    final startOfMonth = DateTime(year, month, 1).millisecondsSinceEpoch;
    final startOfNextMonth = DateTime(
      year,
      month + 1,
      1,
    ).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfMonth, startOfNextMonth],
      orderBy: 'date DESC',
    );

    return maps.map(_mapToTransaction).toList();
  }

  // ====================== UPDATE ======================
  Future<int> updateTransaction(WaltTransaction transaction) async {
    final db = await _dbHelper.database;

    return await db.update(
      'transactions',
      {
        'amount': transaction.amount,
        'type': transaction.type,
        'category_id': transaction.categoryId,
        'account_id': transaction.accountId,
        'note': transaction.note,
        'merchant': transaction.merchant,
        'date': transaction.date.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ====================== DELETE ======================
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllAmounts(double rate) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('UPDATE transactions SET amount = amount * ?', [rate]);
  }

  // Convert Map from database → Transaction model
  WaltTransaction _mapToTransaction(Map<String, dynamic> map) {
    return WaltTransaction(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['category_id'],
      accountId: map['account_id'],
      note: map['note'],
      merchant: map['merchant'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
