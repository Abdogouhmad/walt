import 'package:ota_update/ota_update.dart';

import 'update_state.dart';

/// Folds one OTA event into the update [state].
///
/// Kept as a pure function so the download flow reads as a stream of events
/// rather than a chain of assignments, and so each event's outcome can be
/// reasoned about on its own.
UpdateState applyOtaEvent(UpdateState state, OtaEvent event) {
  switch (event.status) {
    case OtaStatus.DOWNLOADING:
      final progress = double.tryParse(event.value ?? '') ?? 0;
      return state.copyWith(progress: (progress / 100).clamp(0, 1));
    case OtaStatus.INSTALLING:
      return state.copyWith(status: UpdateStatus.readyToInstall, progress: 1);
    case OtaStatus.INSTALLATION_DONE:
      return state.copyWith(
        status: UpdateStatus.idle,
        clearManifest: true,
        clearCheckResult: true,
        clearProgress: true,
      );
    case OtaStatus.ALREADY_RUNNING_ERROR:
      return state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.downloadFailed,
        errorDetail: 'An update is already in progress.',
        clearProgress: true,
      );
    case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
      return state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.install,
        errorDetail: 'Permission to install apps was denied.',
        clearProgress: true,
      );
    case OtaStatus.CHECKSUM_ERROR:
      return state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.integrity,
        errorDetail: event.value,
        clearProgress: true,
      );
    case OtaStatus.INSTALLATION_ERROR:
      return state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.install,
        errorDetail: event.value,
        clearProgress: true,
      );
    case OtaStatus.DOWNLOAD_ERROR:
    case OtaStatus.INTERNAL_ERROR:
      return state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.downloadFailed,
        errorDetail: event.value,
        clearProgress: true,
      );
    case OtaStatus.CANCELED:
      // A cancelled download leaves a partial bar behind; drop it so the
      // next attempt starts from a clean state.
      return state.copyWith(
        status: UpdateStatus.available,
        clearProgress: true,
      );
  }
}
