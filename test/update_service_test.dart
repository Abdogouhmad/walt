import 'package:flutter_test/flutter_test.dart';

import 'package:walt/data/services/notification_service.dart';
import 'package:walt/data/services/update_service.dart';

import 'support/update_fixtures.dart';

void main() {
  group('UpdateService.check', () {
    const service = UpdateService();

    test('null manifest fails the check silently', () {
      expect(
        service.check(manifest: null, currentVersionCode: 401),
        UpdateCheckResult.checkFailed,
      );
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

    test(
      'a legacy mandatory flag only yields a normal, declineable update',
      () {
        expect(
          service.check(
            manifest: makeManifest(code: 500, mandatory: true),
            currentVersionCode: 401,
          ),
          UpdateCheckResult.updateAvailable,
        );
      },
    );

    test('an install below minSupported is still only updateAvailable', () {
      expect(
        service.check(
          manifest: makeManifest(code: 500, minSupported: 400),
          currentVersionCode: 300,
        ),
        UpdateCheckResult.updateAvailable,
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
      const updateId = NotificationService.updateNotificationId;
      expect(updateId, isNot(equals(1)));
      // Budget ids are tiny; the update id must stay far above any plausible
      // budget count so Android never replaces one notification with the other.
      expect(updateId, greaterThan(1 << 10));
    });
  });
}
