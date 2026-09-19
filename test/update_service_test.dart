import 'package:flutter_test/flutter_test.dart';
import 'package:walt/data/models/update_manifest.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/data/services/update_service.dart';

/// Mirrors the deterministic `versionCode` formula in
/// `android/app/build.gradle.kts` (spec §2): `major*10000 + minor*100 + patch`.
int deriveVersionCode(String versionName) {
  final parts = versionName.split('.').map(int.tryParse).toList();
  int num(int? v) => v ?? 0;
  return num(parts.getOrNull(0)) * 10000 +
      num(parts.getOrNull(1)) * 100 +
      num(parts.getOrNull(2));
}

extension<T> on List<T> {
  T? getOrNull(int index) => index >= 0 && index < length ? this[index] : null;
}

UpdateManifest makeManifest({
  int code = 500,
  String name = '0.5.0',
  int? minSupported,
  bool mandatory = false,
  String apkUrl = 'https://example.com/walt-v0.5.0-universal.apk',
  String? sha256,
}) {
  return UpdateManifest(
    latestVersionCode: code,
    latestVersionName: name,
    minSupportedVersionCode: minSupported,
    mandatory: mandatory,
    apkUrl: apkUrl,
    sha256: sha256,
  );
}

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

  group('UpdateManifest.isMandatoryFor', () {
    test('explicit mandatory flag forces an update', () {
      final m = makeManifest(code: 500, mandatory: true);
      expect(m.isMandatoryFor(401), isTrue);
    });

    test('below the minSupportedVersionCode floor forces an update', () {
      final m = makeManifest(code: 500, minSupported: 400);
      expect(m.isMandatoryFor(300), isTrue);
      expect(m.isMandatoryFor(400), isFalse);
    });

    test('an up-to-date install is never forced', () {
      final m = makeManifest(code: 500, minSupported: 999);
      expect(m.isMandatoryFor(500), isFalse);
      expect(m.isMandatoryFor(600), isFalse);
    });

    test('non-mandatory, within-floor update is declineable', () {
      expect(makeManifest(code: 500).isMandatoryFor(401), isFalse);
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

  group('UpdateService.check', () {
    const service = UpdateService();

    test('null manifest fails the check silently', () {
      expect(service.check(manifest: null, currentVersionCode: 401),
          UpdateCheckResult.checkFailed);
    });

    test('up to date', () {
      expect(
        service.check(
          manifest: makeManifest(code: 401, name: '0.4.1'),
          currentVersionCode: 401,
        ),
        UpdateCheckResult.upToDate,
      );
    });

    test('optional update available', () {
      expect(
        service.check(
          manifest: makeManifest(code: 500),
          currentVersionCode: 401,
        ),
        UpdateCheckResult.updateAvailable,
      );
    });

    test('mandatory update when flagged or out of support', () {
      expect(
        service.check(
          manifest: makeManifest(code: 500, mandatory: true),
          currentVersionCode: 401,
        ),
        UpdateCheckResult.updateMandatory,
      );
      expect(
        service.check(
          manifest: makeManifest(code: 500, minSupported: 400),
          currentVersionCode: 300,
        ),
        UpdateCheckResult.updateMandatory,
      );
    });

    test('a manifest without an APK url is a failed check', () {
      expect(
        service.check(
          manifest: makeManifest(code: 500, apkUrl: ''),
          currentVersionCode: 401,
        ),
        UpdateCheckResult.checkFailed,
      );
    });
  });

  group('NotificationService update id', () {
    test('never collides with budget alert ids (sequential from 1)', () {
      final updateId = NotificationService.updateNotificationId;
      expect(updateId, isNot(equals(1)));
      // Budget ids are tiny; the update id must stay far above any plausible
      // budget count so Android never replaces one notification with the other.
      expect(updateId, greaterThan(1 << 10));
    });
  });
}