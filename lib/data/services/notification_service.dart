import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:walt/core/utils/money.dart';
import 'package:walt/data/reports/budget_aggregation.dart';

/// Where a notification tap should take the user.
sealed class NotificationDestination {
  const NotificationDestination();
}

class BudgetAlertDestination extends NotificationDestination {
  const BudgetAlertDestination(this.budgetId);
  final int budgetId;
}

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
  static const String budgetChannelId = 'budget_alerts';
  static const String updateChannelId = 'app_updates';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Invoked when the user taps a notification while the app is in the
  /// foreground or background.
  void Function(NotificationDestination destination)? onDestinationSelected;

  /// Payload delivered by the notification that cold-started the app, if any.
  /// Read once at startup by [init].
  NotificationDestination? launchDestination;

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
  Future<bool> requestPermissions() async {
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('NotificationService: permission request failed — $e');
      return false;
    }
  }

  /// Whether notifications are currently allowed, without prompting.
  Future<bool> hasPermission() async {
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.areNotificationsEnabled();
      return granted ?? false;
    } catch (e) {
      debugPrint('NotificationService: permission query failed — $e');
      return false;
    }
  }

  Future<void> showBudgetAlert({
    required int id,
    required String categoryName,
    required double limit,
    required double spent,
    String currency = '',
    BudgetAlert alert = BudgetAlert.exceeded,
  }) async {
    final cur = currency.trim().isEmpty ? '' : ' $currency';
    final spentLabel = '${_trim(spent)}$cur';
    final limitLabel = '${_trim(limit)}$cur';

    final title = alert.title;
    final body = alert == BudgetAlert.exceeded
        ? '$categoryName: $spentLabel spent of $limitLabel.'
        : '$categoryName: $spentLabel of $limitLabel spent.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          budgetChannelId,
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
      // Tapping opens the Budget screen.
      payload: '$kBudgetPayloadPrefix$id',
    );
  }

  Future<void> showUpdateNotification({
    required String latestVersion,
    required String changelogSummary,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          updateChannelId,
          'App Updates',
          channelDescription: 'Notifications for new app updates and releases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id: updateNotificationId,
      body: changelogSummary.trim().isEmpty
          ? 'New Update Available!'
          : changelogSummary.trim(),
      title: 'Walt $latestVersion is available',
      notificationDetails: platformDetails,
      payload: kUpdatePayload,
    );
  }

  /// Trims trailing ".00" noise: `120.50` -> `120.5`, `200.00` -> `200`.
  /// Whole amounts read better without cents; fractional ones keep them, but
  /// both go through the shared formatter so a notification and the screen it
  /// opens never disagree about how a number is written.
  static String _trim(double value) {
    final fractionDigits = value == value.roundToDouble() ? 0 : 2;
    return MoneyFormat.digits(value, fractionDigits: fractionDigits);
  }
}
