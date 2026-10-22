import 'package:walt/data/models/update_manifest.dart';

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

/// A manifest for the update tests.
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
