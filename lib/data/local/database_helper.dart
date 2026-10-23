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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Runs `PRAGMA table_info` and returns the column names of [table].
  ///
  /// Migrations ask this before every `ALTER TABLE ... ADD COLUMN` so they are
  /// idempotent. A user who installed a broken build, or an earlier upgrade
  /// that only got partway, still ends up with a complete schema instead of an
  /// exception and an unusable app.
  Future<Set<String>> _columnsOf(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return {
      for (final row in rows)
        if (row['name'] case final String name) name,
    };
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await _columnsOf(db, table);
    if (columns.contains(column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _createBudgetSnapshots(Database db) async {
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

    await _createBudgetSnapshots(db);
    await _createIndexes(db);
    debugPrint('✅ Database tables created successfully.');
  }

  /// Indexes for the columns every query filters or sorts on.
  ///
  /// Without these, SQLite scans the whole `transactions` table and sorts into
  /// a temporary B-tree on every list/report load — the Activity screen, the
  /// home recap and the budget progress all order by `date DESC`. Created with
  /// `IF NOT EXISTS` so it is safe to run from both `onCreate` and `onUpgrade`.
  ///
  /// Upgrade paths must call this **after** all columns exist: the budget index
  /// below references `transactions.budget_id`, which only arrives in v7.
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
      await _addColumnIfMissing(
        db,
        table: 'accounts',
        column: 'profile_pic',
        definition: 'TEXT',
      );
    }

    // v4 introduced multi-category budgets and per-period snapshots.
    if (oldVersion < 4) {
      await _addBudgetColumns(db);
      await _createBudgetSnapshots(db);
    }

    // A database upgraded by an early v4 build could be missing some of the
    // budget columns; re-checking is cheap and keeps the upgrade idempotent.
    if (oldVersion < 5) {
      await _addBudgetColumns(db);
    }

    if (oldVersion < 6) {
      await _createBudgetSnapshots(db);

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
    }

    if (oldVersion < 8) {
      // v7 added this column; v8 is an idempotent repair for databases that a
      // broken v7 build left without it. Existing rows stay NULL, which keeps
      // the old category-based attribution.
      await _addColumnIfMissing(
        db,
        table: 'transactions',
        column: 'budget_id',
        definition: 'INTEGER',
      );
    }

    // Run every index last, once all referenced columns are guaranteed to
    // exist. Creating `idx_tx_budget` in the v6 step used to fail an upgrade
    // from v3 with "no such column: budget_id" and the app could not open its
    // database at all.
    await _createIndexes(db);
  }

  Future<void> _addBudgetColumns(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'budgets',
      column: 'name',
      definition: 'TEXT DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'budgets',
      column: 'category_ids',
      definition: "TEXT DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'budgets',
      column: 'is_pinned',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'budgets',
      column: 'pin_order',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'budgets',
      column: 'accent_color',
      definition: 'TEXT',
    );
  }
}
