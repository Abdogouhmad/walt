import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A [PathProviderPlatform] that points at a real temporary directory, so
/// Hive has somewhere to live during the tests.
class FakePathProvider extends PathProviderPlatform {
  static final String _docs = Directory.systemTemp
      .createTempSync('walt_test_docs')
      .path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docs;

  @override
  Future<String?> getTemporaryPath() async => _docs;
}
