// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walt_budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaltBudget {

 int get id;/// The budget's primary category. Kept for backwards compatibility with
/// rows written before budgets could span more than one category; the
/// full selection lives in [categoryIds].
 int get categoryId; double get amount; String get period; double get alertAt; DateTime? get createdAt;/// User-facing label. Empty for budgets created before names existed; the
/// UI falls back to the primary category's name.
 String get name;/// Every category this budget consumes. Empty (legacy rows) means "just
/// [categoryId]".
 List<int> get categoryIds;/// Pinned budgets are shown on Home, in [pinOrder] order.
 bool get isPinned; int get pinOrder;/// Per-budget accent (`#RRGGBB`). Null follows the active scheme's primary.
 String? get accentColor;
/// Create a copy of WaltBudget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaltBudgetCopyWith<WaltBudget> get copyWith => _$WaltBudgetCopyWithImpl<WaltBudget>(this as WaltBudget, _$identity);

  /// Serializes this WaltBudget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaltBudget&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.period, period) || other.period == period)&&(identical(other.alertAt, alertAt) || other.alertAt == alertAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.pinOrder, pinOrder) || other.pinOrder == pinOrder)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,amount,period,alertAt,createdAt,name,const DeepCollectionEquality().hash(categoryIds),isPinned,pinOrder,accentColor);

@override
String toString() {
  return 'WaltBudget(id: $id, categoryId: $categoryId, amount: $amount, period: $period, alertAt: $alertAt, createdAt: $createdAt, name: $name, categoryIds: $categoryIds, isPinned: $isPinned, pinOrder: $pinOrder, accentColor: $accentColor)';
}


}

