import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:walt/data/local/database_helper.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/services/notification_router.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens everything the app needs before its first frame.
///
/// SQLite, the app info and Hive touch different resources, so they are opened
/// together: the first frame then waits on the slowest of the three rather than
/// on their sum.
Future<void> initializeApp() async {
  // SQLite Initialization for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Future.wait([
    Appinfo.init(),
    DatabaseHelper.instance.database,
    HiveService.init(),
  ]);

  // Notifications are non-critical: never block startup on them. Permission is
  // *not* requested here — it is asked in context, when the user creates their
  // first budget or turns an alert toggle on, so the OS prompt has context.
  try {
    final notifications = NotificationService();
    await notifications.init();
    // Must happen after init(), which is what populates `launchDestination`
    // for a notification that cold-started the app.
    wireNotificationRouting(notifications);
  } catch (e) {
    debugPrint('Notifications unavailable: $e');
  }
}

/// The stored appearance choices, read *before* the first frame.
///
/// A `Notifier` would rebuild it synchronously anyway, but doing it here means
/// the decision is already made when the widget tree is built, so the app can
/// never paint a frame in the wrong palette on the way to the right one.
ThemeSettings readThemeSettings() {
  try {
    return ThemeSettings.fromMap(HiveService.instance.readThemeSettings());
  } catch (e) {
    debugPrint('Could not read theme settings, using defaults: $e');
    return ThemeSettings.defaults;
  }
}
