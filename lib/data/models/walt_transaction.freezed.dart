// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walt_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaltTransaction {

 int get id; double get amount; String get type;// 'income' or 'expense'
 int get categoryId; DateTime get date; int? get accountId; String? get note; String? get merchant; DateTime? get createdAt;
/// Create a copy of WaltTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaltTransactionCopyWith<WaltTransaction> get copyWith => _$WaltTransactionCopyWithImpl<WaltTransaction>(this as WaltTransaction, _$identity);

  /// Serializes this WaltTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaltTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.date, date) || other.date == date)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,type,categoryId,date,accountId,note,merchant,createdAt);

@override
String toString() {
  return 'WaltTransaction(id: $id, amount: $amount, type: $type, categoryId: $categoryId, date: $date, accountId: $accountId, note: $note, merchant: $merchant, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WaltTransactionCopyWith<$Res>  {
  factory $WaltTransactionCopyWith(WaltTransaction value, $Res Function(WaltTransaction) _then) = _$WaltTransactionCopyWithImpl;
@useResult
$Res call({
 int id, double amount, String type, int categoryId, DateTime date, int? accountId, String? note, String? merchant, DateTime? createdAt
});




}
/// @nodoc
class _$WaltTransactionCopyWithImpl<$Res>
    implements $WaltTransactionCopyWith<$Res> {
  _$WaltTransactionCopyWithImpl(this._self, this._then);

  final WaltTransaction _self;
  final $Res Function(WaltTransaction) _then;

/// Create a copy of WaltTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? type = null,Object? categoryId = null,Object? date = null,Object? accountId = freezed,Object? note = freezed,Object? merchant = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaltTransaction].
extension WaltTransactionPatterns on WaltTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaltTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaltTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaltTransaction value)  $default,){
final _that = this;
switch (_that) {
case _WaltTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaltTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _WaltTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  double amount,  String type,  int categoryId,  DateTime date,  int? accountId,  String? note,  String? merchant,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaltTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.type,_that.categoryId,_that.date,_that.accountId,_that.note,_that.merchant,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  double amount,  String type,  int categoryId,  DateTime date,  int? accountId,  String? note,  String? merchant,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WaltTransaction():
return $default(_that.id,_that.amount,_that.type,_that.categoryId,_that.date,_that.accountId,_that.note,_that.merchant,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  double amount,  String type,  int categoryId,  DateTime date,  int? accountId,  String? note,  String? merchant,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WaltTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.type,_that.categoryId,_that.date,_that.accountId,_that.note,_that.merchant,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaltTransaction implements WaltTransaction {
  const _WaltTransaction({required this.id, required this.amount, required this.type, required this.categoryId, required this.date, this.accountId, this.note, this.merchant, this.createdAt});
  factory _WaltTransaction.fromJson(Map<String, dynamic> json) => _$WaltTransactionFromJson(json);

@override final  int id;
@override final  double amount;
@override final  String type;
// 'income' or 'expense'
@override final  int categoryId;
@override final  DateTime date;
@override final  int? accountId;
@override final  String? note;
@override final  String? merchant;
@override final  DateTime? createdAt;

/// Create a copy of WaltTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaltTransactionCopyWith<_WaltTransaction> get copyWith => __$WaltTransactionCopyWithImpl<_WaltTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaltTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaltTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.date, date) || other.date == date)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,type,categoryId,date,accountId,note,merchant,createdAt);

@override
String toString() {
  return 'WaltTransaction(id: $id, amount: $amount, type: $type, categoryId: $categoryId, date: $date, accountId: $accountId, note: $note, merchant: $merchant, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WaltTransactionCopyWith<$Res> implements $WaltTransactionCopyWith<$Res> {
  factory _$WaltTransactionCopyWith(_WaltTransaction value, $Res Function(_WaltTransaction) _then) = __$WaltTransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, double amount, String type, int categoryId, DateTime date, int? accountId, String? note, String? merchant, DateTime? createdAt
});




}
/// @nodoc
class __$WaltTransactionCopyWithImpl<$Res>
    implements _$WaltTransactionCopyWith<$Res> {
  __$WaltTransactionCopyWithImpl(this._self, this._then);

  final _WaltTransaction _self;
  final $Res Function(_WaltTransaction) _then;

/// Create a copy of WaltTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? type = null,Object? categoryId = null,Object? date = null,Object? accountId = freezed,Object? note = freezed,Object? merchant = freezed,Object? createdAt = freezed,}) {
  return _then(_WaltTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
