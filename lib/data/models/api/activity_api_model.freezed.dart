// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityLabelApi {

 String get label;@JsonKey(name: 'hashed_id') String get hashedId;
/// Create a copy of ActivityLabelApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<ActivityLabelApi> get copyWith => _$ActivityLabelApiCopyWithImpl<ActivityLabelApi>(this as ActivityLabelApi, _$identity);

  /// Serializes this ActivityLabelApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityLabelApi&&(identical(other.label, label) || other.label == label)&&(identical(other.hashedId, hashedId) || other.hashedId == hashedId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,hashedId);

@override
String toString() {
  return 'ActivityLabelApi(label: $label, hashedId: $hashedId)';
}


}

/// @nodoc
abstract mixin class $ActivityLabelApiCopyWith<$Res>  {
  factory $ActivityLabelApiCopyWith(ActivityLabelApi value, $Res Function(ActivityLabelApi) _then) = _$ActivityLabelApiCopyWithImpl;
@useResult
$Res call({
 String label,@JsonKey(name: 'hashed_id') String hashedId
});




}
/// @nodoc
class _$ActivityLabelApiCopyWithImpl<$Res>
    implements $ActivityLabelApiCopyWith<$Res> {
  _$ActivityLabelApiCopyWithImpl(this._self, this._then);

  final ActivityLabelApi _self;
  final $Res Function(ActivityLabelApi) _then;

/// Create a copy of ActivityLabelApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? hashedId = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hashedId: null == hashedId ? _self.hashedId : hashedId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityLabelApi].
extension ActivityLabelApiPatterns on ActivityLabelApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityLabelApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityLabelApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityLabelApi value)  $default,){
final _that = this;
switch (_that) {
case _ActivityLabelApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityLabelApi value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityLabelApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label, @JsonKey(name: 'hashed_id')  String hashedId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityLabelApi() when $default != null:
return $default(_that.label,_that.hashedId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label, @JsonKey(name: 'hashed_id')  String hashedId)  $default,) {final _that = this;
switch (_that) {
case _ActivityLabelApi():
return $default(_that.label,_that.hashedId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label, @JsonKey(name: 'hashed_id')  String hashedId)?  $default,) {final _that = this;
switch (_that) {
case _ActivityLabelApi() when $default != null:
return $default(_that.label,_that.hashedId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityLabelApi implements ActivityLabelApi {
  const _ActivityLabelApi({this.label = '', @JsonKey(name: 'hashed_id') this.hashedId = ''});
  factory _ActivityLabelApi.fromJson(Map<String, dynamic> json) => _$ActivityLabelApiFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey(name: 'hashed_id') final  String hashedId;

/// Create a copy of ActivityLabelApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityLabelApiCopyWith<_ActivityLabelApi> get copyWith => __$ActivityLabelApiCopyWithImpl<_ActivityLabelApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityLabelApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityLabelApi&&(identical(other.label, label) || other.label == label)&&(identical(other.hashedId, hashedId) || other.hashedId == hashedId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,hashedId);

@override
String toString() {
  return 'ActivityLabelApi(label: $label, hashedId: $hashedId)';
}


}

/// @nodoc
abstract mixin class _$ActivityLabelApiCopyWith<$Res> implements $ActivityLabelApiCopyWith<$Res> {
  factory _$ActivityLabelApiCopyWith(_ActivityLabelApi value, $Res Function(_ActivityLabelApi) _then) = __$ActivityLabelApiCopyWithImpl;
@override @useResult
$Res call({
 String label,@JsonKey(name: 'hashed_id') String hashedId
});




}
/// @nodoc
class __$ActivityLabelApiCopyWithImpl<$Res>
    implements _$ActivityLabelApiCopyWith<$Res> {
  __$ActivityLabelApiCopyWithImpl(this._self, this._then);

  final _ActivityLabelApi _self;
  final $Res Function(_ActivityLabelApi) _then;

/// Create a copy of ActivityLabelApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? hashedId = null,}) {
  return _then(_ActivityLabelApi(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hashedId: null == hashedId ? _self.hashedId : hashedId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ActivityApi {

@JsonKey(name: 'hashed_id') String get id;@JsonKey(name: 'activity_type_id') int get activityTypeId; String get notes;@JsonKey(name: 'created_at') int get createdAt; String get ip; ActivityLabelApi? get user; ActivityLabelApi? get client; ActivityLabelApi? get invoice;
/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityApiCopyWith<ActivityApi> get copyWith => _$ActivityApiCopyWithImpl<ActivityApi>(this as ActivityApi, _$identity);

  /// Serializes this ActivityApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityApi&&(identical(other.id, id) || other.id == id)&&(identical(other.activityTypeId, activityTypeId) || other.activityTypeId == activityTypeId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.user, user) || other.user == user)&&(identical(other.client, client) || other.client == client)&&(identical(other.invoice, invoice) || other.invoice == invoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityTypeId,notes,createdAt,ip,user,client,invoice);

@override
String toString() {
  return 'ActivityApi(id: $id, activityTypeId: $activityTypeId, notes: $notes, createdAt: $createdAt, ip: $ip, user: $user, client: $client, invoice: $invoice)';
}


}

/// @nodoc
abstract mixin class $ActivityApiCopyWith<$Res>  {
  factory $ActivityApiCopyWith(ActivityApi value, $Res Function(ActivityApi) _then) = _$ActivityApiCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'hashed_id') String id,@JsonKey(name: 'activity_type_id') int activityTypeId, String notes,@JsonKey(name: 'created_at') int createdAt, String ip, ActivityLabelApi? user, ActivityLabelApi? client, ActivityLabelApi? invoice
});


$ActivityLabelApiCopyWith<$Res>? get user;$ActivityLabelApiCopyWith<$Res>? get client;$ActivityLabelApiCopyWith<$Res>? get invoice;

}
/// @nodoc
class _$ActivityApiCopyWithImpl<$Res>
    implements $ActivityApiCopyWith<$Res> {
  _$ActivityApiCopyWithImpl(this._self, this._then);

  final ActivityApi _self;
  final $Res Function(ActivityApi) _then;

/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? activityTypeId = null,Object? notes = null,Object? createdAt = null,Object? ip = null,Object? user = freezed,Object? client = freezed,Object? invoice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityTypeId: null == activityTypeId ? _self.activityTypeId : activityTypeId // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,invoice: freezed == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,
  ));
}
/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get client {
    if (_self.client == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.client!, (value) {
    return _then(_self.copyWith(client: value));
  });
}/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get invoice {
    if (_self.invoice == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.invoice!, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityApi].
extension ActivityApiPatterns on ActivityApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityApi value)  $default,){
final _that = this;
switch (_that) {
case _ActivityApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityApi value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'hashed_id')  String id, @JsonKey(name: 'activity_type_id')  int activityTypeId,  String notes, @JsonKey(name: 'created_at')  int createdAt,  String ip,  ActivityLabelApi? user,  ActivityLabelApi? client,  ActivityLabelApi? invoice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityApi() when $default != null:
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.user,_that.client,_that.invoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'hashed_id')  String id, @JsonKey(name: 'activity_type_id')  int activityTypeId,  String notes, @JsonKey(name: 'created_at')  int createdAt,  String ip,  ActivityLabelApi? user,  ActivityLabelApi? client,  ActivityLabelApi? invoice)  $default,) {final _that = this;
switch (_that) {
case _ActivityApi():
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.user,_that.client,_that.invoice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'hashed_id')  String id, @JsonKey(name: 'activity_type_id')  int activityTypeId,  String notes, @JsonKey(name: 'created_at')  int createdAt,  String ip,  ActivityLabelApi? user,  ActivityLabelApi? client,  ActivityLabelApi? invoice)?  $default,) {final _that = this;
switch (_that) {
case _ActivityApi() when $default != null:
return $default(_that.id,_that.activityTypeId,_that.notes,_that.createdAt,_that.ip,_that.user,_that.client,_that.invoice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityApi implements ActivityApi {
  const _ActivityApi({@JsonKey(name: 'hashed_id') this.id = '', @JsonKey(name: 'activity_type_id') this.activityTypeId = 0, this.notes = '', @JsonKey(name: 'created_at') this.createdAt = 0, this.ip = '', this.user, this.client, this.invoice});
  factory _ActivityApi.fromJson(Map<String, dynamic> json) => _$ActivityApiFromJson(json);

@override@JsonKey(name: 'hashed_id') final  String id;
@override@JsonKey(name: 'activity_type_id') final  int activityTypeId;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'created_at') final  int createdAt;
@override@JsonKey() final  String ip;
@override final  ActivityLabelApi? user;
@override final  ActivityLabelApi? client;
@override final  ActivityLabelApi? invoice;

/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityApiCopyWith<_ActivityApi> get copyWith => __$ActivityApiCopyWithImpl<_ActivityApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityApi&&(identical(other.id, id) || other.id == id)&&(identical(other.activityTypeId, activityTypeId) || other.activityTypeId == activityTypeId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.user, user) || other.user == user)&&(identical(other.client, client) || other.client == client)&&(identical(other.invoice, invoice) || other.invoice == invoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityTypeId,notes,createdAt,ip,user,client,invoice);

@override
String toString() {
  return 'ActivityApi(id: $id, activityTypeId: $activityTypeId, notes: $notes, createdAt: $createdAt, ip: $ip, user: $user, client: $client, invoice: $invoice)';
}


}

/// @nodoc
abstract mixin class _$ActivityApiCopyWith<$Res> implements $ActivityApiCopyWith<$Res> {
  factory _$ActivityApiCopyWith(_ActivityApi value, $Res Function(_ActivityApi) _then) = __$ActivityApiCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'hashed_id') String id,@JsonKey(name: 'activity_type_id') int activityTypeId, String notes,@JsonKey(name: 'created_at') int createdAt, String ip, ActivityLabelApi? user, ActivityLabelApi? client, ActivityLabelApi? invoice
});


