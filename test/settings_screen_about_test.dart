import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/settings_screen.dart';
import 'package:walt/features/settings/widgets/about_info_dialog.dart';

import 'support/fake_path_provider.dart';
import 'support/settings_harness.dart';

void main() {
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

    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
    await Hive.deleteBoxFromDisk('settings_json_box');
  });

  group('Settings screen — About', () {
    testWidgets('tapping About opens a dialog instead of a new screen', (
      tester,
    ) async {
      await tester.pumpWidget(settingsHost());
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
