// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walt_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaltAccount {

 int get id; String get name; String get type; double get balance; String get currency; String? get color; bool get isDefault;
/// Create a copy of WaltAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaltAccountCopyWith<WaltAccount> get copyWith => _$WaltAccountCopyWithImpl<WaltAccount>(this as WaltAccount, _$identity);

  /// Serializes this WaltAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaltAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,balance,currency,color,isDefault);

@override
String toString() {
  return 'WaltAccount(id: $id, name: $name, type: $type, balance: $balance, currency: $currency, color: $color, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $WaltAccountCopyWith<$Res>  {
  factory $WaltAccountCopyWith(WaltAccount value, $Res Function(WaltAccount) _then) = _$WaltAccountCopyWithImpl;
@useResult
$Res call({
 int id, String name, String type, double balance, String currency, String? color, bool isDefault
});




}
/// @nodoc
class _$WaltAccountCopyWithImpl<$Res>
    implements $WaltAccountCopyWith<$Res> {
  _$WaltAccountCopyWithImpl(this._self, this._then);

  final WaltAccount _self;
  final $Res Function(WaltAccount) _then;

/// Create a copy of WaltAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? balance = null,Object? currency = null,Object? color = freezed,Object? isDefault = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WaltAccount].
extension WaltAccountPatterns on WaltAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaltAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaltAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaltAccount value)  $default,){
final _that = this;
switch (_that) {
case _WaltAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaltAccount value)?  $default,){
final _that = this;
switch (_that) {
case _WaltAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String type,  double balance,  String currency,  String? color,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaltAccount() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.balance,_that.currency,_that.color,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String type,  double balance,  String currency,  String? color,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _WaltAccount():
return $default(_that.id,_that.name,_that.type,_that.balance,_that.currency,_that.color,_that.isDefault);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String type,  double balance,  String currency,  String? color,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _WaltAccount() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.balance,_that.currency,_that.color,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaltAccount implements WaltAccount {
  const _WaltAccount({required this.id, required this.name, required this.type, required this.balance, required this.currency, this.color, this.isDefault = false});
  factory _WaltAccount.fromJson(Map<String, dynamic> json) => _$WaltAccountFromJson(json);

@override final  int id;
@override final  String name;
@override final  String type;
@override final  double balance;
@override final  String currency;
@override final  String? color;
@override@JsonKey() final  bool isDefault;

/// Create a copy of WaltAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaltAccountCopyWith<_WaltAccount> get copyWith => __$WaltAccountCopyWithImpl<_WaltAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaltAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaltAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,balance,currency,color,isDefault);

@override
String toString() {
  return 'WaltAccount(id: $id, name: $name, type: $type, balance: $balance, currency: $currency, color: $color, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$WaltAccountCopyWith<$Res> implements $WaltAccountCopyWith<$Res> {
  factory _$WaltAccountCopyWith(_WaltAccount value, $Res Function(_WaltAccount) _then) = __$WaltAccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String type, double balance, String currency, String? color, bool isDefault
});




}
/// @nodoc
class __$WaltAccountCopyWithImpl<$Res>
    implements _$WaltAccountCopyWith<$Res> {
  __$WaltAccountCopyWithImpl(this._self, this._then);

  final _WaltAccount _self;
  final $Res Function(_WaltAccount) _then;

/// Create a copy of WaltAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? balance = null,Object? currency = null,Object? color = freezed,Object? isDefault = null,}) {
  return _then(_WaltAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
