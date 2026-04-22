import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:dynamic_color/dynamic_color.dart';

// sqflite FFI support for Desktop
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Your local files
import 'data/local/database_helper.dart';
import 'data/local/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';
// Providers
//import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeApp() async {
  try {
    // Initialize dotenv
    await dotenv.load(fileName: ".env");

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
    // 1. Watch the settings provider
    //final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Walt',
          debugShowCheckedModeBanner: false,

          // 2. Use the values from your Hive/Riverpod state
        themeMode: ThemeMode.system,

          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),

          // 3. The Router will now automatically re-evaluate
          // when settings.isOnboardingCompleted changes
          routerConfig: appRouter,
        );
      },
    );
  }
}
