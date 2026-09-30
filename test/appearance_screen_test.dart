import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/core/widgets/section_header.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/features/settings/widgets/palette_swatch.dart';
import 'package:walt/features/settings/widgets/theme_preview_card.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';

class FakePathProvider extends PathProviderPlatform {
  static final String _docs = Directory.systemTemp
      .createTempSync('walt_test_docs')
      .path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docs;

  @override
  Future<String?> getTemporaryPath() async => _docs;
}

class _StubSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      SettingsState(isLoaded: true, isOnboardingCompleted: true);
}

/// Builds the screen the way `main.dart` does: a real [ThemeController]
/// hydrated from a known state, and a [MaterialApp] whose theme is *derived from
/// that notifier on every build*.
///
/// The second half is the part that matters. A `MaterialApp(theme: buildTheme(
/// initial, ...))` would look right and prove nothing — the theme is computed
/// once at construction and never revisited, so a screen that failed to rebuild
/// on a palette change would still paint emerald. `MyApp` watches the provider;
/// so does this.
Widget _host(ThemeSettings initial) {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(_StubSettings.new),
      themeControllerProvider.overrideWith(
        () => ThemeController()..bootstrap = initial,
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        theme: buildTheme(ref.watch(themeControllerProvider), Brightness.light),
        home: const AppearanceScreen(),
      ),
    ),
  );
}

/// A generous but finite settle.
///
/// The default is ten minutes, so a screen that never settles — an animation
/// that never ends, a scroll that fights its own content — takes a quarter of an
/// hour to report and blames the whole file. A short bound fails the test that
/// actually hung instead.
Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 16),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 5),
);

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AppearanceScreen)));

ThemeSettings _state(WidgetTester tester) =>
    _containerOf(tester).read(themeControllerProvider);

/// The swatch tile for [palette], or the "Custom" tile.
Finder _swatch(WaltPalette palette) => find.descendant(
  of: find.byType(PaletteSwatch),
  matching: find.text(palette.label),
);

Finder _customSwatch() => find.descendant(
  of: find.byType(PaletteSwatch),
  matching: find.text('Custom'),
);

/// The AMOLED switch specifically — the screen has two switches, and the other
/// one is about blur, not colour.
///
/// The title and the switch are *siblings* inside one [GroupedListTile], so the
/// switch has to be found by walking out to the tile and back down. Matching on
/// `widgetWithText` would look for a Text *inside* the Switch and find nothing.
Finder _amoledSwitch() => find.descendant(
  of: find.ancestor(
    of: find.text('Pure black'),
    matching: find.byType(GroupedListTile),
  ),
  matching: find.byType(Switch),
);

/// The blur switch, found the same way.
Finder _blurSwitch() => find.descendant(
  of: find.ancestor(
    of: find.text('Reduce transparency'),
    matching: find.byType(GroupedListTile),
  ),
  matching: find.byType(Switch),
);

/// The Colour section header, which is the one carrying the active palette
/// name. There are three headers on the screen, so it is matched by title.
Finder _colourHeader() => find.widgetWithText(SectionHeader, 'Colour');

Finder _modeButton(ThemeMode mode) {
  final label = switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
  return find.descendant(
    of: find.byType(SegmentedButton<ThemeMode>),
    matching: find.text(label),
  );
}

