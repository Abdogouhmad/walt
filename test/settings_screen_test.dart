import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:walt/core/theme/app_theme.dart';
import 'package:walt/core/widgets/grouped_list.dart';
import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_info_dialog.dart';
import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/providers/settings_provider.dart';

/// Satisfies `HiveService.init` without touching the real filesystem layout.
/// The `path_provider` top-level helpers forward to the `*Path` methods on the
/// platform interface, so those are what have to be overridden — adding
/// `getApplicationDocumentsDirectory` here would compile and do nothing.
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

Widget _host() => ProviderScope(
  overrides: [settingsProvider.overrideWith(_StubSettings.new)],
  child: MaterialApp(
    theme: AppTheme.lightTheme(),
    home: const SettingsScreen(),
  ),
);

void main() {
  // The About row renders the app version, so Appinfo has to be primed before
  // the first build or every test here fails on setup instead of assertions.
  // It reads through package_info_plus, which has no test implementation, so
  // the channel is answered directly.
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async => switch (call.method) {
            'getAll' => <String, Object?>{
              'appName': 'Walt',
              'packageName': 'dev.walt.app',
              'version': '0.7.0',
              'buildNumber': '70',
            },
            _ => null,
          },
        );
    await Appinfo.init();

    // Settings reads through Hive for the avatar, the update check and the
    // currency fallback. `HiveService.init` needs a documents directory, so
    // point the plugin at a throwaway temp dir instead of a real one.
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
    await Hive.deleteBoxFromDisk('settings_json_box');
  });

  group('Settings screen', () {
    testWidgets('has an opaque background of its own', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // Settings is pushed on the root navigator with a transparent Scaffold,
      // so there is nothing of its own behind it. `Colors.transparent` lets the
      // platform window show through, which is what rendered as a black screen.
      expect(scaffold.backgroundColor, isNot(Colors.transparent));
      expect((scaffold.backgroundColor!.a * 255).round(), 255);
    });

    testWidgets('spaces its grouped list tiles apart', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Measure the tiles, not their labels: the labels sit inside the tile's
      // own padding, so text-to-text distance hides the real inter-tile gap.
      final tiles = tester
          .widgetList<GroupedListTile>(find.byType(GroupedListTile))
          .toList();
      expect(tiles.length, greaterThanOrEqualTo(2));

      final first = tester.getRect(find.byWidget(tiles[0]));
      final second = tester.getRect(find.byWidget(tiles[1]));
      // Inside a group the tiles are separate cards, so a 2dp hairline gap
      // read as one undifferentiated block. They need to look like rows.
      expect(
        second.top - first.bottom,
        greaterThanOrEqualTo(8),
        reason: 'Settings rows are packed against each other',
      );

      final appearance = tester.getRect(find.text('Appearance'));

      // And the group as a whole needs air above it.
      final header = tester.getRect(find.text('Preferences'));
      expect(appearance.top - header.bottom, greaterThanOrEqualTo(8));
    });

    testWidgets('names the current appearance in the row subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // The Appearance row must answer "is my colour still set?" without the
      // user having to open it, so the subtitle carries the palette and mode.
      expect(find.textContaining('Emerald'), findsOneWidget);
      expect(find.textContaining('System'), findsOneWidget);
    });

    testWidgets('never offers a switch for update notifications', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.text('Update notifications'), findsNothing);
    });

    testWidgets('tapping About opens a dialog instead of a new screen', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // The About row sits below the fold in the test viewport.
      await tester.ensureVisible(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      // Match the concrete type: `find.byType` is an exact runtime-type match,
      // so looking for the AlertDialog base class would miss the subclass.
      expect(find.byType(AboutInfoDialog), findsOneWidget);
      // Still on Settings: no route was pushed.
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
