import 'package:walt/data/models/walt_category.dart';
import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ====================== CREATE ======================
  Future<int> insertCategory(WaltCategory category) async {
    final db = await _dbHelper.database;

    final Map<String, dynamic> map = {
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'type': category.type,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await db.insert('categories', map);
  }

  // ====================== READ ======================

  // Get all categories
  Future<List<WaltCategory>> getAllCategories() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('categories');

    return maps.map((map) => _mapToCategory(map)).toList().cast<WaltCategory>();
  }

  // Get category by ID
  Future<WaltCategory?> getCategoryById(int id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToCategory(maps.first);
  }

  // map to gategory
  WaltCategory _mapToCategory(Map<String, dynamic> map) {
    return WaltCategory(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
    );
  }
}
