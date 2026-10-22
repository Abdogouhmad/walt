import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Channel ids. Kept as constants so tests and the Settings copy agree.
const String kBudgetChannelId = 'budget_alerts';
const String kUpdateChannelId = 'app_updates';

/// The plugin's initialization settings, shared by every platform Walt ships.
const InitializationSettings notificationInitializationSettings =
    InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
    );

/// The platform details of a budget-alert notification.
const NotificationDetails budgetAlertNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    kBudgetChannelId,
    'Budget Alerts',
    channelDescription: 'Notifications for budget limits and warnings',
    importance: Importance.high,
    priority: Priority.high,
  ),
  linux: LinuxNotificationDetails(),
);

/// The platform details of the "new version available" notification.
const NotificationDetails updateNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    kUpdateChannelId,
    'App Updates',
    channelDescription: 'Notifications for new app updates and releases',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  linux: LinuxNotificationDetails(),
);
