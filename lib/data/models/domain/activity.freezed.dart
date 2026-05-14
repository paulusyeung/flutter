// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Activity {

 String get id; int get activityTypeId; String get notes; DateTime get createdAt; String get ip; String? get userLabel; String? get clientLabel; String? get invoiceLabel;
/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityCopyWith<Activity> get copyWith => _$ActivityCopyWithImpl<Activity>(this as Activity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.activityTypeId, activityTypeId) || other.activityTypeId == activityTypeId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.userLabel, userLabel) || other.userLabel == userLabel)&&(identical(other.clientLabel, clientLabel) || other.clientLabel == clientLabel)&&(identical(other.invoiceLabel, invoiceLabel) || other.invoiceLabel == invoiceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,activityTypeId,notes,createdAt,ip,userLabel,clientLabel,invoiceLabel);

@override
String toString() {
  return 'Activity(id: $id, activityTypeId: $activityTypeId, notes: $notes, createdAt: $createdAt, ip: $ip, userLabel: $userLabel, clientLabel: $clientLabel, invoiceLabel: $invoiceLabel)';
}


}

/// @nodoc
abstract mixin class $ActivityCopyWith<$Res>  {
  factory $ActivityCopyWith(Activity value, $Res Function(Activity) _then) = _$ActivityCopyWithImpl;
@useResult
$Res call({
 String id, int activityTypeId, String notes, DateTime createdAt, String ip, String? userLabel, String? clientLabel, String? invoiceLabel
});




}
/// @nodoc
class _$ActivityCopyWithImpl<$Res>
    implements $ActivityCopyWith<$Res> {
  _$ActivityCopyWithImpl(this._self, this._then);

  final Activity _self;
  final $Res Function(Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? activityTypeId = null,Object? notes = null,Object? createdAt = null,Object? ip = null,Object? userLabel = freezed,Object? clientLabel = freezed,Object? invoiceLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityTypeId: null == activityTypeId ? _self.activityTypeId : activityTypeId // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,userLabel: freezed == userLabel ? _self.userLabel : userLabel // ignore: cast_nullable_to_non_nullable
as String?,clientLabel: freezed == clientLabel ? _self.clientLabel : clientLabel // ignore: cast_nullable_to_non_nullable
as String?,invoiceLabel: freezed == invoiceLabel ? _self.invoiceLabel : invoiceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Activity].
extension ActivityPatterns on Activity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Activity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Activity value)  $default,){
final _that = this;
switch (_that) {
case _Activity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Activity value)?  $default,){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int activityTypeId,  String notes,  DateTime createdAt,  String ip,  String? userLabel,  String? clientLabel,  String? invoiceLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.userLabel,_that.clientLabel,_that.invoiceLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int activityTypeId,  String notes,  DateTime createdAt,  String ip,  String? userLabel,  String? clientLabel,  String? invoiceLabel)  $default,) {final _that = this;
switch (_that) {
case _Activity():
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.userLabel,_that.clientLabel,_that.invoiceLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int activityTypeId,  String notes,  DateTime createdAt,  String ip,  String? userLabel,  String? clientLabel,  String? invoiceLabel)?  $default,) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.userLabel,_that.clientLabel,_that.invoiceLabel);case _:
  return null;

}
}

}

/// @nodoc


class _Activity extends Activity {
  const _Activity({required this.id, required this.activityTypeId, required this.notes, required this.createdAt, required this.ip, this.userLabel, this.clientLabel, this.invoiceLabel}): super._();
  

@override final  String id;
@override final  int activityTypeId;
@override final  String notes;
@override final  DateTime createdAt;
@override final  String ip;
@override final  String? userLabel;
@override final  String? clientLabel;
@override final  String? invoiceLabel;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityCopyWith<_Activity> get copyWith => __$ActivityCopyWithImpl<_Activity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.activityTypeId, activityTypeId) || other.activityTypeId == activityTypeId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.userLabel, userLabel) || other.userLabel == userLabel)&&(identical(other.clientLabel, clientLabel) || other.clientLabel == clientLabel)&&(identical(other.invoiceLabel, invoiceLabel) || other.invoiceLabel == invoiceLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,activityTypeId,notes,createdAt,ip,userLabel,clientLabel,invoiceLabel);

@override
String toString() {
  return 'Activity(id: $id, activityTypeId: $activityTypeId, notes: $notes, createdAt: $createdAt, ip: $ip, userLabel: $userLabel, clientLabel: $clientLabel, invoiceLabel: $invoiceLabel)';
}


}

/// @nodoc
abstract mixin class _$ActivityCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory _$ActivityCopyWith(_Activity value, $Res Function(_Activity) _then) = __$ActivityCopyWithImpl;
@override @useResult
$Res call({
 String id, int activityTypeId, String notes, DateTime createdAt, String ip, String? userLabel, String? clientLabel, String? invoiceLabel
});




}
/// @nodoc
class __$ActivityCopyWithImpl<$Res>
    implements _$ActivityCopyWith<$Res> {
  __$ActivityCopyWithImpl(this._self, this._then);

  final _Activity _self;
  final $Res Function(_Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? activityTypeId = null,Object? notes = null,Object? createdAt = null,Object? ip = null,Object? userLabel = freezed,Object? clientLabel = freezed,Object? invoiceLabel = freezed,}) {
  return _then(_Activity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityTypeId: null == activityTypeId ? _self.activityTypeId : activityTypeId // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,userLabel: freezed == userLabel ? _self.userLabel : userLabel // ignore: cast_nullable_to_non_nullable
as String?,clientLabel: freezed == clientLabel ? _self.clientLabel : clientLabel // ignore: cast_nullable_to_non_nullable
as String?,invoiceLabel: freezed == invoiceLabel ? _self.invoiceLabel : invoiceLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
