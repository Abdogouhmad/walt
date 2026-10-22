import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt_ui/walt_ui.dart';

import 'support/fake_path_provider.dart';

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    await HiveService.init();
  });

  setUp(() async {
    await HiveService.instance.settingsBox.clear();
  });

  group('readThemeSettings', () {
    test('returns the defaults on a first launch', () {
      expect(
        ThemeSettings.fromMap(HiveService.instance.readThemeSettings()),
        ThemeSettings.defaults,
        reason: 'a first launch must land on emerald, not on a black screen',
      );
    });

    test('round-trips a full saved appearance', () async {
      await HiveService.instance.setThemePalette('terracotta');
      await HiveService.instance.setThemeMode('dark');
      await HiveService.instance.setThemeAmoled(true);
      await HiveService.instance.setThemeCustomSeed(0xFF7C4DFF);

      final restored = ThemeSettings.fromMap(
        HiveService.instance.readThemeSettings(),
      );

      expect(restored.palette, WaltPalette.terracotta);
      expect(restored.mode, ThemeMode.dark);
      expect(restored.amoled, isTrue);
      expect(restored.customSeed, const Color(0xFF7C4DFF));
    });

    test('an unwritten key is absent, not defaulted', () {
      // "not stored" has to stay distinguishable from "stored as the default",
      // otherwise a removed palette could never fall back.
      expect(
        HiveService.instance.readThemeSettings().containsKey(
          ThemeSettings.keyPalette,
        ),
        isTrue,
      );
      expect(
        HiveService.instance.readThemeSettings()[ThemeSettings.keyPalette],
        isNull,
      );
    });
  });
}
