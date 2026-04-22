import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

part 'walt_category.freezed.dart';
part 'walt_category.g.dart';

@freezed
@HiveType(typeId: 0) // Add this
sealed class WaltCategory with _$WaltCategory {
  const factory WaltCategory({
    @HiveField(0) required int id,
    @HiveField(1) required String name,
    @HiveField(2) required String icon,
    @HiveField(3) required String color,
    @HiveField(4) required String type,
    @HiveField(5) @Default(false) bool isDefault,
  }) = _WaltCategory;

  factory WaltCategory.fromJson(Map<String, dynamic> json) =>
      _$WaltCategoryFromJson(json);
}