Future<void> _tapPalette(WidgetTester tester, WaltPalette palette) async {
  await tester.ensureVisible(_swatch(palette));
  await _settle(tester);
  await tester.tap(_swatch(palette));
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
  });

  setUp(() async {
    await HiveService.instance.settingsBox.clear();
  });

  group('Appearance screen', () {
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
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      for (final palette in WaltPalette.values) {
        expect(
          _swatch(palette),
          findsOneWidget,
          reason: '${palette.name} is missing from the grid',
        );
      }
      expect(_customSwatch(), findsOneWidget);

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
        _host(const ThemeSettings(palette: WaltPalette.ocean)),
      );
      await _settle(tester);

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
        _host(
          const ThemeSettings(
            palette: WaltPalette.ocean,
            customSeed: Color(0xFF8E5CD9),
          ),
        ),
      );
      await _settle(tester);

      final selected = tester
          .widgetList<PaletteSwatch>(find.byType(PaletteSwatch))
          .where((swatch) => swatch.selected)
          .toList();

      expect(selected, hasLength(1));
      expect(selected.single.label, 'Custom');
      expect(selected.single.custom, isTrue);
    });

    testWidgets('tapping a swatch updates state and repaints the theme', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

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

      await _tapPalette(tester, WaltPalette.violet);

      expect(_state(tester).palette, WaltPalette.violet);

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

    testWidgets('every palette is reachable and applies in one pass', (
      tester,
    ) async {
      // One pumped screen, nine taps. Re-pumping per palette would also pass
      // while the grid only worked on a fresh build, which is not what this is
      // meant to check.
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      for (final palette in WaltPalette.values) {
        await _tapPalette(tester, palette);

        expect(
          _state(tester).palette,
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
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      await _tapPalette(tester, WaltPalette.teal);

      expect(
        HiveService.instance.settingsBox.get(ThemeSettings.keyPalette),
        'teal',
      );
    });

    testWidgets('the mode button switches mode and persists it', (
      tester,
    ) async {
      for (final mode in ThemeMode.values) {
        await tester.pumpWidget(_host(ThemeSettings.defaults));
        await _settle(tester);

        await tester.tap(_modeButton(mode));
        await _settle(tester);

        expect(_state(tester).mode, mode);
        expect(
          HiveService.instance.settingsBox.get(ThemeSettings.keyMode),
          mode.name,
        );
      }
    });

    testWidgets('the AMOLED switch toggles the flag and persists it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      await tester.ensureVisible(_amoledSwitch());
      await _settle(tester);
      await tester.tap(_amoledSwitch());
      await _settle(tester);

      expect(_state(tester).amoled, isTrue);
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
      await tester.pumpWidget(_host(const ThemeSettings(amoled: true)));
      await _settle(tester);

      await tester.ensureVisible(_amoledSwitch());
      await _settle(tester);

      expect(tester.widget<Switch>(_amoledSwitch()).value, isTrue);
    });

    testWidgets('reduce transparency lives here and does not touch the theme', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      expect(tester.widget<Switch>(_blurSwitch()).value, isFalse);

      // The tile itself is not tappable — only the switch is — so the switch is
      // what has to be hit.
      await tester.ensureVisible(_blurSwitch());
      await _settle(tester);
      await tester.tap(_blurSwitch());
      await _settle(tester);

      expect(
        _containerOf(tester).read(settingsProvider).reduceTransparency,
        isTrue,
      );
      // Blur and colour are separate settings; turning one on must not quietly
      // change the other.
      expect(_state(tester), ThemeSettings.defaults);
    });

    testWidgets('the preview card follows a palette change live', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      final preview = find.byType(ThemePreviewCard);
      expect(preview, findsOneWidget);

      await _tapPalette(tester, WaltPalette.rose);

      expect(preview, findsOneWidget);
      // The card is themed from `settings`, not from the ambient theme, so it
      // must be showing the palette that was *just* tapped.
      final card = tester.widget<ThemePreviewCard>(preview);
      expect(card.settings.palette, WaltPalette.rose);
    });

    testWidgets('the colour section names the active palette', (tester) async {
      await tester.pumpWidget(
        _host(const ThemeSettings(palette: WaltPalette.amber)),
      );
      await _settle(tester);

      // Matched through the header, not by bare text: "Amber" also appears as
      // a swatch label in the grid, so `find.text` alone is ambiguous.
      expect(
        find.descendant(of: _colourHeader(), matching: find.text('Amber')),
        findsOneWidget,
      );
    });

    testWidgets('a choice survives a cold start', (tester) async {
      await tester.pumpWidget(_host(ThemeSettings.defaults));
      await _settle(tester);

      await _tapPalette(tester, WaltPalette.ocean);
      await tester.tap(_modeButton(ThemeMode.dark));
      await _settle(tester);

      // A brand new container with no bootstrap, reading only from Hive.
      final restarted = ProviderContainer(
        overrides: [settingsProvider.overrideWith(_StubSettings.new)],
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
        overrides: [settingsProvider.overrideWith(_StubSettings.new)],
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
      await _settle(tester);

      expect(find.byType(AppearanceScreen), findsOneWidget);
      expect(_state(tester).palette, WaltPalette.emerald);
    });
  });
}
