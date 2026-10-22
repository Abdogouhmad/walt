import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The Android notification permission, wrapped.
///
/// Every call is best-effort: a permission prompt that throws, or a platform
/// that has no such permission at all, resolves to `false` rather than
/// taking the caller down. A notification is never worth failing an operation
/// over.
class NotificationPermissions {
  const NotificationPermissions(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Asks for POST_NOTIFICATIONS. Returns true when the user has granted it,
  /// false when denied — callers treat denial as "skip quietly", never as an
  /// error.
  Future<bool> request() async {
    try {
      final android = _plugin
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
      final android = _plugin
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

  /// Whether the OS will actually deliver a notification, requesting the
  /// Android runtime permission when it is still missing.
  ///
  /// Best-effort and idempotent: returns `true` straight away on platforms that
  /// have no notification permission (Linux) or when it is already granted, and
  /// otherwise the outcome of the prompt.
  Future<bool> ensureAllowed() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    if (await hasPermission()) return true;
    return request();
  }
}
