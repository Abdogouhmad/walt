import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local-only image storage for user-picked avatars.
///
/// Walt is privacy-first: images are copied into the app's own documents
/// directory and never uploaded anywhere. Copying matters because
/// `ImagePicker` hands back a *cache* path on Android, which the OS is free to
/// evict — persisting it directly means the avatar silently disappears a few
/// days later.
class ImageStore {
  const ImageStore._();

  static const String _folder = 'profile';

  /// Copies [source] into the app documents directory and returns the new
  /// absolute path. Returns null if the source is missing or the copy fails.
  static Future<String?> importImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final dir = Directory(
        p.join((await getApplicationDocumentsDirectory()).path, _folder),
      );
      if (!await dir.exists()) await dir.create(recursive: true);

      // Stable, extension-preserving name so repeated picks replace rather than
      // accumulate files.
      final extension = p.extension(sourcePath).isEmpty
          ? '.jpg'
          : p.extension(sourcePath);
      final target = File(p.join(dir.path, 'avatar$extension'));
      await source.copy(target.path);
      return target.path;
    } catch (e) {
      debugPrint('ImageStore: could not import $sourcePath — $e');
      return null;
    }
  }

  /// Whether [path] still exists on disk. Used to drop a stale avatar path
  /// instead of rendering a broken image.
  /// Whether [path] still points at a readable file.
  ///
  /// Synchronous because it is called from `build()`. The cost is a single
  /// `stat`, which is not free but is bounded, and the alternative — resolving
  /// it in a `Future` — would mean the avatar renders the initial for one frame
  /// on every screen it appears in, which is a worse trade than the `stat`.
  ///
  /// Callers must not pass an untrusted or remote path; this is only ever the
  /// app's own copy of a user-picked image.
  static bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
