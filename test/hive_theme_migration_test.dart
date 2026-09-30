import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:walt/core/theme/theme_settings.dart';
import 'package:walt/core/theme/walt_palette.dart';
import 'package:walt/data/local/hive_service.dart';

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

  group('readThemeSettings', () {
    test('returns the defaults on a first launch', () {
      expect(
        ThemeSettings.fromMap(_hive.readThemeSettings()),
        ThemeSettings.defaults,
        reason: 'a first launch must land on emerald, not on a black screen',
      );
    });

    test('round-trips a full saved appearance', () async {
      await _hive.setThemePalette('terracotta');
      await _hive.setThemeMode('dark');
      await _hive.setThemeAmoled(true);
      await _hive.setThemeCustomSeed(0xFF7C4DFF);

      final restored = ThemeSettings.fromMap(_hive.readThemeSettings());

      expect(restored.palette, WaltPalette.terracotta);
      expect(restored.mode, ThemeMode.dark);
      expect(restored.amoled, isTrue);
      expect(restored.customSeed, const Color(0xFF7C4DFF));
    });

    test('an unwritten key is absent, not defaulted', () {
      // "not stored" has to stay distinguishable from "stored as the default",
      // otherwise a removed palette could never fall back.
      expect(
        _hive.readThemeSettings().containsKey(ThemeSettings.keyPalette),
        isTrue,
      );
      expect(_hive.readThemeSettings()[ThemeSettings.keyPalette], isNull);
    });
  });

  group('migrateThemeSettings', () {
    test('carries the old theme mode over to the new key', () async {
      await _hive.saveSetting('themeMode', 'dark');

      await _hive.migrateThemeSettings();

      expect(
        _hive.settingsBox.get('themeMode'),
        isNull,
        reason: 'old key must be gone',
      );
      expect(_hive.settingsBox.get(ThemeSettings.keyMode), 'dark');
      expect(
        ThemeSettings.fromMap(_hive.readThemeSettings()).mode,
        ThemeMode.dark,
      );
    });

    test('does not overwrite a mode the user has already chosen', () async {
      await _hive.saveSetting('themeMode', 'dark');
      await _hive.setThemeMode('light');

      await _hive.migrateThemeSettings();

      expect(_hive.settingsBox.get(ThemeSettings.keyMode), 'light');
    });

    test('drops every Material You key and falls back to emerald', () async {
      await _hive.saveSetting('dynamicColor', true);
      await _hive.saveSetting('useDynamicColor', true);
      await _hive.saveSetting('dynamic_color', true);

      await _hive.migrateThemeSettings();

      for (final key in ['dynamicColor', 'useDynamicColor', 'dynamic_color']) {
        expect(
          _hive.settingsBox.containsKey(key),
          isFalse,
          reason: '$key survived',
        );
      }
      // Dynamic colour had no palette behind it, so the replacement is the
      // launcher-matching default rather than an arbitrary system colour.
      expect(
        ThemeSettings.fromMap(_hive.readThemeSettings()).palette,
        WaltPalette.emerald,
      );
    });

    test('leaves an already-migrated appearance untouched', () async {
      await _hive.setThemePalette('violet');
      await _hive.setThemeMode('light');

      await _hive.migrateThemeSettings();

      expect(_hive.settingsBox.get(ThemeSettings.keyPalette), 'violet');
      expect(_hive.settingsBox.get(ThemeSettings.keyMode), 'light');
    });

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
