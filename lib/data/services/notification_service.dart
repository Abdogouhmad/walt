import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:walt/data/reports/budget_aggregation.dart';
import 'package:walt/data/services/notification_destination.dart';
import 'package:walt/data/services/notification_message.dart';
import 'package:walt/data/services/notification_permissions.dart';
import 'package:walt/data/services/notification_platform_details.dart';

export 'notification_destination.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Dedicated, collision-free id for the update notification. Budget alerts
  /// use `id: budget.id` (sequential from 1), and Android notifications with a
  /// matching id replace each other — so the update ping must live far away
  /// from the low budget ids or a budget alert could clobber it.
  static const int updateNotificationId = 0x7A17;

  /// Channel ids. Kept as constants so tests and the Settings copy agree.
  static const String budgetChannelId = kBudgetChannelId;
  static const String updateChannelId = kUpdateChannelId;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// The Android notification permission, wrapped in its own helper so the
  /// best-effort error handling around it does not crowd this class.
  late final NotificationPermissions permissions = NotificationPermissions(
    _notificationsPlugin,
  );

  /// Invoked when the user taps a notification while the app is in the
  /// foreground or background.
  void Function(NotificationDestination destination)? onDestinationSelected;

  /// Payload delivered by the notification that cold-started the app, if any.
  /// Read once at startup by [init].
  NotificationDestination? launchDestination;

  Future<void> init() async {
    await _notificationsPlugin.initialize(
      settings: notificationInitializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handle(response.payload);
      },
    );

    // A tap that cold-started the app never reaches the callback above, so the
    // launch details are the only way to recover that destination.
    //
    // Linux implements the plugin but not this call, and it throws
    // UnimplementedError rather than returning null. Rather than treat an
    // expected platform gap as a failure, only ask where it can answer.
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final launch = await _notificationsPlugin
            .getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _handle(launch?.notificationResponse?.payload);
        }
      } catch (e) {
        debugPrint('NotificationService: launch details unavailable — $e');
      }
    }
  }

  void _handle(String? payload) {
    final destination = parseNotificationPayload(payload);
    if (destination == null) return;
    onDestinationSelected?.call(destination);
  }

  /// Asks for POST_NOTIFICATIONS. Returns true when the user has granted it,
  /// false when denied — callers treat denial as "skip quietly", never as an
  /// error.
  Future<bool> requestPermissions() => permissions.request();

  /// Whether notifications are currently allowed, without prompting.
  Future<bool> hasPermission() => permissions.hasPermission();

  Future<void> showBudgetAlert({
    required int id,
    required String categoryName,
    required double limit,
    required double spent,
    String currency = '',
    BudgetAlert alert = BudgetAlert.exceeded,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: alert.title,
      body: budgetAlertBody(
        categoryName: categoryName,
        limit: limit,
        spent: spent,
        currency: currency,
        exceeded: alert == BudgetAlert.exceeded,
      ),
      notificationDetails: budgetAlertNotificationDetails,
      // Tapping opens the Budget screen.
      payload: '$kBudgetPayloadPrefix$id',
    );
  }

  /// Posts the "new version available" notification.
  ///
  /// Returns `true` once the notification has been handed to the OS, and
  /// `false` when it could not be delivered because notifications are not
  /// permitted. Callers use that to decide whether the release has really been
  /// announced: recording a version after a declined prompt would retire that
  /// update silently, so the user would never be told about it even after they
  /// later allow notifications.
  Future<bool> showUpdateNotification({
    required String latestVersion,
    required String changelogSummary,
  }) async {
    // Android 13+ discards notifications until POST_NOTIFICATIONS is granted,
    // and Walt only ever asked for it from the budget-alert flow — so an update
    // ping for a user who never touched budgets vanished without a trace. Ask
    // here instead: the one moment there is a concrete release to announce.
    if (!await permissions.ensureAllowed()) return false;

    await _notificationsPlugin.show(
      id: updateNotificationId,
      body: changelogSummary.trim().isEmpty
          ? 'New Update Available!'
          : changelogSummary.trim(),
      title: 'Walt $latestVersion is available',
      notificationDetails: updateNotificationDetails,
      payload: kUpdatePayload,
    );
    return true;
  }
}
