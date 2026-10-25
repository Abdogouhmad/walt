import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local-only image storage for user-picked avatars and category images.
///
/// Walt is privacy-first: images are copied into the app's own documents
/// directory and never uploaded anywhere. Copying matters because
/// `ImagePicker` hands back a *cache* path on Android, which the OS is free to
/// evict — persisting it directly means the avatar silently disappears a few
/// days later.
class ImageStore {
  const ImageStore._();

  static const String _profileFolder = 'profile';
  static const String _categoryFolder = 'categories';

  /// Copies [source] into the app documents directory and returns the new
  /// absolute path. Returns null if the source is missing or the copy fails.
  static Future<String?> importImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final dir = Directory(
        p.join((await getApplicationDocumentsDirectory()).path, _profileFolder),
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

  /// Copies a picked image into the category images folder and returns the
  /// app-documents-relative path (e.g. `categories/foo.png`) so it survives
  /// base directory changes and is never stored as a raw cache path.
  static Future<String?> importCategoryImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, _categoryFolder));
      if (!await dir.exists()) await dir.create(recursive: true);

      final extension = p.extension(sourcePath).isEmpty
          ? '.png'
          : p.extension(sourcePath);
      final name = 'cat_${DateTime.now().millisecondsSinceEpoch}$extension';
      final target = File(p.join(dir.path, name));
      await source.copy(target.path);
      return p.join(_categoryFolder, name);
    } catch (e) {
      debugPrint('ImageStore: could not import category $sourcePath — $e');
      return null;
    }
  }

  /// Deletes a category image that is no longer referenced.
  ///
  /// Category edits and deletions used to leave every replaced or removed photo
  /// behind in the app's documents directory. The guard is deliberate: only
  /// files under the `categories/` folder can be deleted, so a damaged store
  /// cannot point this at an arbitrary file.
  static Future<void> deleteCategoryImage(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) return;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final normalized = p.normalize(storedPath.trim());
      final absolute = p.isAbsolute(normalized)
          ? normalized
          : p.join(docs.path, normalized);
      final categoryDirectory = p.normalize(p.join(docs.path, _categoryFolder));
      if (!p.isWithin(categoryDirectory, absolute)) {
        debugPrint('ImageStore: refused to delete outside $categoryDirectory');
        return;
      }

      final file = File(absolute);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('ImageStore: could not delete $storedPath — $e');
    }
  }

  /// Resolves an app-documents-relative image path to an absolute path.
  static Future<String?> resolveRelativePath(String? relativePath) async {
    if (relativePath == null || relativePath.trim().isEmpty) return null;
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, relativePath);
  }

  /// Synchronously resolve a relative path using a cached documents dir when
  /// possible; callers fall back to assets or show placeholder if missing.
  static String? resolveRelativePathSync(
    String? relativePath,
    String documentsDir,
  ) {
    if (relativePath == null || relativePath.trim().isEmpty) return null;
    return p.join(documentsDir, relativePath);
  }

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
