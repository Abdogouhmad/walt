import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

part 'walt_category.freezed.dart';
part 'walt_category.g.dart';

/// Where a category's artwork comes from.
///
/// Bundled category images ship with the app. Imported images are copied into
/// the app's documents directory and referenced by a path relative to it, so a
/// picker cache path is never persisted.
@HiveType(typeId: 1)
enum CategoryImageSource {
  @HiveField(0)
  asset,
  @HiveField(1)
  file,
}

@freezed
@HiveType(typeId: 0)
sealed class WaltCategory with _$WaltCategory {
  const factory WaltCategory({
    @HiveField(0) required int id,
    @HiveField(1) required String name,

    /// Material icon key, retained as the fallback when no artwork is set and
    /// as the icon used by compact chart legends.
    @HiveField(2) required String icon,
    @HiveField(3) required String color,
    @HiveField(4) required String type,
    @HiveField(5) @Default(false) bool isDefault,

    /// Asset path or app-documents-relative file path.
    @HiveField(6)
    @Default(CategoryImageSource.asset)
    CategoryImageSource imageSource,
    @HiveField(7) String? imagePath,
  }) = _WaltCategory;

  factory WaltCategory.fromJson(Map<String, dynamic> json) =>
      _$WaltCategoryFromJson(json);
}

extension WaltCategoryX on WaltCategory {
  /// Whether this category has artwork to render instead of [icon].
  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;
}
