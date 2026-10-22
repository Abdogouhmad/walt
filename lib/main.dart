import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/soft_update_bootstrap.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt/shared/system_bars.dart';
import 'package:walt_ui/walt_ui.dart';

import 'app_bootstrap.dart';
import 'app_router.dart';

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

  await initializeApp();

  final theme = readThemeSettings();

  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWith(
          () => ThemeController()..bootstrap = theme,
        ),
        // The design system owns the "reduce transparency" switch; the app
        // supplies the user's stored choice. Watching keeps the frosted
        // surfaces in step with the setting when it is toggled at runtime.
        reduceTransparencyProvider.overrideWith(
          (ref) =>
              ref.watch(settingsProvider.select((s) => s.reduceTransparency)),
        ),
        hapticsEnabledProvider.overrideWith(
          (ref) => ref.watch(settingsProvider.select((s) => s.hapticsEnabled)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Change MyApp from StatelessWidget to ConsumerWidget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(themeControllerProvider);

    final appSettings = ref.watch(settingsProvider);
    final animationsEnabled = appSettings.animationsEnabled;

    return MaterialApp.router(
      title: 'Walt',
      debugShowCheckedModeBanner: false,

      themeMode: settings.mode,

      theme: buildTheme(settings, Brightness.light),
      darkTheme: buildTheme(settings, Brightness.dark),

      // A palette swap is a whole-app recolour. Cross-fading it reads as
      // deliberate; snapping to it reads as a glitch.
      themeAnimationDuration: animationsEnabled
          ? kThemeAnimationDuration
          : Duration.zero,
      themeAnimationCurve: waltThemeAnimationCurve,

      routerConfig: router,
      // Non-blocking background update check. Never takes over the app.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final updatedMedia = animationsEnabled
            ? media
            : media.copyWith(disableAnimations: true);
        final content = SystemBars(
          child: SoftUpdateBootstrap(child: child ?? const SizedBox.shrink()),
        );
        return MediaQuery(data: updatedMedia, child: content);
      },
    );
  }
}
