import 'package:package_info_plus/package_info_plus.dart';

/// App identity captured once at startup from `PackageInfo`.
///
/// The OTA updater compares the Android `versionCode` ([buildNumber]) against
/// `update_manifest.json` (spec §3.2). Because Walt derives versionCode
/// deterministically from the semver version (§2), `version` and `buildNumber`
/// can never drift apart.
class Appinfo {
  static late String _version;
  static late String _appname;
  static late int _buildNumber;

  static bool _initialized = false;

  /// Call this ONCE at app startup
  static Future<void> init() async {
    if (_initialized) return;

    final pkg = await PackageInfo.fromPlatform();
    _version = pkg.version;
    _appname = pkg.appName;
    _buildNumber = int.tryParse(pkg.buildNumber) ?? 0;
    _initialized = true;
  }

  /// Synchronous getter
  static String get version {
    _ensureInitialized();
    return _version;
  }

  static String get appname {
    _ensureInitialized();
    return _appname;
  }

  /// Android `versionCode` as parsed from `PackageInfo.buildNumber`.
  static int get buildNumber {
    _ensureInitialized();
    return _buildNumber;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'Appinfo not initialized. Call Appinfo.init() before accessing.',
      );
    }
  }
}