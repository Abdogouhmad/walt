import 'package:walt/data/models/update_manifest.dart';
import 'package:walt/data/services/update_service.dart';

export 'package:walt/data/services/update_service.dart' show UpdateCheckResult;

/// The stages of the OTA update flow (ported from Brewline, spec §3):
/// `idle / checking / available / downloading(progress) / readyToInstall / error`.
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  error,
}

/// Failure kinds surfaced while [UpdateStatus.error]. The provider stores a
/// code (never a user-facing string — the UI maps it to copy).
enum UpdateErrorCode {
  /// The manifest points at an empty/invalid APK URL.
  noBuild,

  /// The download itself failed (network / transport).
  downloadFailed,

  /// The downloaded APK failed SHA-256 verification against the manifest.
  integrity,

  /// The system package installer rejected the APK.
  install,
}

/// The update state surfaced to the UI.
class UpdateState {
  final UpdateStatus status;
  final UpdateManifest? manifest;
  final UpdateCheckResult? checkResult;
  final double? progress;
  final UpdateErrorCode? error;
  final String? errorDetail;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.manifest,
    this.checkResult,
    this.progress,
    this.error,
    this.errorDetail,
  });

  /// An update exists. Optional by construction — there is no mandatory state.
  bool get hasUpdate => checkResult == UpdateCheckResult.updateAvailable;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateManifest? manifest,
    UpdateCheckResult? checkResult,
    double? progress,
    UpdateErrorCode? error,
    String? errorDetail,
    bool clearError = false,
    bool clearProgress = false,
    bool clearManifest = false,
    bool clearCheckResult = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      manifest: clearManifest ? null : manifest ?? this.manifest,
      checkResult: clearCheckResult ? null : checkResult ?? this.checkResult,
      // `progress` is nullable, so a plain `progress: null` would fall through
      // to `this.progress` and silently keep a stale bar. Clearing needs its
      // own flag.
      progress: clearProgress ? null : progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
    );
  }
}
