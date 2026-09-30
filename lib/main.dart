import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:walt/data/services/notification_router.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/features/settings/widgets/soft_update_bootstrap.dart';

// sqflite FFI support for Desktop
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:walt/features/settings/services/appinfo.dart';

// Your local files
import 'data/local/database_helper.dart';
import 'data/local/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_settings.dart';
import 'app_router.dart';
// Providers
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Portrait Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge: content draws behind the status/navigation bars and the
  // system bars stay transparent. Every screen insets itself with SafeArea or
  // MediaQuery padding (see `WaltChrome`).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await _initializeApp();

  // Read the stored appearance *before* the first frame.
  //
  // A `Notifier` would rebuild it synchronously anyway, but doing it here means
  // the decision is already made when the widget tree is built, so the app can
  // never paint a frame in the wrong palette on the way to the right one.
  final theme = _readThemeSettings();

  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWith(
          () => ThemeController()..bootstrap = theme,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

ThemeSettings _readThemeSettings() {
  try {
    return ThemeSettings.fromMap(HiveService.instance.readThemeSettings());
  } catch (e) {
    debugPrint('Could not read theme settings, using defaults: $e');
    return ThemeSettings.defaults;
  }
}

Future<void> _initializeApp() async {
  // SQLite Initialization for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Appinfo.init();
  await DatabaseHelper.instance.database;

  await HiveService.init();

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

// Change MyApp from StatelessWidget to ConsumerWidget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Walt',
      debugShowCheckedModeBanner: false,

      themeMode: settings.mode,

      theme: buildTheme(settings, Brightness.light),
      darkTheme: buildTheme(settings, Brightness.dark),

      // A palette swap is a whole-app recolour. Cross-fading it reads as
      // deliberate; snapping to it reads as a glitch.
      themeAnimationDuration: kThemeAnimationDuration,
      themeAnimationCurve: waltThemeAnimationCurve,

      routerConfig: router,
      // Non-blocking background update check. Never takes over the app.
      builder: (context, child) => _SystemBars(
        child: SoftUpdateBootstrap(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Keeps the system bars' icon brightness in step with the effective theme.
///
/// The bars themselves stay transparent — the app draws edge to edge — so the
/// only thing that has to track the palette is whether the icons should be light
/// or dark. Driven from the resolved `ColorScheme` inside the app rather than
/// from the raw `ThemeMode`, so "system in dark mode" is handled by the same
/// code path as an explicit dark selection.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(Theme.of(context).colorScheme),
      child: child,
    );
  }
}
