import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:dynamic_color/dynamic_color.dart';

// sqflite FFI support for Desktop
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:walt/features/settings/services/appinfo.dart';

import 'package:walt/data/services/notification_service.dart';

// Your local files
import 'data/local/database_helper.dart';
import 'data/local/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';
// Providers
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Portrait Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeApp() async {
  try {
    // Initialize dotenv
    await dotenv.load(fileName: ".env");
    await Appinfo.init();

    // SQLite Initialization for Desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      debugPrint('✅ sqflite FFI initialized for Desktop');
    }

    // Initialize SQLite
    await DatabaseHelper.instance.database;
    debugPrint('✅ SQLite database initialized');

    // Initialize Hive
    await HiveService.init();
    debugPrint('✅ Hive initialized');

    // Initialize Notifications
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
    debugPrint('✅ Notifications initialized');

    debugPrint('🎉 Walt Finance Tracker initialized successfully!');
  } catch (e, stack) {
    debugPrint('❌ Error during initialization: $e');
    debugPrint(stack.toString());
    rethrow;
  }
}

// Change MyApp from StatelessWidget to ConsumerWidget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Walt',
          debugShowCheckedModeBanner: false,

          themeMode: settings.themeMode,

          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),

          routerConfig: router,
        );
      },
    );
  }
}