@override $ActivityLabelApiCopyWith<$Res>? get user;@override $ActivityLabelApiCopyWith<$Res>? get client;@override $ActivityLabelApiCopyWith<$Res>? get invoice;

}
/// @nodoc
class __$ActivityApiCopyWithImpl<$Res>
    implements _$ActivityApiCopyWith<$Res> {
  __$ActivityApiCopyWithImpl(this._self, this._then);

  final _ActivityApi _self;
  final $Res Function(_ActivityApi) _then;

/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? activityTypeId = null,Object? notes = null,Object? createdAt = null,Object? ip = null,Object? user = freezed,Object? client = freezed,Object? invoice = freezed,}) {
  return _then(_ActivityApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityTypeId: null == activityTypeId ? _self.activityTypeId : activityTypeId // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,invoice: freezed == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as ActivityLabelApi?,
  ));
}

/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get client {
    if (_self.client == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.client!, (value) {
    return _then(_self.copyWith(client: value));
  });
}/// Create a copy of ActivityApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityLabelApiCopyWith<$Res>? get invoice {
    if (_self.invoice == null) {
    return null;
  }

  return $ActivityLabelApiCopyWith<$Res>(_self.invoice!, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}
}


/// @nodoc
mixin _$ActivityListApi {

 List<ActivityApi> get data;
/// Create a copy of ActivityListApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityListApiCopyWith<ActivityListApi> get copyWith => _$ActivityListApiCopyWithImpl<ActivityListApi>(this as ActivityListApi, _$identity);

  /// Serializes this ActivityListApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityListApi&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ActivityListApi(data: $data)';
}


}

