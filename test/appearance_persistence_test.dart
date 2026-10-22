import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
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

  group('Appearance screen — persistence', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(400, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.reset);
    });

    testWidgets('every palette is reachable and applies in one pass', (
      tester,
    ) async {
      // One pumped screen, nine taps. Re-pumping per palette would also pass
      // while the grid only worked on a fresh build, which is not what this is
      // meant to check.
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      for (final palette in WaltPalette.values) {
        await tapPalette(tester, palette);

        expect(
          appearanceState(tester).palette,
          palette,
          reason: '${palette.name} did not apply when tapped',
        );
        expect(
          HiveService.instance.settingsBox.get(ThemeSettings.keyPalette),
          palette.name,
        );
      }
    });

    testWidgets('a palette choice is written to storage', (tester) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      await tapPalette(tester, WaltPalette.teal);

      expect(
        HiveService.instance.settingsBox.get(ThemeSettings.keyPalette),
        'teal',
      );
    });

    testWidgets('the mode button switches mode and persists it', (
      tester,
    ) async {
      for (final mode in ThemeMode.values) {
        await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
        await settleAppearance(tester);

        await tester.tap(modeButton(mode));
        await settleAppearance(tester);

        expect(appearanceState(tester).mode, mode);
        expect(
          HiveService.instance.settingsBox.get(ThemeSettings.keyMode),
          mode.name,
        );
      }
    });

    testWidgets('the AMOLED switch toggles the flag and persists it', (
      tester,
    ) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      await tester.ensureVisible(amoledSwitch());
      await settleAppearance(tester);
      await tester.tap(amoledSwitch());
      await settleAppearance(tester);

      expect(appearanceState(tester).amoled, isTrue);
      expect(
        HiveService.instance.settingsBox.get(ThemeSettings.keyAmoled),
        isTrue,
      );
      // The stored form has to be a bool, not a string — a mis-typed write here
      // would silently read back as `false` and look like the toggle
      // "forgetting" itself.
      expect(
        HiveService.instance.settingsBox.get(ThemeSettings.keyAmoled),
        isA<bool>(),
      );
    });

    testWidgets('the AMOLED switch reflects the stored value', (tester) async {
      await tester.pumpWidget(
        appearanceHost(const ThemeSettings(amoled: true)),
      );
      await settleAppearance(tester);

      await tester.ensureVisible(amoledSwitch());
      await settleAppearance(tester);

      expect(tester.widget<Switch>(amoledSwitch()).value, isTrue);
    });
  });
}
