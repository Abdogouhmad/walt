import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:walt/features/settings/widgets/appearance_screen.dart';
import 'package:walt/features/settings/widgets/palette_swatch.dart';
import 'package:walt/providers/settings_provider.dart';
import 'package:walt/providers/theme_provider.dart';
import 'package:walt_ui/walt_ui.dart';

export 'fake_path_provider.dart';

/// Settings that are already loaded, so the screen never waits on Hive.
class StubSettings extends SettingsNotifier {
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
Widget appearanceHost(ThemeSettings initial) {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(StubSettings.new),
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
Future<void> settleAppearance(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 16),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 5),
);

/// The provider container backing the pumped screen.
ProviderContainer appearanceContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AppearanceScreen)));

/// The screen's current theme settings.
ThemeSettings appearanceState(WidgetTester tester) =>
    appearanceContainer(tester).read(themeControllerProvider);

/// The swatch tile for [palette], or the "Custom" tile.
Finder paletteSwatch(WaltPalette palette) => find.descendant(
  of: find.byType(PaletteSwatch),
  matching: find.text(palette.label),
);

/// The "Custom" tile.
Finder customSwatch() => find.descendant(
  of: find.byType(PaletteSwatch),
  matching: find.text('Custom'),
);

/// The AMOLED switch specifically — the screen has two switches, and the other
/// one is about blur, not colour.
///
/// The title and the switch are *siblings* inside one [GroupedListTile], so the
/// switch has to be found by walking out to the tile and back down. Matching on
/// `widgetWithText` would look for a Text *inside* the Switch and find nothing.
Finder amoledSwitch() => find.descendant(
  of: find.ancestor(
    of: find.text('Pure black'),
    matching: find.byType(GroupedListTile),
  ),
  matching: find.byType(Switch),
);

/// The blur switch, found the same way.
Finder blurSwitch() => find.descendant(
  of: find.ancestor(
    of: find.text('Reduce transparency'),
    matching: find.byType(GroupedListTile),
  ),
  matching: find.byType(Switch),
);

/// The Colour section header, which is the one carrying the active palette
/// name. There are three headers on the screen, so it is matched by title.
Finder colourHeader() => find.widgetWithText(SectionHeader, 'Colour');

/// The button of the mode [SegmentedButton] that sets [mode].
Finder modeButton(ThemeMode mode) {
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

/// Taps the swatch for [palette], scrolling it into view first.
Future<void> tapPalette(WidgetTester tester, WaltPalette palette) async {
  await tester.ensureVisible(paletteSwatch(palette));
  await settleAppearance(tester);
  await tester.tap(paletteSwatch(palette));
  await settleAppearance(tester);
}
