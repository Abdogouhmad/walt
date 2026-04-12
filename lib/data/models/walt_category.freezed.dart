// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walt_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaltCategory {

@HiveField(0) int get id;@HiveField(1) String get name;@HiveField(2) String get icon;@HiveField(3) String get color;@HiveField(4) String get type;@HiveField(5) bool get isDefault;
/// Create a copy of WaltCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaltCategoryCopyWith<WaltCategory> get copyWith => _$WaltCategoryCopyWithImpl<WaltCategory>(this as WaltCategory, _$identity);

  /// Serializes this WaltCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaltCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,type,isDefault);

@override
String toString() {
  return 'WaltCategory(id: $id, name: $name, icon: $icon, color: $color, type: $type, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $WaltCategoryCopyWith<$Res>  {
  factory $WaltCategoryCopyWith(WaltCategory value, $Res Function(WaltCategory) _then) = _$WaltCategoryCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int id,@HiveField(1) String name,@HiveField(2) String icon,@HiveField(3) String color,@HiveField(4) String type,@HiveField(5) bool isDefault
});




}
/// @nodoc
class _$WaltCategoryCopyWithImpl<$Res>
    implements $WaltCategoryCopyWith<$Res> {
  _$WaltCategoryCopyWithImpl(this._self, this._then);

  final WaltCategory _self;
  final $Res Function(WaltCategory) _then;

/// Create a copy of WaltCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? type = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WaltCategory].
extension WaltCategoryPatterns on WaltCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaltCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaltCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaltCategory value)  $default,){
final _that = this;
switch (_that) {
case _WaltCategory():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaltCategory value)?  $default,){
final _that = this;
switch (_that) {
case _WaltCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)  String name, @HiveField(2)  String icon, @HiveField(3)  String color, @HiveField(4)  String type, @HiveField(5)  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaltCategory() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isDefault);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int id, @HiveField(1)  String name, @HiveField(2)  String icon, @HiveField(3)  String color, @HiveField(4)  String type, @HiveField(5)  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _WaltCategory():
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isDefault);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int id, @HiveField(1)  String name, @HiveField(2)  String icon, @HiveField(3)  String color, @HiveField(4)  String type, @HiveField(5)  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _WaltCategory() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaltCategory implements WaltCategory {
  const _WaltCategory({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required this.icon, @HiveField(3) required this.color, @HiveField(4) required this.type, @HiveField(5) this.isDefault = false});
  factory _WaltCategory.fromJson(Map<String, dynamic> json) => _$WaltCategoryFromJson(json);

@override@HiveField(0) final  int id;
@override@HiveField(1) final  String name;
@override@HiveField(2) final  String icon;
@override@HiveField(3) final  String color;
@override@HiveField(4) final  String type;
@override@JsonKey()@HiveField(5) final  bool isDefault;

/// Create a copy of WaltCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaltCategoryCopyWith<_WaltCategory> get copyWith => __$WaltCategoryCopyWithImpl<_WaltCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaltCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaltCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,type,isDefault);

@override
String toString() {
  return 'WaltCategory(id: $id, name: $name, icon: $icon, color: $color, type: $type, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$WaltCategoryCopyWith<$Res> implements $WaltCategoryCopyWith<$Res> {
  factory _$WaltCategoryCopyWith(_WaltCategory value, $Res Function(_WaltCategory) _then) = __$WaltCategoryCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int id,@HiveField(1) String name,@HiveField(2) String icon,@HiveField(3) String color,@HiveField(4) String type,@HiveField(5) bool isDefault
});




}
/// @nodoc
class __$WaltCategoryCopyWithImpl<$Res>
    implements _$WaltCategoryCopyWith<$Res> {
  __$WaltCategoryCopyWithImpl(this._self, this._then);

  final _WaltCategory _self;
  final $Res Function(_WaltCategory) _then;

/// Create a copy of WaltCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? type = null,Object? isDefault = null,}) {
  return _then(_WaltCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
