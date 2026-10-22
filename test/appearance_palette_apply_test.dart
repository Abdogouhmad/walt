import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
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

  group('Appearance screen — applying a palette', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(400, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.reset);
    });

    testWidgets('tapping a swatch updates state and repaints the theme', (
      tester,
    ) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      final before = Theme.of(
        tester.element(find.byType(AppearanceScreen)),
      ).colorScheme.primary;
      expect(
        before,
        buildTheme(
          ThemeSettings.defaults,
          Brightness.light,
        ).colorScheme.primary,
      );

      await tapPalette(tester, WaltPalette.violet);

      expect(appearanceState(tester).palette, WaltPalette.violet);

      final after = Theme.of(
        tester.element(find.byType(AppearanceScreen)),
      ).colorScheme.primary;
      expect(
        after,
        buildTheme(
          const ThemeSettings(palette: WaltPalette.violet),
          Brightness.light,
        ).colorScheme.primary,
        reason: 'the screen must rebuild against the new palette, not the old',
      );
      expect(after, isNot(before));
    });

    testWidgets('the preview card follows a palette change live', (
      tester,
    ) async {
      await tester.pumpWidget(appearanceHost(ThemeSettings.defaults));
      await settleAppearance(tester);

      final preview = find.byType(ThemePreviewCard);
      expect(preview, findsOneWidget);

      await tapPalette(tester, WaltPalette.rose);

      expect(preview, findsOneWidget);
      // The card is themed from `settings`, not from the ambient theme, so it
      // must be showing the palette that was *just* tapped.
      final card = tester.widget<ThemePreviewCard>(preview);
      expect(card.settings.palette, WaltPalette.rose);
    });

    testWidgets('the colour section names the active palette', (tester) async {
      await tester.pumpWidget(
        appearanceHost(const ThemeSettings(palette: WaltPalette.amber)),
      );
      await settleAppearance(tester);

      // Matched through the header, not by bare text: "Amber" also appears as
      // a swatch label in the grid, so `find.text` alone is ambiguous.
      expect(
        find.descendant(of: colourHeader(), matching: find.text('Amber')),
        findsOneWidget,
      );
    });
  });
}
