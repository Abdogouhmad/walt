import 'package:walt/providers/update_provider.dart';

/// The user-facing message for the update flow's current failure.
String otaErrorMessage(UpdateState state) {
  final detail = state.errorDetail;
  return switch (state.error) {
    UpdateErrorCode.noBuild => 'This release has no APK to install.',
    UpdateErrorCode.downloadFailed =>
      'Could not download the update.${detail != null ? ' $detail' : ''}',
    UpdateErrorCode.integrity =>
      'Checksum mismatch — the update was refused for your safety.',
    UpdateErrorCode.install =>
      'Android would not install the update.${detail != null ? ' $detail' : ''}',
    null => switch (state.checkResult) {
      UpdateCheckResult.checkFailed => 'Could not reach the update server.',
      _ => 'Something went wrong.',
    },
  };
}
