import 'package:flutter/foundation.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/providers/budget_provider.dart';

/// Decides which budget alerts still need to fire and posts exactly those.
///
/// "Once per threshold per period" is persisted in the Hive settings box under
/// a key shaped `<budgetId>|<period>:<yyy-mm-dd>|<threshold>`, so a threshold
/// never repeats within a period but *does* fire again in the next one — this
/// is what makes period rollover observable to the user.
class BudgetAlertService {
  BudgetAlertService({HiveService? hive, NotificationService? notifications})
    : _hive = hive ?? HiveService.instance,
      _notifications = notifications ?? NotificationService();

  static const String storagePrefix = 'budget_alert_fired:';

  final HiveService _hive;
  final NotificationService _notifications;

  static String storageKey({
    required int budgetId,
    required String periodKey,
    required BudgetAlert alert,
  }) => '$storagePrefix$budgetId|$periodKey|${alert.name}';

  /// Every threshold [calculation] has reached, in ascending severity.
  ///
  /// Not just the most severe one: a budget that jumps from 40% to 120% has
  /// crossed *both* thresholds, and reporting only "exceeded" silently skipped
  /// the "approaching limit" warning the user is entitled to. Returns an empty
  /// list when nothing is crossed.
  static List<BudgetAlert> reachedAlerts(BudgetCalculation calculation) {
    return [
      if (calculation.isNearLimit) BudgetAlert.approaching,
      if (calculation.isExceeded) BudgetAlert.exceeded,
    ];
  }

  /// Alerts that should fire for [progress], given what has already fired.
  ///
  /// Pure with respect to [alreadyFired] — exposed for testing.
  static List<(BudgetProgress, BudgetAlert)> pendingAlerts(
    List<BudgetProgress> progress,
    Set<String> alreadyFired,
  ) {
    final out = <(BudgetProgress, BudgetAlert)>[];
    for (final p in progress) {
      for (final alert in reachedAlerts(p.calculation)) {
        final key = storageKey(
          budgetId: p.budget.id,
          periodKey: p.calculation.window.key,
          alert: alert,
        );
        if (alreadyFired.contains(key)) continue;
        out.add((p, alert));
      }
    }
    return out;
  }

  /// Evaluates [progress] and posts a notification for each threshold crossed
  /// for the first time in the current period.
  ///
  /// Safe to call from app start, after a transaction write, or after an
  /// import — it is idempotent within a period.
  Future<int> evaluate({
    required List<BudgetProgress> progress,
    String currency = '',
    bool notify = true,
  }) async {
    if (progress.isEmpty) return 0;

    final fired = await _firedKeys();
    final pending = pendingAlerts(progress, fired);
    var sent = 0;

    for (final (p, alert) in pending) {
      final key = storageKey(
        budgetId: p.budget.id,
        periodKey: p.calculation.window.key,
        alert: alert,
      );
      // A dry run is used by the "show me what's crossed" UI affordance: it
      // reveals the pending alerts without consuming them.
      if (notify) {
        try {
          await _notifications.showBudgetAlert(
            id: p.budget.id,
            categoryName: p.category.name,
            limit: p.limit,
            spent: p.spentAmount,
            currency: currency,
            alert: alert,
          );
          sent++;
        } catch (e) {
          debugPrint('BudgetAlertService: failed to post alert $key — $e');
          continue;
        }
      }
      // Recorded even on a dry run, so a preview never double-notifies later.
      await _hive.saveSetting(key, true);
    }
    return sent;
  }

  /// Test/debug helper: forgets every recorded alert.
  Future<void> reset() async {
    final box = _hive.settingsBox;
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(storagePrefix))
        .toList();
    await box.deleteAll(keys);
  }

  Future<Set<String>> _firedKeys() async {
    await _hive.ensureSettingsOpen();
    return _hive.settingsBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(storagePrefix))
        .toSet();
  }
}