/// @nodoc
abstract mixin class $ActivityListApiCopyWith<$Res>  {
  factory $ActivityListApiCopyWith(ActivityListApi value, $Res Function(ActivityListApi) _then) = _$ActivityListApiCopyWithImpl;
@useResult
$Res call({
 List<ActivityApi> data
});




}
/// @nodoc
class _$ActivityListApiCopyWithImpl<$Res>
    implements $ActivityListApiCopyWith<$Res> {
  _$ActivityListApiCopyWithImpl(this._self, this._then);

  final ActivityListApi _self;
  final $Res Function(ActivityListApi) _then;

/// Create a copy of ActivityListApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<ActivityApi>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityListApi].
extension ActivityListApiPatterns on ActivityListApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityListApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityListApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityListApi value)  $default,){
final _that = this;
switch (_that) {
case _ActivityListApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityListApi value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityListApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ActivityApi> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityListApi() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ActivityApi> data)  $default,) {final _that = this;
switch (_that) {
case _ActivityListApi():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ActivityApi> data)?  $default,) {final _that = this;
switch (_that) {
case _ActivityListApi() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityListApi implements ActivityListApi {
  const _ActivityListApi({final  List<ActivityApi> data = const []}): _data = data;
  factory _ActivityListApi.fromJson(Map<String, dynamic> json) => _$ActivityListApiFromJson(json);

 final  List<ActivityApi> _data;
@override@JsonKey() List<ActivityApi> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of ActivityListApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityListApiCopyWith<_ActivityListApi> get copyWith => __$ActivityListApiCopyWithImpl<_ActivityListApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityListApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityListApi&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'ActivityListApi(data: $data)';
}


}

/// @nodoc
abstract mixin class _$ActivityListApiCopyWith<$Res> implements $ActivityListApiCopyWith<$Res> {
  factory _$ActivityListApiCopyWith(_ActivityListApi value, $Res Function(_ActivityListApi) _then) = __$ActivityListApiCopyWithImpl;
@override @useResult
$Res call({
 List<ActivityApi> data
});




}
/// @nodoc
class __$ActivityListApiCopyWithImpl<$Res>
    implements _$ActivityListApiCopyWith<$Res> {
  __$ActivityListApiCopyWithImpl(this._self, this._then);

  final _ActivityListApi _self;
  final $Res Function(_ActivityListApi) _then;

/// Create a copy of ActivityListApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_ActivityListApi(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<ActivityApi>,
  ));
}


}

// dart format on
