import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt_ui/walt_ui.dart';

/// The accent a category's artwork is drawn in.
///
/// User colours are harmonised toward the active chart palette, exactly like
/// [CategoryAvatar] does, so a category picked under Amber does not stay frozen
/// in orange after switching to Ocean.
Color categoryAccentColor(
  BuildContext context,
  WaltCategory category, {
  int seriesIndex = 0,
}) {
  final parsed = CategoryAvatar.parseHex(category.color);
  return WaltChartColors.of(context).harmonizeCategory(parsed, seriesIndex);
}

/// One category's artwork: bundled asset, imported file or icon fallback.
///
/// Bundled categories are white silhouettes, so they are tinted with the
/// category accent. Imported photos are shown as-is and are never tinted.
class CategoryArtwork extends StatefulWidget {
  const CategoryArtwork({
    super.key,
    required this.category,
    this.size = 48,
    this.radius,
    this.seriesIndex = 0,
    this.background,
    this.filled = true,
  });

  final WaltCategory category;
  final double size;
  final double? radius;
  final int seriesIndex;
  final Color? background;

  /// Whether to paint the tonal plate behind the artwork. Off for images that
  /// already fill a card header.
  final bool filled;

  @override
  State<CategoryArtwork> createState() => _CategoryArtworkState();
}

class _CategoryArtworkState extends State<CategoryArtwork> {
  /// Resolved image paths, shared by every tile showing the same artwork.
  ///
  /// Bounded because imported photos can come and go with categories; an
  /// unbounded map would keep a future (and its path) per image for the life of
  /// the process. Failed lookups are evicted below so a restored file appears
  /// without restarting the app.
  static final BoundedMemo<String, Future<String?>> _resolvedPaths =
      BoundedMemo<String, Future<String?>>(64);

  Future<String?>? _fileFuture;
  String? _sourcePath;

  @override
  void initState() {
    super.initState();
    _prepareFileFuture();
  }

  @override
  void didUpdateWidget(covariant CategoryArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.imagePath != widget.category.imagePath ||
        oldWidget.category.imageSource != widget.category.imageSource) {
      _prepareFileFuture();
    }
  }

  void _prepareFileFuture() {
    final category = widget.category;
    if (!category.hasImage ||
        category.imageSource != CategoryImageSource.file) {
      _sourcePath = null;
      _fileFuture = null;
      return;
    }
    final path = category.imagePath!;
    _sourcePath = path;
    _fileFuture = _resolvedPaths.getOrPut(
      path,
      () => _resolve(path).then((resolved) {
        // A missing file is a temporary state, not an immutable fact: a backup
        // restore can put the artwork back. Do not cache the absence.
        if (resolved == null) _resolvedPaths.remove(path);
        return resolved;
      }),
    );
  }

  static Future<String?> _resolve(String stored) async {
    try {
      if (p.isAbsolute(stored)) {
        return await File(stored).exists() ? stored : null;
      }
      final docs = await getApplicationDocumentsDirectory();
      final absolute = p.join(docs.path, stored);
      return await File(absolute).exists() ? absolute : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = categoryAccentColor(
      context,
      widget.category,
      seriesIndex: widget.seriesIndex,
    );
    final radius = widget.radius ?? widget.size * 0.32;
    // Decode at the size the tile is actually drawn. An imported phone photo
    // can be tens of megapixels; decoding it full-size for a 40 px row costs
    // megabytes of image cache per tile.
    final decodeExtent = widget.size > 0
        ? (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil()
        : null;
    final background =
        widget.background ?? accent.withValues(alpha: widget.filled ? 0.14 : 0);

    final fallback = Icon(
      CategoryIcons.getIcon(widget.category.icon),
      size: widget.size * 0.48,
      color: accent,
    );

    Widget content;
    if (!widget.category.hasImage) {
      content = fallback;
    } else if (widget.category.imageSource == CategoryImageSource.asset) {
      content = Padding(
        padding: EdgeInsets.all(widget.size * 0.2),
        // `srcIn` keeps the transparent background transparent and replaces the
        // white silhouette with the category accent.
        child: Image.asset(
          widget.category.imagePath!,
          fit: BoxFit.contain,
          cacheWidth: decodeExtent,
          color: accent,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    } else {
      content = FutureBuilder<String?>(
        key: ValueKey(_sourcePath),
        future: _fileFuture,
        builder: (context, snapshot) {
          final path = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (path == null) return fallback;
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
              cacheWidth: decodeExtent,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
        },
      );
    }

    return Semantics(
      label: '${widget.category.name} category',
      image: widget.category.hasImage,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
