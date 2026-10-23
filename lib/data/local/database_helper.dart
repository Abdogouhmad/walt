import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 7,
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
        budget_id INTEGER,
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
        name TEXT DEFAULT '',
        category_ids TEXT DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        pin_order INTEGER NOT NULL DEFAULT 0,
        accent_color TEXT,

        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_period_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_id INTEGER NOT NULL,
        start_ms INTEGER NOT NULL,
        end_ms INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        UNIQUE(budget_id, start_ms)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_snapshot_budget '
      'ON budget_period_snapshots(budget_id, start_ms)',
    );
    await _createIndexes(db);
    debugPrint('✅ Database tables created successfully.');
  }

  /// Indexes for the columns every query filters or sorts on.
  ///
  /// Without these, SQLite scans the whole `transactions` table and sorts into
  /// a temporary B-tree on every list/report load — the Activity screen, the
  /// home recap and the budget progress all order by `date DESC`. Created with
  /// `IF NOT EXISTS` so it is safe to run from both `onCreate` and `onUpgrade`.
  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_category '
      'ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_account '
      'ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tx_budget ON transactions(budget_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_category '
      'ON budgets(category_id)',
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE accounts ADD COLUMN profile_pic TEXT');
    }
    if (oldVersion < 3) {
      await _createIndexes(db);
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN name TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE budgets ADD COLUMN category_ids TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE budgets ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE budgets ADD COLUMN pin_order INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN accent_color TEXT');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_period_snapshots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budget_id INTEGER NOT NULL,
          start_ms INTEGER NOT NULL,
          end_ms INTEGER NOT NULL,
          limit_amount REAL NOT NULL,
          UNIQUE(budget_id, start_ms)
        )
      ''');
    }
    if (oldVersion < 5) {
      // Ensure pinning exists for databases upgraded partway.
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN name TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE budgets ADD COLUMN category_ids TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE budgets ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE budgets ADD COLUMN pin_order INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN accent_color TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_period_snapshots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budget_id INTEGER NOT NULL,
          start_ms INTEGER NOT NULL,
          end_ms INTEGER NOT NULL,
          limit_amount REAL NOT NULL,
          UNIQUE(budget_id, start_ms)
        )
      ''');

      // Older rows only knew their primary category. Backfill the multi-category
      // column so both the DAO and the picker see a complete selection.
      await db.execute(
        'UPDATE budgets SET category_ids = CAST(category_id AS TEXT) '
        "WHERE category_ids IS NULL OR TRIM(category_ids) = ''",
      );

      // A migration must not leave Home's pinned section empty: the first
      // budget the user ever created is the least surprising thing to pin.
      await db.execute(
        'UPDATE budgets SET is_pinned = 1, pin_order = 0 '
        'WHERE id = (SELECT MIN(id) FROM budgets) '
        'AND NOT EXISTS (SELECT 1 FROM budgets WHERE is_pinned = 1)',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_budget_snapshot_budget '
        'ON budget_period_snapshots(budget_id, start_ms)',
      );
      await _createIndexes(db);
    }
    if (oldVersion < 7) {
      // Transactions can now be booked against one specific budget. Existing
      // rows stay NULL, which preserves the old category-based attribution.
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN budget_id INTEGER',
        );
      } catch (_) {}
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tx_budget ON transactions(budget_id)',
      );
    }
  }
}
