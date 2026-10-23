// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walt_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaltCategoryAdapter extends TypeAdapter<WaltCategory> {
  @override
  final typeId = 0;

  @override
  WaltCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaltCategory(
      id: (fields[0] as num).toInt(),
      name: fields[1] as String,
      icon: fields[2] as String,
      color: fields[3] as String,
      type: fields[4] as String,
      isDefault: fields[5] == null ? false : fields[5] as bool,
      imageSource: fields[6] == null
          ? CategoryImageSource.asset
          : fields[6] as CategoryImageSource,
      imagePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WaltCategory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isDefault)
      ..writeByte(6)
      ..write(obj.imageSource)
      ..writeByte(7)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaltCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryImageSourceAdapter extends TypeAdapter<CategoryImageSource> {
  @override
  final typeId = 1;

  @override
  CategoryImageSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryImageSource.asset;
      case 1:
        return CategoryImageSource.file;
      default:
        return CategoryImageSource.asset;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryImageSource obj) {
    switch (obj) {
      case CategoryImageSource.asset:
        writer.writeByte(0);
      case CategoryImageSource.file:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryImageSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WaltCategory _$WaltCategoryFromJson(Map<String, dynamic> json) =>
    _WaltCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      type: json['type'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      imageSource:
          $enumDecodeNullable(
            _$CategoryImageSourceEnumMap,
            json['imageSource'],
          ) ??
          CategoryImageSource.asset,
      imagePath: json['imagePath'] as String?,
    );

Map<String, dynamic> _$WaltCategoryToJson(_WaltCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'type': instance.type,
      'isDefault': instance.isDefault,
      'imageSource': _$CategoryImageSourceEnumMap[instance.imageSource]!,
      'imagePath': instance.imagePath,
    };

const _$CategoryImageSourceEnumMap = {
  CategoryImageSource.asset: 'asset',
  CategoryImageSource.file: 'file',
};
