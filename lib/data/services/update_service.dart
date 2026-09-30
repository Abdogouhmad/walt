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

/// Upper bound on a single manifest fetch. A stalled connection must resolve
/// to a normal failed check, never leave the UI in `checking` indefinitely.
const Duration kUpdateCheckTimeout = Duration(seconds: 15);

/// The manifest URI, with a cache-busting parameter.
///
/// `raw.githubusercontent.com` is fronted by a CDN that serves a stale copy for
/// minutes after a release is committed. The server ignores the query string
/// when resolving the path but varies its cache on it, so a per-request
/// timestamp makes every check read the manifest that was just published.
Uri manifestUri({DateTime? now}) {
  final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
  return Uri.parse('$kUpdateManifestUrl?ts=$stamp');
}

/// Result of comparing the installed version against the latest manifest.
enum UpdateCheckResult {
  /// The app is already up to date.
  upToDate,

  /// An update is available. Always optional: Walt never blocks use of an
  /// older version.
  updateAvailable,

  /// The check failed (offline, HTTP error, malformed manifest).
  checkFailed,
}

class UpdateService {
  const UpdateService();

  /// Fetches the newest update manifest. Returns `null` on any failure so
  /// callers can treat a failed background check as "check again later".
  ///
  /// The request is bounded by [timeout] so a connection that stalls without
  /// failing would otherwise leave the UI spinning in `checking` forever
  /// instead of resolving to a plain "couldn't check".
  Future<UpdateManifest?> fetchManifest({Duration? timeout}) async {
    try {
      final response = await http
          .get(
            manifestUri(),
            headers: const {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'User-Agent': 'Walt-Updater',
            },
          )
          .timeout(timeout ?? kUpdateCheckTimeout);
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return UpdateManifest.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Compares the installed [currentVersionCode] against [manifest] and
  /// reports whether an update is available. An available update is never
  /// mandatory — the result set is the same whether or not the manifest still
  /// carries a legacy `mandatory` flag.
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
    return UpdateCheckResult.updateAvailable;
  }

  /// Downloads and installs the manifest's APK.
  ///
  /// `ota_update` downloads the file with live progress, verifies the SHA-256
  /// from the manifest against the downloaded bytes **before** anything is
  /// installed (it surfaces `OtaStatus.CHECKSUM_ERROR` on a mismatch), and
  /// hands off to Android's system `PackageInstaller`.
  Stream<OtaEvent> downloadAndInstall({required UpdateManifest manifest}) {
    return OtaUpdate().execute(
      manifest.apkUrl,
      destinationFilename: 'walt-update.apk',
      // Verified natively before the install intent is fired.
      sha256checksum: manifest.sha256,
    );
  }
}
