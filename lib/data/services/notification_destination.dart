/// Where a notification tap should take the user.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// A tap on a budget alert: open the budget with this id.
class BudgetAlertDestination extends NotificationDestination {
  const BudgetAlertDestination(this.budgetId);
  final int budgetId;
}

/// A tap on the "new version available" notification: open the update screen.
class UpdateDestination extends NotificationDestination {
  const UpdateDestination();
}

/// Payload string carried by a budget alert. Kept as a string on the platform
/// side, so parsing lives here next to the routing.
const String kBudgetPayloadPrefix = 'budget:';
const String kUpdatePayload = 'app_update';

/// Translates a notification payload into a [NotificationDestination].
/// Returns null for anything unrecognised so a stale notification can never
/// navigate somewhere unexpected.
NotificationDestination? parseNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  if (payload == kUpdatePayload) return const UpdateDestination();
  if (payload.startsWith(kBudgetPayloadPrefix)) {
    final id = int.tryParse(payload.substring(kBudgetPayloadPrefix.length));
    if (id == null) return null;
    return BudgetAlertDestination(id);
  }
  return null;
}
