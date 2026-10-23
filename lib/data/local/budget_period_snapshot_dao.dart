import 'package:sqflite/sqflite.dart';

import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/models/budget_period.dart';
import 'package:walt/data/reports/budget_window.dart';

/// Stores the limit each budget had during a concrete period.
///
/// Only the *current* period is ever written. A row for a period that has
/// already ended is immutable, which is what keeps "September allowed 1,000"
/// true after the budget is edited in October.
class BudgetPeriodSnapshotDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> ensureCurrentSnapshot({
    required int budgetId,
    required BudgetWindow window,
    required double limit,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budget_period_snapshots',
      {
        'budget_id': budgetId,
        'start_ms': window.start.millisecondsSinceEpoch,
        'end_ms': window.endExclusive.millisecondsSinceEpoch,
        'limit_amount': limit,
      },
      // Ignore, not replace: the first snapshot of a period is the one that
      // wins, so a later edit updates progress but never rewrites history.
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Updates the *current* period's limit after an edit.
  ///
  /// Past periods are never touched: keeping their original snapshot is the
  /// whole point. The current one has to move, otherwise editing a budget would
  /// leave today's history disagreeing with the card until the next rollover.
  Future<void> replaceCurrentSnapshot({
    required int budgetId,
    required BudgetWindow window,
    required double limit,
  }) async {
    final db = await _dbHelper.database;
    final updated = await db.update(
      'budget_period_snapshots',
      {
        'limit_amount': limit,
        'end_ms': window.endExclusive.millisecondsSinceEpoch,
      },
      where: 'budget_id = ? AND start_ms = ?',
      whereArgs: [budgetId, window.start.millisecondsSinceEpoch],
    );
    if (updated == 0) {
      await ensureCurrentSnapshot(
        budgetId: budgetId,
        window: window,
        limit: limit,
      );
    }
  }

  Future<List<BudgetPeriodSnapshot>> getSnapshotsForBudget(int budgetId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budget_period_snapshots',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      orderBy: 'start_ms DESC',
    );
    return maps.map(_map).toList();
  }

  Future<BudgetPeriodSnapshot?> getSnapshot({
    required int budgetId,
    required DateTime start,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budget_period_snapshots',
      where: 'budget_id = ? AND start_ms = ?',
      whereArgs: [budgetId, start.millisecondsSinceEpoch],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _map(maps.first);
  }

  BudgetPeriodSnapshot _map(Map<String, dynamic> map) {
    return BudgetPeriodSnapshot(
      budgetId: map['budget_id'] as int,
      start: DateTime.fromMillisecondsSinceEpoch(map['start_ms'] as int),
      endExclusive: DateTime.fromMillisecondsSinceEpoch(map['end_ms'] as int),
      limit: (map['limit_amount'] as num).toDouble(),
    );
  }
}
