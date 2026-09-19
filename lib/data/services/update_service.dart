/// OTA update service: fetches the `update_manifest.json` from this repo and
/// compares it against the installed version (spec §3).
///
/// The manifest is a raw GitHub file, so the updater needs nothing but a plain
/// HTTPS GET. A failed or offline check is always silent — it never blocks
/// startup and never surfaces as an error for a routine background check.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';

import 'package:walt/data/models/update_manifest.dart';

/// Compile-time constant so the manifest URL can't drift between the code and
/// the CI workflow that writes it (§4.5).
const String kGitHubRepo = 'Abdogouhmad/walt';

/// Raw URL of the committed `update_manifest.json` on the default branch.
const String kUpdateManifestUrl =
    'https://raw.githubusercontent.com/$kGitHubRepo/main/update_manifest.json';

/// Result of comparing the installed version against the latest manifest.
enum UpdateCheckResult {
  /// The app is already up to date.
  upToDate,

  /// An update is available but not mandatory.
  updateAvailable,

  /// An update is available and mandatory — the installed build is out of
  /// support and the app must be updated to keep working.
  updateMandatory,

  /// The check failed (offline, HTTP error, malformed manifest).
  checkFailed,
}

class UpdateService {
  const UpdateService();

  /// Fetches the newest update manifest. Returns `null` on any failure so
  /// callers can treat a failed background check as "check again later".
  Future<UpdateManifest?> fetchManifest() async {
    try {
      final response = await http.get(
        Uri.parse(kUpdateManifestUrl),
        headers: const {'Accept': 'application/json', 'User-Agent': 'Walt-Updater'},
      );
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return UpdateManifest.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Compares the installed [currentVersionCode] against [manifest] and
  /// reports whether an update is available and/or required.
  UpdateCheckResult check({
    required UpdateManifest? manifest,
    required int currentVersionCode,
  }) {
    if (manifest == null ||
        manifest.latestVersionCode <= 0 ||
        manifest.apkUrl.isEmpty) {
      return UpdateCheckResult.checkFailed;
    }
    if (!manifest.isNewerThan(currentVersionCode)) {
      return UpdateCheckResult.upToDate;
    }
    if (manifest.isMandatoryFor(currentVersionCode)) {
      return UpdateCheckResult.updateMandatory;
    }
    return UpdateCheckResult.updateAvailable;
  }

  /// Downloads and installs the manifest's APK.
  ///
  /// `ota_update` downloads the file with live progress, verifies the SHA-256
  /// from the manifest against the downloaded bytes **before** anything is
  /// installed (it surfaces `OtaStatus.CHECKSUM_ERROR` on a mismatch), and
  /// hands off to Android's system `PackageInstaller`.
  Stream<OtaEvent> downloadAndInstall({
    required UpdateManifest manifest,
  }) {
    return OtaUpdate().execute(
      manifest.apkUrl,
      destinationFilename: 'walt-update.apk',
      // Verified natively before the install intent is fired.
      sha256checksum: manifest.sha256,
    );
  }
}