import 'package:walt/data/models/walt_account.dart';
import 'database_helper.dart';

class AccountDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertAccount(WaltAccount account) async {
    final db = await _dbHelper.database;

    return await db.insert('accounts', {
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'currency': account.currency,
      'color': account.color,
      'profile_pic': account.profilePic,
      'is_default': account.isDefault ? 1 : 0,
    });
  }

  Future<List<WaltAccount>> getAllAccounts() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return maps.map(_mapToAccount).toList();
  }

  WaltAccount _mapToAccount(Map<String, dynamic> map) {
    return WaltAccount(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'],
      color: map['color'],
      profilePic: map['profile_pic'],
      isDefault: map['is_default'] == 1,
    );
  }

  Future<void> updateAllBalances(double rate, String newCurrency) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance * ?, currency = ?',
      [rate, newCurrency],
    );
  }
}
