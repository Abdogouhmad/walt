import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    // Removed the incorrect '()' after the generic type argument
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showBudgetAlert({
    required int id,
    required String categoryName,
    required double limit,
    required double spent,
    String currency = '',
    bool isOver = true,
  }) async {
    final String cur = currency.isEmpty ? '' : ' $currency';
    final String title = isOver ? 'Budget Exceeded!' : 'Budget Warning';
    final String body = isOver
        ? 'You have spent ${spent.toStringAsFixed(2)}$cur on $categoryName, which is over your ${limit.toStringAsFixed(2)}$cur limit.'
        : 'You have spent ${spent.toStringAsFixed(2)}$cur on $categoryName, reaching ${limit > 0 ? ((spent / limit) * 100).toInt() : 100}% of your ${limit.toStringAsFixed(2)}$cur limit.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Notifications for budget limits and warnings',
          importance: Importance.high,
          priority: Priority.high,
        );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> showUpdateNotification({
    required String latestVersion,
    required String changelogSummary,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'app_updates',
          'App Updates',
          channelDescription: 'Notifications for new app updates and releases',
          importance: Importance.high,
          priority: Priority.high,
        );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id: 1,
      body: 'New Update Available! 🚀',
      title: 'Version v$latestVersion is available. Tap to view changes.',
      notificationDetails: platformDetails,
      payload: 'ota_update',
    );
  }
}
