import 'package:walt/data/models/walt_account.dart';
import 'database_helper.dart';

class AccountDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ====================== CREATE ======================
  Future<int> insertAccount(WaltAccount account) async {
    final db = await _dbHelper.database;

    final Map<String, dynamic> map = {
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await db.insert('accounts', map);
  }

  // ====================== READ ======================

  // Get all accounts
  Future<List<WaltAccount>> getAllAccounts() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return maps.map((map) => _mapToAccount(map)).toList();
  }

  // Get account by ID
  Future<WaltAccount?> getAccountById(int id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToAccount(maps.first);
  }

  // Helper method to convert a map to an Account object
  WaltAccount _mapToAccount(Map<String, dynamic> map) {
    return WaltAccount(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'],
      currency: map['currency'],
      color: map['color'],
      isDefault: map['is_default'] == 1,
    );
  }
}