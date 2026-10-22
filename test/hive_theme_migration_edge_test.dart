import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt_ui/walt_ui.dart';

class FakePathProvider extends PathProviderPlatform {
  static final String _docs = Directory.systemTemp
      .createTempSync('walt_test_docs')
      .path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docs;

  @override
  Future<String?> getTemporaryPath() async => _docs;
}

HiveService get _hive => HiveService.instance;

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
  });

  setUp(() async {
    await _hive.settingsBox.clear();
  });

  group('migrateThemeSettings — edge cases', () {
    test(
      'an unrecognised stored palette degrades instead of throwing',
      () async {
        await _hive.saveSetting(ThemeSettings.keyPalette, 'ultraviolet');

        await _hive.migrateThemeSettings();

        expect(
          ThemeSettings.fromMap(_hive.readThemeSettings()).palette,
          WaltPalette.emerald,
        );
      },
    );

    test(
      'a non-string legacy mode is discarded, not written through',
      () async {
        await _hive.saveSetting('themeMode', 3);

        await _hive.migrateThemeSettings();

        expect(_hive.settingsBox.containsKey(ThemeSettings.keyMode), isFalse);
      },
    );

    test('is safe to run on an empty box', () async {
      await expectLater(_hive.migrateThemeSettings(), completes);
    });

    test('is idempotent', () async {
      await _hive.saveSetting('themeMode', 'dark');
      await _hive.migrateThemeSettings();
      final first = _hive.readThemeSettings();

      await _hive.migrateThemeSettings();

      expect(_hive.readThemeSettings(), first);
    });
  });
}
