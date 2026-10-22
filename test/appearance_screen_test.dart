import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/widgets/palette_swatch.dart';
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

  group('Appearance screen — palette grid', () {
    // A 400×900 logical surface so the whole screen — preview, palette grid and
    // both switches — is laid out without anything being cut off. The default
    // 800×600 test viewport leaves the lower rows of the grid off-screen, which
    // makes a tap land on nothing.
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(400, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.reset);
    });

    testWidgets('offers every palette, the custom tile and three modes', (
      tester,
    ) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      for (final palette in WaltPalette.values) {
        expect(
          paletteSwatch(palette),
          findsOneWidget,
          reason: '${palette.name} is missing from the grid',
        );
      }
      expect(customSwatch(), findsOneWidget);

      for (final label in ['System', 'Light', 'Dark']) {
        expect(
          find.descendant(
            of: find.byType(SegmentedButton<ThemeMode>),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: 'the $label mode is missing',
        );
      }
    });

    testWidgets('marks the current palette as selected', (tester) async {
      await tester.pumpWidget(
        appearanceHost(const ThemeSettings(palette: WaltPalette.ocean)),
      );
      await settleAppearance(tester);

      final selected = tester
          .widgetList<PaletteSwatch>(find.byType(PaletteSwatch))
          .where((swatch) => swatch.selected)
          .toList();

      expect(selected, hasLength(1));
      expect(selected.single.label, WaltPalette.ocean.label);
    });

    testWidgets('a custom seed is shown as selected instead of a palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        appearanceHost(
          const ThemeSettings(
            palette: WaltPalette.ocean,
            customSeed: Color(0xFF8E5CD9),
          ),
        ),
      );
      await settleAppearance(tester);

      final selected = tester
          .widgetList<PaletteSwatch>(find.byType(PaletteSwatch))
          .where((swatch) => swatch.selected)
          .toList();

      expect(selected, hasLength(1));
      expect(selected.single.label, 'Custom');
      expect(selected.single.custom, isTrue);
    });
  });
}