/// @nodoc
abstract mixin class $WaltBudgetCopyWith<$Res>  {
  factory $WaltBudgetCopyWith(WaltBudget value, $Res Function(WaltBudget) _then) = _$WaltBudgetCopyWithImpl;
@useResult
$Res call({
 int id, int categoryId, double amount, String period, double alertAt, DateTime? createdAt, String name, List<int> categoryIds, bool isPinned, int pinOrder, String? accentColor
});




}
/// @nodoc
class _$WaltBudgetCopyWithImpl<$Res>
    implements $WaltBudgetCopyWith<$Res> {
  _$WaltBudgetCopyWithImpl(this._self, this._then);

  final WaltBudget _self;
  final $Res Function(WaltBudget) _then;

/// Create a copy of WaltBudget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? amount = null,Object? period = null,Object? alertAt = null,Object? createdAt = freezed,Object? name = null,Object? categoryIds = null,Object? isPinned = null,Object? pinOrder = null,Object? accentColor = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,alertAt: null == alertAt ? _self.alertAt : alertAt // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,pinOrder: null == pinOrder ? _self.pinOrder : pinOrder // ignore: cast_nullable_to_non_nullable
as int,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaltBudget].
extension WaltBudgetPatterns on WaltBudget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaltBudget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaltBudget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaltBudget value)  $default,){
final _that = this;
switch (_that) {
case _WaltBudget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaltBudget value)?  $default,){
final _that = this;
switch (_that) {
case _WaltBudget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int categoryId,  double amount,  String period,  double alertAt,  DateTime? createdAt,  String name,  List<int> categoryIds,  bool isPinned,  int pinOrder,  String? accentColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaltBudget() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.period,_that.alertAt,_that.createdAt,_that.name,_that.categoryIds,_that.isPinned,_that.pinOrder,_that.accentColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int categoryId,  double amount,  String period,  double alertAt,  DateTime? createdAt,  String name,  List<int> categoryIds,  bool isPinned,  int pinOrder,  String? accentColor)  $default,) {final _that = this;
switch (_that) {
case _WaltBudget():
return $default(_that.id,_that.categoryId,_that.amount,_that.period,_that.alertAt,_that.createdAt,_that.name,_that.categoryIds,_that.isPinned,_that.pinOrder,_that.accentColor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int categoryId,  double amount,  String period,  double alertAt,  DateTime? createdAt,  String name,  List<int> categoryIds,  bool isPinned,  int pinOrder,  String? accentColor)?  $default,) {final _that = this;
switch (_that) {
case _WaltBudget() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.period,_that.alertAt,_that.createdAt,_that.name,_that.categoryIds,_that.isPinned,_that.pinOrder,_that.accentColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaltBudget implements WaltBudget {
  const _WaltBudget({required this.id, required this.categoryId, required this.amount, required this.period, this.alertAt = 0.8, this.createdAt, this.name = '', final  List<int> categoryIds = const <int>[], this.isPinned = false, this.pinOrder = 0, this.accentColor}): _categoryIds = categoryIds;
  factory _WaltBudget.fromJson(Map<String, dynamic> json) => _$WaltBudgetFromJson(json);

@override final  int id;
/// The budget's primary category. Kept for backwards compatibility with
/// rows written before budgets could span more than one category; the
/// full selection lives in [categoryIds].
@override final  int categoryId;
@override final  double amount;
@override final  String period;
@override@JsonKey() final  double alertAt;
@override final  DateTime? createdAt;
/// User-facing label. Empty for budgets created before names existed; the
/// UI falls back to the primary category's name.
@override@JsonKey() final  String name;
/// Every category this budget consumes. Empty (legacy rows) means "just
/// [categoryId]".
 final  List<int> _categoryIds;
/// Every category this budget consumes. Empty (legacy rows) means "just
/// [categoryId]".
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

/// Pinned budgets are shown on Home, in [pinOrder] order.
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  int pinOrder;
/// Per-budget accent (`#RRGGBB`). Null follows the active scheme's primary.
@override final  String? accentColor;

/// Create a copy of WaltBudget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaltBudgetCopyWith<_WaltBudget> get copyWith => __$WaltBudgetCopyWithImpl<_WaltBudget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaltBudgetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaltBudget&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.period, period) || other.period == period)&&(identical(other.alertAt, alertAt) || other.alertAt == alertAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.pinOrder, pinOrder) || other.pinOrder == pinOrder)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,amount,period,alertAt,createdAt,name,const DeepCollectionEquality().hash(_categoryIds),isPinned,pinOrder,accentColor);

@override
String toString() {
  return 'WaltBudget(id: $id, categoryId: $categoryId, amount: $amount, period: $period, alertAt: $alertAt, createdAt: $createdAt, name: $name, categoryIds: $categoryIds, isPinned: $isPinned, pinOrder: $pinOrder, accentColor: $accentColor)';
}


}

/// @nodoc
abstract mixin class _$WaltBudgetCopyWith<$Res> implements $WaltBudgetCopyWith<$Res> {
  factory _$WaltBudgetCopyWith(_WaltBudget value, $Res Function(_WaltBudget) _then) = __$WaltBudgetCopyWithImpl;
@override @useResult
$Res call({
 int id, int categoryId, double amount, String period, double alertAt, DateTime? createdAt, String name, List<int> categoryIds, bool isPinned, int pinOrder, String? accentColor
});




}
/// @nodoc
class __$WaltBudgetCopyWithImpl<$Res>
    implements _$WaltBudgetCopyWith<$Res> {
  __$WaltBudgetCopyWithImpl(this._self, this._then);

  final _WaltBudget _self;
  final $Res Function(_WaltBudget) _then;

/// Create a copy of WaltBudget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? amount = null,Object? period = null,Object? alertAt = null,Object? createdAt = freezed,Object? name = null,Object? categoryIds = null,Object? isPinned = null,Object? pinOrder = null,Object? accentColor = freezed,}) {
  return _then(_WaltBudget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,alertAt: null == alertAt ? _self.alertAt : alertAt // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,pinOrder: null == pinOrder ? _self.pinOrder : pinOrder // ignore: cast_nullable_to_non_nullable
as int,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
