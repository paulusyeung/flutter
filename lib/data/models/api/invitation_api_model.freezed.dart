// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationApi {

 String get id; String get key; String get link;@JsonKey(name: 'client_contact_id') String get clientContactId;@JsonKey(name: 'vendor_contact_id') String get vendorContactId;@JsonKey(name: 'sent_date') String get sentDate;@JsonKey(name: 'viewed_date') String get viewedDate;@JsonKey(name: 'opened_date') String get openedDate;@JsonKey(name: 'email_status') String get emailStatus;@JsonKey(name: 'email_error') String get emailError;@JsonKey(name: 'message_id') String get messageId;@JsonKey(name: 'created_at') int get createdAt;@JsonKey(name: 'updated_at') int get updatedAt;
/// Create a copy of InvitationApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationApiCopyWith<InvitationApi> get copyWith => _$InvitationApiCopyWithImpl<InvitationApi>(this as InvitationApi, _$identity);

  /// Serializes this InvitationApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationApi&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.link, link) || other.link == link)&&(identical(other.clientContactId, clientContactId) || other.clientContactId == clientContactId)&&(identical(other.vendorContactId, vendorContactId) || other.vendorContactId == vendorContactId)&&(identical(other.sentDate, sentDate) || other.sentDate == sentDate)&&(identical(other.viewedDate, viewedDate) || other.viewedDate == viewedDate)&&(identical(other.openedDate, openedDate) || other.openedDate == openedDate)&&(identical(other.emailStatus, emailStatus) || other.emailStatus == emailStatus)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,link,clientContactId,vendorContactId,sentDate,viewedDate,openedDate,emailStatus,emailError,messageId,createdAt,updatedAt);

