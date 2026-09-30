import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/services/budget_alert_service.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/providers/budget_provider.dart';
import 'package:walt/providers/settings_provider.dart';

/// Asks for POST_NOTIFICATIONS at the moment the user opts in, never at app
/// start.
///
/// A permission prompt on first launch is the least likely moment to be
/// granted and the easiest to dismiss reflexively. Tying the request to the
/// toggle — or to creating the first budget — gives the OS dialog context.
///
/// Returns false when the user has denied it; callers treat that as "stay
/// quiet", never as an error.
Future<bool> requestNotificationPermission() async {
  try {
    return await NotificationService().requestPermissions();
  } catch (e) {
    debugPrint('Notification permission request failed: $e');
    return false;
  }
}

/// Re-runs budget threshold detection immediately.
///
/// Called whenever something the alerts depend on changes — the alert toggle
/// being switched on, a budget being created, a transaction written — so the
/// decision is never deferred to the next unrelated change. Idempotent within
/// a period: thresholds that already fired stay recorded and are not repeated.
Future<int> evaluateBudgetAlertsNow(WidgetRef ref) async {
  if (!ref.read(settingsProvider).budgetAlertsEnabled) return 0;
  final progress = ref.read(budgetProgressProvider);
  if (progress.isEmpty) return 0;
  final currency = ref.read(settingsProvider).currency;
  return BudgetAlertService().evaluate(progress: progress, currency: currency);
}
