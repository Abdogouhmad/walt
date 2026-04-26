import 'package:package_info_plus/package_info_plus.dart';

class Appinfo {
  static late String _version;
  static late String _appname;

  static bool _initialized = false;

  /// Call this ONCE at app startup
  static Future<void> init() async {
    if (_initialized) return;

    final pkg = await PackageInfo.fromPlatform();
    _version = pkg.version;
    _appname = pkg.appName;
    _initialized = true;
  }

  /// Synchronous getter
  static String get version {
    if (!_initialized) {
      throw Exception(
        'Appinfo not initialized. Call Appinfo.init() before using version.',
      );
    }
    return _version;
  }

  static String get appname {
    if (!_initialized) {
      throw Exception(
        'Appinfo not initialized. Call Appinfo.init() before using appname.',
      );
    }
    return _appname;
  }
}