@override
String toString() {
  return 'InvitationApi(id: $id, key: $key, link: $link, clientContactId: $clientContactId, vendorContactId: $vendorContactId, sentDate: $sentDate, viewedDate: $viewedDate, openedDate: $openedDate, emailStatus: $emailStatus, emailError: $emailError, messageId: $messageId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $InvitationApiCopyWith<$Res>  {
  factory $InvitationApiCopyWith(InvitationApi value, $Res Function(InvitationApi) _then) = _$InvitationApiCopyWithImpl;
@useResult
$Res call({
 String id, String key, String link,@JsonKey(name: 'client_contact_id') String clientContactId,@JsonKey(name: 'vendor_contact_id') String vendorContactId,@JsonKey(name: 'sent_date') String sentDate,@JsonKey(name: 'viewed_date') String viewedDate,@JsonKey(name: 'opened_date') String openedDate,@JsonKey(name: 'email_status') String emailStatus,@JsonKey(name: 'email_error') String emailError,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt
});




}
/// @nodoc
class _$InvitationApiCopyWithImpl<$Res>
    implements $InvitationApiCopyWith<$Res> {
  _$InvitationApiCopyWithImpl(this._self, this._then);

  final InvitationApi _self;
  final $Res Function(InvitationApi) _then;

/// Create a copy of InvitationApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? link = null,Object? clientContactId = null,Object? vendorContactId = null,Object? sentDate = null,Object? viewedDate = null,Object? openedDate = null,Object? emailStatus = null,Object? emailError = null,Object? messageId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,clientContactId: null == clientContactId ? _self.clientContactId : clientContactId // ignore: cast_nullable_to_non_nullable
as String,vendorContactId: null == vendorContactId ? _self.vendorContactId : vendorContactId // ignore: cast_nullable_to_non_nullable
as String,sentDate: null == sentDate ? _self.sentDate : sentDate // ignore: cast_nullable_to_non_nullable
as String,viewedDate: null == viewedDate ? _self.viewedDate : viewedDate // ignore: cast_nullable_to_non_nullable
as String,openedDate: null == openedDate ? _self.openedDate : openedDate // ignore: cast_nullable_to_non_nullable
as String,emailStatus: null == emailStatus ? _self.emailStatus : emailStatus // ignore: cast_nullable_to_non_nullable
as String,emailError: null == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitationApi].
extension InvitationApiPatterns on InvitationApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationApi value)  $default,){
final _that = this;
switch (_that) {
case _InvitationApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationApi value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String link, @JsonKey(name: 'client_contact_id')  String clientContactId, @JsonKey(name: 'vendor_contact_id')  String vendorContactId, @JsonKey(name: 'sent_date')  String sentDate, @JsonKey(name: 'viewed_date')  String viewedDate, @JsonKey(name: 'opened_date')  String openedDate, @JsonKey(name: 'email_status')  String emailStatus, @JsonKey(name: 'email_error')  String emailError, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationApi() when $default != null:
return $default(_that.id,_that.key,_that.link,_that.clientContactId,_that.vendorContactId,_that.sentDate,_that.viewedDate,_that.openedDate,_that.emailStatus,_that.emailError,_that.messageId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String link, @JsonKey(name: 'client_contact_id')  String clientContactId, @JsonKey(name: 'vendor_contact_id')  String vendorContactId, @JsonKey(name: 'sent_date')  String sentDate, @JsonKey(name: 'viewed_date')  String viewedDate, @JsonKey(name: 'opened_date')  String openedDate, @JsonKey(name: 'email_status')  String emailStatus, @JsonKey(name: 'email_error')  String emailError, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _InvitationApi():
return $default(_that.id,_that.key,_that.link,_that.clientContactId,_that.vendorContactId,_that.sentDate,_that.viewedDate,_that.openedDate,_that.emailStatus,_that.emailError,_that.messageId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String link, @JsonKey(name: 'client_contact_id')  String clientContactId, @JsonKey(name: 'vendor_contact_id')  String vendorContactId, @JsonKey(name: 'sent_date')  String sentDate, @JsonKey(name: 'viewed_date')  String viewedDate, @JsonKey(name: 'opened_date')  String openedDate, @JsonKey(name: 'email_status')  String emailStatus, @JsonKey(name: 'email_error')  String emailError, @JsonKey(name: 'message_id')  String messageId, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _InvitationApi() when $default != null:
return $default(_that.id,_that.key,_that.link,_that.clientContactId,_that.vendorContactId,_that.sentDate,_that.viewedDate,_that.openedDate,_that.emailStatus,_that.emailError,_that.messageId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationApi implements InvitationApi {
  const _InvitationApi({this.id = '', this.key = '', this.link = '', @JsonKey(name: 'client_contact_id') this.clientContactId = '', @JsonKey(name: 'vendor_contact_id') this.vendorContactId = '', @JsonKey(name: 'sent_date') this.sentDate = '', @JsonKey(name: 'viewed_date') this.viewedDate = '', @JsonKey(name: 'opened_date') this.openedDate = '', @JsonKey(name: 'email_status') this.emailStatus = '', @JsonKey(name: 'email_error') this.emailError = '', @JsonKey(name: 'message_id') this.messageId = '', @JsonKey(name: 'created_at') this.createdAt = 0, @JsonKey(name: 'updated_at') this.updatedAt = 0});
  factory _InvitationApi.fromJson(Map<String, dynamic> json) => _$InvitationApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String key;
@override@JsonKey() final  String link;
@override@JsonKey(name: 'client_contact_id') final  String clientContactId;
@override@JsonKey(name: 'vendor_contact_id') final  String vendorContactId;
@override@JsonKey(name: 'sent_date') final  String sentDate;
@override@JsonKey(name: 'viewed_date') final  String viewedDate;
@override@JsonKey(name: 'opened_date') final  String openedDate;
@override@JsonKey(name: 'email_status') final  String emailStatus;
@override@JsonKey(name: 'email_error') final  String emailError;
@override@JsonKey(name: 'message_id') final  String messageId;
@override@JsonKey(name: 'created_at') final  int createdAt;
@override@JsonKey(name: 'updated_at') final  int updatedAt;

/// Create a copy of InvitationApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationApiCopyWith<_InvitationApi> get copyWith => __$InvitationApiCopyWithImpl<_InvitationApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationApi&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.link, link) || other.link == link)&&(identical(other.clientContactId, clientContactId) || other.clientContactId == clientContactId)&&(identical(other.vendorContactId, vendorContactId) || other.vendorContactId == vendorContactId)&&(identical(other.sentDate, sentDate) || other.sentDate == sentDate)&&(identical(other.viewedDate, viewedDate) || other.viewedDate == viewedDate)&&(identical(other.openedDate, openedDate) || other.openedDate == openedDate)&&(identical(other.emailStatus, emailStatus) || other.emailStatus == emailStatus)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,link,clientContactId,vendorContactId,sentDate,viewedDate,openedDate,emailStatus,emailError,messageId,createdAt,updatedAt);

@override
String toString() {
  return 'InvitationApi(id: $id, key: $key, link: $link, clientContactId: $clientContactId, vendorContactId: $vendorContactId, sentDate: $sentDate, viewedDate: $viewedDate, openedDate: $openedDate, emailStatus: $emailStatus, emailError: $emailError, messageId: $messageId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$InvitationApiCopyWith<$Res> implements $InvitationApiCopyWith<$Res> {
  factory _$InvitationApiCopyWith(_InvitationApi value, $Res Function(_InvitationApi) _then) = __$InvitationApiCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String link,@JsonKey(name: 'client_contact_id') String clientContactId,@JsonKey(name: 'vendor_contact_id') String vendorContactId,@JsonKey(name: 'sent_date') String sentDate,@JsonKey(name: 'viewed_date') String viewedDate,@JsonKey(name: 'opened_date') String openedDate,@JsonKey(name: 'email_status') String emailStatus,@JsonKey(name: 'email_error') String emailError,@JsonKey(name: 'message_id') String messageId,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt
});




}
/// @nodoc
class __$InvitationApiCopyWithImpl<$Res>
    implements _$InvitationApiCopyWith<$Res> {
  __$InvitationApiCopyWithImpl(this._self, this._then);

  final _InvitationApi _self;
  final $Res Function(_InvitationApi) _then;

/// Create a copy of InvitationApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? link = null,Object? clientContactId = null,Object? vendorContactId = null,Object? sentDate = null,Object? viewedDate = null,Object? openedDate = null,Object? emailStatus = null,Object? emailError = null,Object? messageId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_InvitationApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,clientContactId: null == clientContactId ? _self.clientContactId : clientContactId // ignore: cast_nullable_to_non_nullable
as String,vendorContactId: null == vendorContactId ? _self.vendorContactId : vendorContactId // ignore: cast_nullable_to_non_nullable
as String,sentDate: null == sentDate ? _self.sentDate : sentDate // ignore: cast_nullable_to_non_nullable
as String,viewedDate: null == viewedDate ? _self.viewedDate : viewedDate // ignore: cast_nullable_to_non_nullable
as String,openedDate: null == openedDate ? _self.openedDate : openedDate // ignore: cast_nullable_to_non_nullable
as String,emailStatus: null == emailStatus ? _self.emailStatus : emailStatus // ignore: cast_nullable_to_non_nullable
as String,emailError: null == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
