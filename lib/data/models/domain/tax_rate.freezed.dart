// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaxRate {

 String get id; String get name; double get rate; DateTime get updatedAt; DateTime get createdAt; DateTime? get archivedAt; bool get isDeleted; bool get isDirty;
/// Create a copy of TaxRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaxRateCopyWith<TaxRate> get copyWith => _$TaxRateCopyWithImpl<TaxRate>(this as TaxRate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaxRate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,rate,updatedAt,createdAt,archivedAt,isDeleted,isDirty);

@override
String toString() {
  return 'TaxRate(id: $id, name: $name, rate: $rate, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $TaxRateCopyWith<$Res>  {
  factory $TaxRateCopyWith(TaxRate value, $Res Function(TaxRate) _then) = _$TaxRateCopyWithImpl;
@useResult
$Res call({
 String id, String name, double rate, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});




}
/// @nodoc
class _$TaxRateCopyWithImpl<$Res>
    implements $TaxRateCopyWith<$Res> {
  _$TaxRateCopyWithImpl(this._self, this._then);

  final TaxRate _self;
  final $Res Function(TaxRate) _then;

/// Create a copy of TaxRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? rate = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaxRate].
extension TaxRatePatterns on TaxRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaxRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaxRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaxRate value)  $default,){
final _that = this;
switch (_that) {
case _TaxRate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaxRate value)?  $default,){
final _that = this;
switch (_that) {
case _TaxRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double rate,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaxRate() when $default != null:
return $default(_that.id,_that.name,_that.rate,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double rate,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _TaxRate():
return $default(_that.id,_that.name,_that.rate,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double rate,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _TaxRate() when $default != null:
return $default(_that.id,_that.name,_that.rate,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _TaxRate implements TaxRate {
  const _TaxRate({required this.id, required this.name, required this.rate, required this.updatedAt, required this.createdAt, required this.archivedAt, required this.isDeleted, this.isDirty = false});
  

@override final  String id;
@override final  String name;
@override final  double rate;
@override final  DateTime updatedAt;
@override final  DateTime createdAt;
@override final  DateTime? archivedAt;
@override final  bool isDeleted;
@override@JsonKey() final  bool isDirty;

/// Create a copy of TaxRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaxRateCopyWith<_TaxRate> get copyWith => __$TaxRateCopyWithImpl<_TaxRate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaxRate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,rate,updatedAt,createdAt,archivedAt,isDeleted,isDirty);

@override
String toString() {
  return 'TaxRate(id: $id, name: $name, rate: $rate, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$TaxRateCopyWith<$Res> implements $TaxRateCopyWith<$Res> {
  factory _$TaxRateCopyWith(_TaxRate value, $Res Function(_TaxRate) _then) = __$TaxRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double rate, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});




}
/// @nodoc
class __$TaxRateCopyWithImpl<$Res>
    implements _$TaxRateCopyWith<$Res> {
  __$TaxRateCopyWithImpl(this._self, this._then);

  final _TaxRate _self;
  final $Res Function(_TaxRate) _then;

/// Create a copy of TaxRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? rate = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_TaxRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
