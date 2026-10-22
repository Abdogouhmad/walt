import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/appearance_harness.dart';

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
  });

  setUp(() async {
    await HiveService.instance.settingsBox.clear();
  });

  group('Appearance screen — blur and restart', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(400, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.reset);
    });

    testWidgets('reduce transparency lives here and does not touch the theme', (
      tester,
    ) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      expect(tester.widget<Switch>(blurSwitch()).value, isFalse);

      // The tile itself is not tappable — only the switch is — so the switch is
      // what has to be hit.
      await tester.ensureVisible(blurSwitch());
      await settleAppearance(tester);
      await tester.tap(blurSwitch());
      await settleAppearance(tester);

      expect(
        appearanceContainer(tester).read(settingsProvider).reduceTransparency,
        isTrue,
      );
      // Blur and colour are separate settings; turning one on must not quietly
      // change the other.
      expect(appearanceState(tester), ThemeSettings.defaults);
    });

    testWidgets('a choice survives a cold start', (tester) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      await tapPalette(tester, WaltPalette.ocean);
      await tester.tap(modeButton(ThemeMode.dark));
      await settleAppearance(tester);

      // A brand new container with no bootstrap, reading only from Hive.
      final restarted = ProviderContainer(
        overrides: [settingsProvider.overrideWith(StubSettings.new)],
      );
      addTearDown(restarted.dispose);

      final restored = restarted.read(themeControllerProvider);
      expect(restored.palette, WaltPalette.ocean);
      expect(restored.mode, ThemeMode.dark);
    });

    testWidgets('a corrupt stored appearance still opens on emerald', (
      tester,
    ) async {
      // A palette that no longer exists must not be able to block the screen.
      await HiveService.instance.saveSetting(
        ThemeSettings.keyPalette,
        'ultraviolet',
      );

      final container = ProviderContainer(
        overrides: [settingsProvider.overrideWith(StubSettings.new)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(ThemeSettings.defaults, Brightness.light),
            home: const AppearanceScreen(),
          ),
        ),
      );
      await settleAppearance(tester);

      expect(find.byType(AppearanceScreen), findsOneWidget);
      expect(appearanceState(tester).palette, WaltPalette.emerald);
    });
  });
}
