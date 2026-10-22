/// Riverpod state for the OTA update flow (ported from Brewline, spec §3):
/// `idle / checking / available / downloading(progress) / readyToInstall / error`.
///
/// The UI only talks to [updateProvider]; internally it talks to
/// [UpdateService] which fetches `update_manifest.json`, compares the Android
/// `versionCode`, then drives `ota_update` (which verifies the manifest's
/// SHA-256 before handing off to the system package installer).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';

import 'package:walt/data/models/changelog.dart';
import 'package:walt/data/models/update_manifest.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/data/services/update_service.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/providers/settings_provider.dart';
import 'update_check_provider.dart';
import 'update_events.dart';
import 'update_state.dart';

export 'update_check_provider.dart';
export 'update_events.dart';
export 'update_state.dart';

/// The single OTA update notifier driving the whole flow.
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  /// Triggers an update check. Silent on failure (never blocks startup).
  Future<void> checkForUpdates() async {
    state = state.copyWith(status: UpdateStatus.checking, clearError: true);

    final manifest = await ref.read(updateServiceProvider).fetchManifest();

    final outcome = ref
        .read(updateServiceProvider)
        .check(manifest: manifest, currentVersionCode: Appinfo.buildNumber);

    if (outcome == UpdateCheckResult.checkFailed) {
      // A failed check is still a check: persist the timestamp + "failed"
      // result so the user can tell "check failed" from "never checked".
      await ref
          .read(lastUpdateCheckProvider.notifier)
          .markChecked(UpdateCheckResult.checkFailed);
      state = state.copyWith(
        status: UpdateStatus.idle,
        checkResult: UpdateCheckResult.checkFailed,
        clearManifest: true,
        clearProgress: true,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.available,
      manifest: manifest,
      checkResult: outcome,
      clearProgress: true,
      clearError: true,
    );

    await ref.read(lastUpdateCheckProvider.notifier).markChecked(outcome);
    await _notifyIfNew(manifest, outcome);
  }

  /// Shown once per release: fires the local notification the first time this
  /// device discovers [manifest]'s update. The in-app banner always shows the
  /// update; the notification is the passive nudge for when the user isn't
  /// looking at Settings.
  ///
  /// The version is only recorded as notified once the ping has actually been
  /// handed to the OS. Recording it after a declined notification prompt would
  /// silently retire the release and the user would never hear about it, even
  /// after they later allow notifications.
  Future<void> _notifyIfNew(
    UpdateManifest? manifest,
    UpdateCheckResult outcome,
  ) async {
    if (manifest == null) return;
    if (outcome != UpdateCheckResult.updateAvailable) return;
    if (!ref.read(settingsProvider).updateNotificationsEnabled) return;
    final hive = ref.read(hiveServiceProvider);
    if (hive.getSetting(kLastUpdateNotifiedKey, defaultValue: '') ==
        manifest.latestVersionName) {
      return;
    }

    try {
      final posted = await NotificationService().showUpdateNotification(
        latestVersion: manifest.latestVersionName,
        changelogSummary: firstChangelogLine(manifest.releaseNotes),
      );
      if (posted) {
        await hive.saveSetting(
          kLastUpdateNotifiedKey,
          manifest.latestVersionName,
        );
      }
    } catch (_) {
      // Notifications are best-effort — never fail the update flow on them.
    }
  }

  /// Downloads and installs the update. `ota_update` verifies the manifest's
  /// SHA-256 before anything is installed and hands off to Android's
  /// `PackageInstaller`, which takes over the screen mid-flow.
  Future<void> downloadAndInstall() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    if (manifest.apkUrl.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.noBuild,
      );
      return;
    }

    Stream<OtaEvent> stream;
    try {
      stream = ref
          .read(updateServiceProvider)
          .downloadAndInstall(manifest: manifest);
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.downloadFailed,
        errorDetail: e.toString(),
      );
      return;
    }

    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);

    await for (final event in stream) {
      state = applyOtaEvent(state, event);
    }
  }
}
