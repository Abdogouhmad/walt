import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/models/update_manifest.dart';

import 'support/update_fixtures.dart';

void main() {
  group('deriveVersionCode (spec §2)', () {
    test('formula matches common semver releases', () {
      expect(deriveVersionCode('0.4.1'), 401);
      expect(deriveVersionCode('0.5.1'), 501);
      expect(deriveVersionCode('1.2.43'), 10243);
      expect(deriveVersionCode('2.0.0'), 20000);
    });
  });

  group('UpdateManifest.isNewerThan', () {
    test('reports newer only when latestVersionCode exceeds installed', () {
      expect(makeManifest(code: 500).isNewerThan(401), isTrue);
      expect(makeManifest(code: 500).isNewerThan(500), isFalse);
      expect(makeManifest(code: 501).isNewerThan(500), isTrue);
    });
  });

  group('UpdateManifest.hasMinimumSupport (informational only)', () {
    // `minSupportedVersionCode` still parses, but it can no longer force
    // anything: spec §7.1 removed all forced-update gating.
    test('flags an install below the floor without forcing anything', () {
      final m = makeManifest(code: 500, minSupported: 400);
      expect(m.hasMinimumSupport(300), isTrue);
      expect(m.hasMinimumSupport(500), isFalse);
    });

    test('legacy mandatory flag is parsed but never acted on', () {
      final m = makeManifest(code: 500, mandatory: true);
      expect(m.mandatory, isTrue, reason: 'kept for old manifests on the wire');
    });
  });

  group('UpdateManifest.fromJson', () {
    test('parses the full manifest shape used by CI', () {
      final m = UpdateManifest.fromJson({
        'latestVersionName': '0.5.0',
        'latestVersionCode': 500,
        'minSupportedVersionCode': 401,
        'mandatory': false,
        'apkUrl': 'https://github.com/x/walt/releases/download/v0.5.0/a.apk',
        'sha256': 'a' * 64,
        'releaseNotes': '## Changed\n\n- Everything.',
        'publishedAt': '2026-09-19T10:00:00Z',
      });
      expect(m.latestVersionCode, 500);
      expect(m.minSupportedVersionCode, 401);
      expect(m.sha256, 'a' * 64);
      expect(m.publishedAt, isNotNull);
    });
  });
}
