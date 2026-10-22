import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/services/budget_alert_service.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';

/// Evaluates budget thresholds after any transaction change and on app start.
///
/// A no-op when the user has turned budget alerts off — the whole point of the
/// setting is that nothing is posted in that case.
Future<void> evaluateShellBudgetAlerts(
  WidgetRef ref,
  BudgetAlertService alerts,
  List<BudgetProgress> progress,
) async {
  if (!ref.read(settingsProvider).budgetAlertsEnabled) return;
  final currency = ref.read(settingsProvider).currency;
  await alerts.evaluate(progress: progress, currency: currency);
}
