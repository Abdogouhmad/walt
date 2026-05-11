import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Accounts Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL,
        color TEXT,
        profile_pic TEXT,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER,
        note TEXT,
        merchant TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),

        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Budgets Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        alert_at REAL NOT NULL DEFAULT 0.8,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),

        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    debugPrint('✅ Database tables created successfully.');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE accounts ADD COLUMN profile_pic TEXT');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
