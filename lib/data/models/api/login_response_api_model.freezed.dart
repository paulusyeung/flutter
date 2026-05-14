// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_response_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginResponseApi {

 List<UserCompanyApi> get data;@JsonKey(name: 'static') Map<String, dynamic> get staticData;
/// Create a copy of LoginResponseApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginResponseApiCopyWith<LoginResponseApi> get copyWith => _$LoginResponseApiCopyWithImpl<LoginResponseApi>(this as LoginResponseApi, _$identity);

  /// Serializes this LoginResponseApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginResponseApi&&const DeepCollectionEquality().equals(other.data, data)&&const DeepCollectionEquality().equals(other.staticData, staticData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),const DeepCollectionEquality().hash(staticData));

@override
String toString() {
  return 'LoginResponseApi(data: $data, staticData: $staticData)';
}


}

/// @nodoc
abstract mixin class $LoginResponseApiCopyWith<$Res>  {
  factory $LoginResponseApiCopyWith(LoginResponseApi value, $Res Function(LoginResponseApi) _then) = _$LoginResponseApiCopyWithImpl;
@useResult
$Res call({
 List<UserCompanyApi> data,@JsonKey(name: 'static') Map<String, dynamic> staticData
});




}
/// @nodoc
class _$LoginResponseApiCopyWithImpl<$Res>
    implements $LoginResponseApiCopyWith<$Res> {
  _$LoginResponseApiCopyWithImpl(this._self, this._then);

  final LoginResponseApi _self;
  final $Res Function(LoginResponseApi) _then;

/// Create a copy of LoginResponseApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? staticData = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<UserCompanyApi>,staticData: null == staticData ? _self.staticData : staticData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginResponseApi].
extension LoginResponseApiPatterns on LoginResponseApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginResponseApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginResponseApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginResponseApi value)  $default,){
final _that = this;
switch (_that) {
case _LoginResponseApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginResponseApi value)?  $default,){
final _that = this;
switch (_that) {
case _LoginResponseApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserCompanyApi> data, @JsonKey(name: 'static')  Map<String, dynamic> staticData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginResponseApi() when $default != null:
return $default(_that.data,_that.staticData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserCompanyApi> data, @JsonKey(name: 'static')  Map<String, dynamic> staticData)  $default,) {final _that = this;
switch (_that) {
case _LoginResponseApi():
return $default(_that.data,_that.staticData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserCompanyApi> data, @JsonKey(name: 'static')  Map<String, dynamic> staticData)?  $default,) {final _that = this;
switch (_that) {
case _LoginResponseApi() when $default != null:
return $default(_that.data,_that.staticData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginResponseApi implements LoginResponseApi {
  const _LoginResponseApi({final  List<UserCompanyApi> data = const <UserCompanyApi>[], @JsonKey(name: 'static') final  Map<String, dynamic> staticData = const <String, dynamic>{}}): _data = data,_staticData = staticData;
  factory _LoginResponseApi.fromJson(Map<String, dynamic> json) => _$LoginResponseApiFromJson(json);

 final  List<UserCompanyApi> _data;
@override@JsonKey() List<UserCompanyApi> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

 final  Map<String, dynamic> _staticData;
@override@JsonKey(name: 'static') Map<String, dynamic> get staticData {
  if (_staticData is EqualUnmodifiableMapView) return _staticData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_staticData);
}


/// Create a copy of LoginResponseApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginResponseApiCopyWith<_LoginResponseApi> get copyWith => __$LoginResponseApiCopyWithImpl<_LoginResponseApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginResponseApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginResponseApi&&const DeepCollectionEquality().equals(other._data, _data)&&const DeepCollectionEquality().equals(other._staticData, _staticData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),const DeepCollectionEquality().hash(_staticData));

@override
String toString() {
  return 'LoginResponseApi(data: $data, staticData: $staticData)';
}


}

/// @nodoc
abstract mixin class _$LoginResponseApiCopyWith<$Res> implements $LoginResponseApiCopyWith<$Res> {
  factory _$LoginResponseApiCopyWith(_LoginResponseApi value, $Res Function(_LoginResponseApi) _then) = __$LoginResponseApiCopyWithImpl;
@override @useResult
$Res call({
 List<UserCompanyApi> data,@JsonKey(name: 'static') Map<String, dynamic> staticData
});




}
/// @nodoc
class __$LoginResponseApiCopyWithImpl<$Res>
    implements _$LoginResponseApiCopyWith<$Res> {
  __$LoginResponseApiCopyWithImpl(this._self, this._then);

  final _LoginResponseApi _self;
  final $Res Function(_LoginResponseApi) _then;

/// Create a copy of LoginResponseApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? staticData = null,}) {
  return _then(_LoginResponseApi(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<UserCompanyApi>,staticData: null == staticData ? _self._staticData : staticData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$UserCompanyApi {

@JsonKey(name: 'is_admin') bool get isAdmin;@JsonKey(name: 'is_owner') bool get isOwner; String get permissions;@JsonKey(name: 'permissions_updated_at') int get permissionsUpdatedAt; CompanyEnvelopeApi get company; TokenApi get token; AccountEnvelopeApi get account; Map<String, dynamic> get settings;@JsonKey(name: 'user') UserSummaryApi get user;
/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCompanyApiCopyWith<UserCompanyApi> get copyWith => _$UserCompanyApiCopyWithImpl<UserCompanyApi>(this as UserCompanyApi, _$identity);

  /// Serializes this UserCompanyApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCompanyApi&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.permissionsUpdatedAt, permissionsUpdatedAt) || other.permissionsUpdatedAt == permissionsUpdatedAt)&&(identical(other.company, company) || other.company == company)&&(identical(other.token, token) || other.token == token)&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other.settings, settings)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isAdmin,isOwner,permissions,permissionsUpdatedAt,company,token,account,const DeepCollectionEquality().hash(settings),user);

@override
String toString() {
  return 'UserCompanyApi(isAdmin: $isAdmin, isOwner: $isOwner, permissions: $permissions, permissionsUpdatedAt: $permissionsUpdatedAt, company: $company, token: $token, account: $account, settings: $settings, user: $user)';
}


}

/// @nodoc
abstract mixin class $UserCompanyApiCopyWith<$Res>  {
  factory $UserCompanyApiCopyWith(UserCompanyApi value, $Res Function(UserCompanyApi) _then) = _$UserCompanyApiCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'is_owner') bool isOwner, String permissions,@JsonKey(name: 'permissions_updated_at') int permissionsUpdatedAt, CompanyEnvelopeApi company, TokenApi token, AccountEnvelopeApi account, Map<String, dynamic> settings,@JsonKey(name: 'user') UserSummaryApi user
});


$CompanyEnvelopeApiCopyWith<$Res> get company;$TokenApiCopyWith<$Res> get token;$AccountEnvelopeApiCopyWith<$Res> get account;$UserSummaryApiCopyWith<$Res> get user;

}
/// @nodoc
class _$UserCompanyApiCopyWithImpl<$Res>
    implements $UserCompanyApiCopyWith<$Res> {
  _$UserCompanyApiCopyWithImpl(this._self, this._then);

  final UserCompanyApi _self;
  final $Res Function(UserCompanyApi) _then;

/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAdmin = null,Object? isOwner = null,Object? permissions = null,Object? permissionsUpdatedAt = null,Object? company = null,Object? token = null,Object? account = null,Object? settings = null,Object? user = null,}) {
  return _then(_self.copyWith(
isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as String,permissionsUpdatedAt: null == permissionsUpdatedAt ? _self.permissionsUpdatedAt : permissionsUpdatedAt // ignore: cast_nullable_to_non_nullable
as int,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as CompanyEnvelopeApi,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as TokenApi,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountEnvelopeApi,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserSummaryApi,
  ));
}
/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanyEnvelopeApiCopyWith<$Res> get company {
  
  return $CompanyEnvelopeApiCopyWith<$Res>(_self.company, (value) {
    return _then(_self.copyWith(company: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenApiCopyWith<$Res> get token {
  
  return $TokenApiCopyWith<$Res>(_self.token, (value) {
    return _then(_self.copyWith(token: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountEnvelopeApiCopyWith<$Res> get account {
  
  return $AccountEnvelopeApiCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryApiCopyWith<$Res> get user {
  
  return $UserSummaryApiCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserCompanyApi].
extension UserCompanyApiPatterns on UserCompanyApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCompanyApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCompanyApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCompanyApi value)  $default,){
final _that = this;
switch (_that) {
case _UserCompanyApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCompanyApi value)?  $default,){
final _that = this;
switch (_that) {
case _UserCompanyApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_owner')  bool isOwner,  String permissions, @JsonKey(name: 'permissions_updated_at')  int permissionsUpdatedAt,  CompanyEnvelopeApi company,  TokenApi token,  AccountEnvelopeApi account,  Map<String, dynamic> settings, @JsonKey(name: 'user')  UserSummaryApi user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCompanyApi() when $default != null:
return $default(_that.isAdmin,_that.isOwner,_that.permissions,_that.permissionsUpdatedAt,_that.company,_that.token,_that.account,_that.settings,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_owner')  bool isOwner,  String permissions, @JsonKey(name: 'permissions_updated_at')  int permissionsUpdatedAt,  CompanyEnvelopeApi company,  TokenApi token,  AccountEnvelopeApi account,  Map<String, dynamic> settings, @JsonKey(name: 'user')  UserSummaryApi user)  $default,) {final _that = this;
switch (_that) {
case _UserCompanyApi():
return $default(_that.isAdmin,_that.isOwner,_that.permissions,_that.permissionsUpdatedAt,_that.company,_that.token,_that.account,_that.settings,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_owner')  bool isOwner,  String permissions, @JsonKey(name: 'permissions_updated_at')  int permissionsUpdatedAt,  CompanyEnvelopeApi company,  TokenApi token,  AccountEnvelopeApi account,  Map<String, dynamic> settings, @JsonKey(name: 'user')  UserSummaryApi user)?  $default,) {final _that = this;
switch (_that) {
case _UserCompanyApi() when $default != null:
return $default(_that.isAdmin,_that.isOwner,_that.permissions,_that.permissionsUpdatedAt,_that.company,_that.token,_that.account,_that.settings,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserCompanyApi implements UserCompanyApi {
  const _UserCompanyApi({@JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'is_owner') this.isOwner = false, this.permissions = '', @JsonKey(name: 'permissions_updated_at') this.permissionsUpdatedAt = 0, required this.company, required this.token, required this.account, final  Map<String, dynamic> settings = const <String, dynamic>{}, @JsonKey(name: 'user') this.user = const UserSummaryApi()}): _settings = settings;
  factory _UserCompanyApi.fromJson(Map<String, dynamic> json) => _$UserCompanyApiFromJson(json);

@override@JsonKey(name: 'is_admin') final  bool isAdmin;
@override@JsonKey(name: 'is_owner') final  bool isOwner;
@override@JsonKey() final  String permissions;
@override@JsonKey(name: 'permissions_updated_at') final  int permissionsUpdatedAt;
@override final  CompanyEnvelopeApi company;
@override final  TokenApi token;
@override final  AccountEnvelopeApi account;
 final  Map<String, dynamic> _settings;
@override@JsonKey() Map<String, dynamic> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}

@override@JsonKey(name: 'user') final  UserSummaryApi user;

/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCompanyApiCopyWith<_UserCompanyApi> get copyWith => __$UserCompanyApiCopyWithImpl<_UserCompanyApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCompanyApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCompanyApi&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.permissionsUpdatedAt, permissionsUpdatedAt) || other.permissionsUpdatedAt == permissionsUpdatedAt)&&(identical(other.company, company) || other.company == company)&&(identical(other.token, token) || other.token == token)&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other._settings, _settings)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isAdmin,isOwner,permissions,permissionsUpdatedAt,company,token,account,const DeepCollectionEquality().hash(_settings),user);

@override
String toString() {
  return 'UserCompanyApi(isAdmin: $isAdmin, isOwner: $isOwner, permissions: $permissions, permissionsUpdatedAt: $permissionsUpdatedAt, company: $company, token: $token, account: $account, settings: $settings, user: $user)';
}


}

/// @nodoc
abstract mixin class _$UserCompanyApiCopyWith<$Res> implements $UserCompanyApiCopyWith<$Res> {
  factory _$UserCompanyApiCopyWith(_UserCompanyApi value, $Res Function(_UserCompanyApi) _then) = __$UserCompanyApiCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'is_owner') bool isOwner, String permissions,@JsonKey(name: 'permissions_updated_at') int permissionsUpdatedAt, CompanyEnvelopeApi company, TokenApi token, AccountEnvelopeApi account, Map<String, dynamic> settings,@JsonKey(name: 'user') UserSummaryApi user
});


@override $CompanyEnvelopeApiCopyWith<$Res> get company;@override $TokenApiCopyWith<$Res> get token;@override $AccountEnvelopeApiCopyWith<$Res> get account;@override $UserSummaryApiCopyWith<$Res> get user;

}
/// @nodoc
class __$UserCompanyApiCopyWithImpl<$Res>
    implements _$UserCompanyApiCopyWith<$Res> {
  __$UserCompanyApiCopyWithImpl(this._self, this._then);

  final _UserCompanyApi _self;
  final $Res Function(_UserCompanyApi) _then;

/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAdmin = null,Object? isOwner = null,Object? permissions = null,Object? permissionsUpdatedAt = null,Object? company = null,Object? token = null,Object? account = null,Object? settings = null,Object? user = null,}) {
  return _then(_UserCompanyApi(
isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as String,permissionsUpdatedAt: null == permissionsUpdatedAt ? _self.permissionsUpdatedAt : permissionsUpdatedAt // ignore: cast_nullable_to_non_nullable
as int,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as CompanyEnvelopeApi,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as TokenApi,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountEnvelopeApi,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserSummaryApi,
  ));
}

/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanyEnvelopeApiCopyWith<$Res> get company {
  
  return $CompanyEnvelopeApiCopyWith<$Res>(_self.company, (value) {
    return _then(_self.copyWith(company: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenApiCopyWith<$Res> get token {
  
  return $TokenApiCopyWith<$Res>(_self.token, (value) {
    return _then(_self.copyWith(token: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountEnvelopeApiCopyWith<$Res> get account {
  
  return $AccountEnvelopeApiCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}/// Create a copy of UserCompanyApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryApiCopyWith<$Res> get user {
  
  return $UserSummaryApiCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$UserSummaryApi {

 String get id;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName;@JsonKey(name: 'email') String get email;@JsonKey(name: 'phone') String get phone;@JsonKey(name: 'signature') String get signature;@JsonKey(name: 'language_id') String get languageId;@JsonKey(name: 'custom_value1') String get customValue1;@JsonKey(name: 'custom_value2') String get customValue2;@JsonKey(name: 'custom_value3') String get customValue3;@JsonKey(name: 'custom_value4') String get customValue4;@JsonKey(name: 'oauth_provider_id') String get oauthProviderId;// Server sends a truthy string ("true"/"1") OR a bool depending on the
// endpoint, so the JSON converter normalizes to a plain bool.
@JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson) bool get google2faSecret;@JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson) bool get verifiedPhoneNumber;
/// Create a copy of UserSummaryApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSummaryApiCopyWith<UserSummaryApi> get copyWith => _$UserSummaryApiCopyWithImpl<UserSummaryApi>(this as UserSummaryApi, _$identity);

  /// Serializes this UserSummaryApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSummaryApi&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.languageId, languageId) || other.languageId == languageId)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.oauthProviderId, oauthProviderId) || other.oauthProviderId == oauthProviderId)&&(identical(other.google2faSecret, google2faSecret) || other.google2faSecret == google2faSecret)&&(identical(other.verifiedPhoneNumber, verifiedPhoneNumber) || other.verifiedPhoneNumber == verifiedPhoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName,email,phone,signature,languageId,customValue1,customValue2,customValue3,customValue4,oauthProviderId,google2faSecret,verifiedPhoneNumber);

@override
String toString() {
  return 'UserSummaryApi(id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, signature: $signature, languageId: $languageId, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, oauthProviderId: $oauthProviderId, google2faSecret: $google2faSecret, verifiedPhoneNumber: $verifiedPhoneNumber)';
}


}

/// @nodoc
abstract mixin class $UserSummaryApiCopyWith<$Res>  {
  factory $UserSummaryApiCopyWith(UserSummaryApi value, $Res Function(UserSummaryApi) _then) = _$UserSummaryApiCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName,@JsonKey(name: 'email') String email,@JsonKey(name: 'phone') String phone,@JsonKey(name: 'signature') String signature,@JsonKey(name: 'language_id') String languageId,@JsonKey(name: 'custom_value1') String customValue1,@JsonKey(name: 'custom_value2') String customValue2,@JsonKey(name: 'custom_value3') String customValue3,@JsonKey(name: 'custom_value4') String customValue4,@JsonKey(name: 'oauth_provider_id') String oauthProviderId,@JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson) bool google2faSecret,@JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson) bool verifiedPhoneNumber
});




}
/// @nodoc
class _$UserSummaryApiCopyWithImpl<$Res>
    implements $UserSummaryApiCopyWith<$Res> {
  _$UserSummaryApiCopyWithImpl(this._self, this._then);

  final UserSummaryApi _self;
  final $Res Function(UserSummaryApi) _then;

/// Create a copy of UserSummaryApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = null,Object? signature = null,Object? languageId = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? oauthProviderId = null,Object? google2faSecret = null,Object? verifiedPhoneNumber = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,languageId: null == languageId ? _self.languageId : languageId // ignore: cast_nullable_to_non_nullable
as String,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,oauthProviderId: null == oauthProviderId ? _self.oauthProviderId : oauthProviderId // ignore: cast_nullable_to_non_nullable
as String,google2faSecret: null == google2faSecret ? _self.google2faSecret : google2faSecret // ignore: cast_nullable_to_non_nullable
as bool,verifiedPhoneNumber: null == verifiedPhoneNumber ? _self.verifiedPhoneNumber : verifiedPhoneNumber // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSummaryApi].
extension UserSummaryApiPatterns on UserSummaryApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSummaryApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSummaryApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSummaryApi value)  $default,){
final _that = this;
switch (_that) {
case _UserSummaryApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSummaryApi value)?  $default,){
final _that = this;
switch (_that) {
case _UserSummaryApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'phone')  String phone, @JsonKey(name: 'signature')  String signature, @JsonKey(name: 'language_id')  String languageId, @JsonKey(name: 'custom_value1')  String customValue1, @JsonKey(name: 'custom_value2')  String customValue2, @JsonKey(name: 'custom_value3')  String customValue3, @JsonKey(name: 'custom_value4')  String customValue4, @JsonKey(name: 'oauth_provider_id')  String oauthProviderId, @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)  bool google2faSecret, @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)  bool verifiedPhoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSummaryApi() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.signature,_that.languageId,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.oauthProviderId,_that.google2faSecret,_that.verifiedPhoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'phone')  String phone, @JsonKey(name: 'signature')  String signature, @JsonKey(name: 'language_id')  String languageId, @JsonKey(name: 'custom_value1')  String customValue1, @JsonKey(name: 'custom_value2')  String customValue2, @JsonKey(name: 'custom_value3')  String customValue3, @JsonKey(name: 'custom_value4')  String customValue4, @JsonKey(name: 'oauth_provider_id')  String oauthProviderId, @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)  bool google2faSecret, @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)  bool verifiedPhoneNumber)  $default,) {final _that = this;
switch (_that) {
case _UserSummaryApi():
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.signature,_that.languageId,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.oauthProviderId,_that.google2faSecret,_that.verifiedPhoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'phone')  String phone, @JsonKey(name: 'signature')  String signature, @JsonKey(name: 'language_id')  String languageId, @JsonKey(name: 'custom_value1')  String customValue1, @JsonKey(name: 'custom_value2')  String customValue2, @JsonKey(name: 'custom_value3')  String customValue3, @JsonKey(name: 'custom_value4')  String customValue4, @JsonKey(name: 'oauth_provider_id')  String oauthProviderId, @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)  bool google2faSecret, @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)  bool verifiedPhoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _UserSummaryApi() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.signature,_that.languageId,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.oauthProviderId,_that.google2faSecret,_that.verifiedPhoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSummaryApi implements UserSummaryApi {
  const _UserSummaryApi({this.id = '', @JsonKey(name: 'first_name') this.firstName = '', @JsonKey(name: 'last_name') this.lastName = '', @JsonKey(name: 'email') this.email = '', @JsonKey(name: 'phone') this.phone = '', @JsonKey(name: 'signature') this.signature = '', @JsonKey(name: 'language_id') this.languageId = '', @JsonKey(name: 'custom_value1') this.customValue1 = '', @JsonKey(name: 'custom_value2') this.customValue2 = '', @JsonKey(name: 'custom_value3') this.customValue3 = '', @JsonKey(name: 'custom_value4') this.customValue4 = '', @JsonKey(name: 'oauth_provider_id') this.oauthProviderId = '', @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson) this.google2faSecret = false, @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson) this.verifiedPhoneNumber = false});
  factory _UserSummaryApi.fromJson(Map<String, dynamic> json) => _$UserSummaryApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
@override@JsonKey(name: 'email') final  String email;
@override@JsonKey(name: 'phone') final  String phone;
@override@JsonKey(name: 'signature') final  String signature;
@override@JsonKey(name: 'language_id') final  String languageId;
@override@JsonKey(name: 'custom_value1') final  String customValue1;
@override@JsonKey(name: 'custom_value2') final  String customValue2;
@override@JsonKey(name: 'custom_value3') final  String customValue3;
@override@JsonKey(name: 'custom_value4') final  String customValue4;
@override@JsonKey(name: 'oauth_provider_id') final  String oauthProviderId;
// Server sends a truthy string ("true"/"1") OR a bool depending on the
// endpoint, so the JSON converter normalizes to a plain bool.
@override@JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson) final  bool google2faSecret;
@override@JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson) final  bool verifiedPhoneNumber;

/// Create a copy of UserSummaryApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSummaryApiCopyWith<_UserSummaryApi> get copyWith => __$UserSummaryApiCopyWithImpl<_UserSummaryApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSummaryApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSummaryApi&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.languageId, languageId) || other.languageId == languageId)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.oauthProviderId, oauthProviderId) || other.oauthProviderId == oauthProviderId)&&(identical(other.google2faSecret, google2faSecret) || other.google2faSecret == google2faSecret)&&(identical(other.verifiedPhoneNumber, verifiedPhoneNumber) || other.verifiedPhoneNumber == verifiedPhoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName,email,phone,signature,languageId,customValue1,customValue2,customValue3,customValue4,oauthProviderId,google2faSecret,verifiedPhoneNumber);

@override
String toString() {
  return 'UserSummaryApi(id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, signature: $signature, languageId: $languageId, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, oauthProviderId: $oauthProviderId, google2faSecret: $google2faSecret, verifiedPhoneNumber: $verifiedPhoneNumber)';
}


}

/// @nodoc
abstract mixin class _$UserSummaryApiCopyWith<$Res> implements $UserSummaryApiCopyWith<$Res> {
  factory _$UserSummaryApiCopyWith(_UserSummaryApi value, $Res Function(_UserSummaryApi) _then) = __$UserSummaryApiCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName,@JsonKey(name: 'email') String email,@JsonKey(name: 'phone') String phone,@JsonKey(name: 'signature') String signature,@JsonKey(name: 'language_id') String languageId,@JsonKey(name: 'custom_value1') String customValue1,@JsonKey(name: 'custom_value2') String customValue2,@JsonKey(name: 'custom_value3') String customValue3,@JsonKey(name: 'custom_value4') String customValue4,@JsonKey(name: 'oauth_provider_id') String oauthProviderId,@JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson) bool google2faSecret,@JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson) bool verifiedPhoneNumber
});




}
/// @nodoc
class __$UserSummaryApiCopyWithImpl<$Res>
    implements _$UserSummaryApiCopyWith<$Res> {
  __$UserSummaryApiCopyWithImpl(this._self, this._then);

  final _UserSummaryApi _self;
  final $Res Function(_UserSummaryApi) _then;

/// Create a copy of UserSummaryApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = null,Object? signature = null,Object? languageId = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? oauthProviderId = null,Object? google2faSecret = null,Object? verifiedPhoneNumber = null,}) {
  return _then(_UserSummaryApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,languageId: null == languageId ? _self.languageId : languageId // ignore: cast_nullable_to_non_nullable
as String,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,oauthProviderId: null == oauthProviderId ? _self.oauthProviderId : oauthProviderId // ignore: cast_nullable_to_non_nullable
as String,google2faSecret: null == google2faSecret ? _self.google2faSecret : google2faSecret // ignore: cast_nullable_to_non_nullable
as bool,verifiedPhoneNumber: null == verifiedPhoneNumber ? _self.verifiedPhoneNumber : verifiedPhoneNumber // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CompanyEnvelopeApi {

 String get id;@JsonKey(name: 'display_name') String get displayName; String get name;@JsonKey(name: 'company_key') String get companyKey;@JsonKey(name: 'custom_fields') Map<String, String> get customFields;@JsonKey(name: 'size_id') String get sizeId;@JsonKey(name: 'industry_id') String get industryId;@JsonKey(name: 'legal_entity_id') int get legalEntityId;@JsonKey(name: 'enabled_modules') int get enabledModules;// `settings` stays as a raw map — every key the server sends is
// preserved verbatim through the round-trip. Strong-typing here would
// drop unknown keys at fromJson/toJson, silently corrupting fields
// we haven't modeled yet. The repository builds the typed view on
// demand via `CompanySettingsApi.fromJson`.
 Map<String, dynamic> get settings;// Bundled reference arrays. `/refresh?first_load=true` delivers these
// alongside the company so the matching repos don't need a separate
// round-trip on first paint. The pattern matches CLAUDE.md § Data
// loading — bundled vs per-entity. Add new bundles here as more
// settings screens come online (tax_rates, designs, …).
@JsonKey(name: 'task_statuses') List<TaskStatusApi> get taskStatuses;@JsonKey(name: 'company_gateways') List<CompanyGatewayApi> get companyGateways;@JsonKey(name: 'payment_terms') List<PaymentTermApi> get paymentTerms;@JsonKey(name: 'tax_rates') List<TaxRateApi> get taxRates;@JsonKey(name: 'expense_categories') List<ExpenseCategoryApi> get expenseCategories;// Top-level tax fields on the envelope, mirroring `CompanyApi`. Settings
// → Tax Settings writes these via `host.updateCompany(...)`.
@JsonKey(name: 'enabled_tax_rates') int get enabledTaxRates;@JsonKey(name: 'enabled_item_tax_rates') int get enabledItemTaxRates;@JsonKey(name: 'enabled_expense_tax_rates') int get enabledExpenseTaxRates;@JsonKey(name: 'calculate_taxes') bool get calculateTaxes;@JsonKey(name: 'tax_data') TaxConfigApi? get taxData;// Top-level product configuration on the envelope, mirroring `CompanyApi`.
// Settings → Product Settings writes these via `vm.updateCompany(...)`;
// the login envelope persists them straight into the `companies` Drift
// table so they're available offline before the first refresh.
@JsonKey(name: 'track_inventory') bool get trackInventory;@JsonKey(name: 'stock_notification') bool get stockNotification;@JsonKey(name: 'inventory_notification_threshold') int get inventoryNotificationThreshold;@JsonKey(name: 'enable_product_discount') bool get enableProductDiscount;@JsonKey(name: 'enable_product_cost') bool get enableProductCost;@JsonKey(name: 'enable_product_quantity') bool get enableProductQuantity;@JsonKey(name: 'default_quantity') bool get defaultQuantity;@JsonKey(name: 'show_product_details') bool get showProductDetails;@JsonKey(name: 'fill_products') bool get fillProducts;@JsonKey(name: 'update_products') bool get updateProducts;@JsonKey(name: 'convert_products') bool get convertProducts;@JsonKey(name: 'convert_rate_to_client') bool get convertRateToClient;
/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyEnvelopeApiCopyWith<CompanyEnvelopeApi> get copyWith => _$CompanyEnvelopeApiCopyWithImpl<CompanyEnvelopeApi>(this as CompanyEnvelopeApi, _$identity);

  /// Serializes this CompanyEnvelopeApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyEnvelopeApi&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&const DeepCollectionEquality().equals(other.settings, settings)&&const DeepCollectionEquality().equals(other.taskStatuses, taskStatuses)&&const DeepCollectionEquality().equals(other.companyGateways, companyGateways)&&const DeepCollectionEquality().equals(other.paymentTerms, paymentTerms)&&const DeepCollectionEquality().equals(other.taxRates, taxRates)&&const DeepCollectionEquality().equals(other.expenseCategories, expenseCategories)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,const DeepCollectionEquality().hash(customFields),sizeId,industryId,legalEntityId,enabledModules,const DeepCollectionEquality().hash(settings),const DeepCollectionEquality().hash(taskStatuses),const DeepCollectionEquality().hash(companyGateways),const DeepCollectionEquality().hash(paymentTerms),const DeepCollectionEquality().hash(taxRates),const DeepCollectionEquality().hash(expenseCategories),enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient]);

@override
String toString() {
  return 'CompanyEnvelopeApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, customFields: $customFields, sizeId: $sizeId, industryId: $industryId, legalEntityId: $legalEntityId, enabledModules: $enabledModules, settings: $settings, taskStatuses: $taskStatuses, companyGateways: $companyGateways, paymentTerms: $paymentTerms, taxRates: $taxRates, expenseCategories: $expenseCategories, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient)';
}


}

/// @nodoc
abstract mixin class $CompanyEnvelopeApiCopyWith<$Res>  {
  factory $CompanyEnvelopeApiCopyWith(CompanyEnvelopeApi value, $Res Function(CompanyEnvelopeApi) _then) = _$CompanyEnvelopeApiCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String displayName, String name,@JsonKey(name: 'company_key') String companyKey,@JsonKey(name: 'custom_fields') Map<String, String> customFields,@JsonKey(name: 'size_id') String sizeId,@JsonKey(name: 'industry_id') String industryId,@JsonKey(name: 'legal_entity_id') int legalEntityId,@JsonKey(name: 'enabled_modules') int enabledModules, Map<String, dynamic> settings,@JsonKey(name: 'task_statuses') List<TaskStatusApi> taskStatuses,@JsonKey(name: 'company_gateways') List<CompanyGatewayApi> companyGateways,@JsonKey(name: 'payment_terms') List<PaymentTermApi> paymentTerms,@JsonKey(name: 'tax_rates') List<TaxRateApi> taxRates,@JsonKey(name: 'expense_categories') List<ExpenseCategoryApi> expenseCategories,@JsonKey(name: 'enabled_tax_rates') int enabledTaxRates,@JsonKey(name: 'enabled_item_tax_rates') int enabledItemTaxRates,@JsonKey(name: 'enabled_expense_tax_rates') int enabledExpenseTaxRates,@JsonKey(name: 'calculate_taxes') bool calculateTaxes,@JsonKey(name: 'tax_data') TaxConfigApi? taxData,@JsonKey(name: 'track_inventory') bool trackInventory,@JsonKey(name: 'stock_notification') bool stockNotification,@JsonKey(name: 'inventory_notification_threshold') int inventoryNotificationThreshold,@JsonKey(name: 'enable_product_discount') bool enableProductDiscount,@JsonKey(name: 'enable_product_cost') bool enableProductCost,@JsonKey(name: 'enable_product_quantity') bool enableProductQuantity,@JsonKey(name: 'default_quantity') bool defaultQuantity,@JsonKey(name: 'show_product_details') bool showProductDetails,@JsonKey(name: 'fill_products') bool fillProducts,@JsonKey(name: 'update_products') bool updateProducts,@JsonKey(name: 'convert_products') bool convertProducts,@JsonKey(name: 'convert_rate_to_client') bool convertRateToClient
});


$TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class _$CompanyEnvelopeApiCopyWithImpl<$Res>
    implements $CompanyEnvelopeApiCopyWith<$Res> {
  _$CompanyEnvelopeApiCopyWithImpl(this._self, this._then);

  final CompanyEnvelopeApi _self;
  final $Res Function(CompanyEnvelopeApi) _then;

/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? customFields = null,Object? sizeId = null,Object? industryId = null,Object? legalEntityId = null,Object? enabledModules = null,Object? settings = null,Object? taskStatuses = null,Object? companyGateways = null,Object? paymentTerms = null,Object? taxRates = null,Object? expenseCategories = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,taskStatuses: null == taskStatuses ? _self.taskStatuses : taskStatuses // ignore: cast_nullable_to_non_nullable
as List<TaskStatusApi>,companyGateways: null == companyGateways ? _self.companyGateways : companyGateways // ignore: cast_nullable_to_non_nullable
as List<CompanyGatewayApi>,paymentTerms: null == paymentTerms ? _self.paymentTerms : paymentTerms // ignore: cast_nullable_to_non_nullable
as List<PaymentTermApi>,taxRates: null == taxRates ? _self.taxRates : taxRates // ignore: cast_nullable_to_non_nullable
as List<TaxRateApi>,expenseCategories: null == expenseCategories ? _self.expenseCategories : expenseCategories // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategoryApi>,enabledTaxRates: null == enabledTaxRates ? _self.enabledTaxRates : enabledTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledItemTaxRates: null == enabledItemTaxRates ? _self.enabledItemTaxRates : enabledItemTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledExpenseTaxRates: null == enabledExpenseTaxRates ? _self.enabledExpenseTaxRates : enabledExpenseTaxRates // ignore: cast_nullable_to_non_nullable
as int,calculateTaxes: null == calculateTaxes ? _self.calculateTaxes : calculateTaxes // ignore: cast_nullable_to_non_nullable
as bool,taxData: freezed == taxData ? _self.taxData : taxData // ignore: cast_nullable_to_non_nullable
as TaxConfigApi?,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockNotification: null == stockNotification ? _self.stockNotification : stockNotification // ignore: cast_nullable_to_non_nullable
as bool,inventoryNotificationThreshold: null == inventoryNotificationThreshold ? _self.inventoryNotificationThreshold : inventoryNotificationThreshold // ignore: cast_nullable_to_non_nullable
as int,enableProductDiscount: null == enableProductDiscount ? _self.enableProductDiscount : enableProductDiscount // ignore: cast_nullable_to_non_nullable
as bool,enableProductCost: null == enableProductCost ? _self.enableProductCost : enableProductCost // ignore: cast_nullable_to_non_nullable
as bool,enableProductQuantity: null == enableProductQuantity ? _self.enableProductQuantity : enableProductQuantity // ignore: cast_nullable_to_non_nullable
as bool,defaultQuantity: null == defaultQuantity ? _self.defaultQuantity : defaultQuantity // ignore: cast_nullable_to_non_nullable
as bool,showProductDetails: null == showProductDetails ? _self.showProductDetails : showProductDetails // ignore: cast_nullable_to_non_nullable
as bool,fillProducts: null == fillProducts ? _self.fillProducts : fillProducts // ignore: cast_nullable_to_non_nullable
as bool,updateProducts: null == updateProducts ? _self.updateProducts : updateProducts // ignore: cast_nullable_to_non_nullable
as bool,convertProducts: null == convertProducts ? _self.convertProducts : convertProducts // ignore: cast_nullable_to_non_nullable
as bool,convertRateToClient: null == convertRateToClient ? _self.convertRateToClient : convertRateToClient // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxConfigApiCopyWith<$Res>? get taxData {
    if (_self.taxData == null) {
    return null;
  }

  return $TaxConfigApiCopyWith<$Res>(_self.taxData!, (value) {
    return _then(_self.copyWith(taxData: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompanyEnvelopeApi].
extension CompanyEnvelopeApiPatterns on CompanyEnvelopeApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanyEnvelopeApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanyEnvelopeApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanyEnvelopeApi value)  $default,){
final _that = this;
switch (_that) {
case _CompanyEnvelopeApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanyEnvelopeApi value)?  $default,){
final _that = this;
switch (_that) {
case _CompanyEnvelopeApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'custom_fields')  Map<String, String> customFields, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'enabled_modules')  int enabledModules,  Map<String, dynamic> settings, @JsonKey(name: 'task_statuses')  List<TaskStatusApi> taskStatuses, @JsonKey(name: 'company_gateways')  List<CompanyGatewayApi> companyGateways, @JsonKey(name: 'payment_terms')  List<PaymentTermApi> paymentTerms, @JsonKey(name: 'tax_rates')  List<TaxRateApi> taxRates, @JsonKey(name: 'expense_categories')  List<ExpenseCategoryApi> expenseCategories, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanyEnvelopeApi() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.customFields,_that.sizeId,_that.industryId,_that.legalEntityId,_that.enabledModules,_that.settings,_that.taskStatuses,_that.companyGateways,_that.paymentTerms,_that.taxRates,_that.expenseCategories,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'custom_fields')  Map<String, String> customFields, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'enabled_modules')  int enabledModules,  Map<String, dynamic> settings, @JsonKey(name: 'task_statuses')  List<TaskStatusApi> taskStatuses, @JsonKey(name: 'company_gateways')  List<CompanyGatewayApi> companyGateways, @JsonKey(name: 'payment_terms')  List<PaymentTermApi> paymentTerms, @JsonKey(name: 'tax_rates')  List<TaxRateApi> taxRates, @JsonKey(name: 'expense_categories')  List<ExpenseCategoryApi> expenseCategories, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient)  $default,) {final _that = this;
switch (_that) {
case _CompanyEnvelopeApi():
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.customFields,_that.sizeId,_that.industryId,_that.legalEntityId,_that.enabledModules,_that.settings,_that.taskStatuses,_that.companyGateways,_that.paymentTerms,_that.taxRates,_that.expenseCategories,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'custom_fields')  Map<String, String> customFields, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'enabled_modules')  int enabledModules,  Map<String, dynamic> settings, @JsonKey(name: 'task_statuses')  List<TaskStatusApi> taskStatuses, @JsonKey(name: 'company_gateways')  List<CompanyGatewayApi> companyGateways, @JsonKey(name: 'payment_terms')  List<PaymentTermApi> paymentTerms, @JsonKey(name: 'tax_rates')  List<TaxRateApi> taxRates, @JsonKey(name: 'expense_categories')  List<ExpenseCategoryApi> expenseCategories, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient)?  $default,) {final _that = this;
switch (_that) {
case _CompanyEnvelopeApi() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.customFields,_that.sizeId,_that.industryId,_that.legalEntityId,_that.enabledModules,_that.settings,_that.taskStatuses,_that.companyGateways,_that.paymentTerms,_that.taxRates,_that.expenseCategories,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompanyEnvelopeApi implements CompanyEnvelopeApi {
  const _CompanyEnvelopeApi({this.id = '', @JsonKey(name: 'display_name') this.displayName = '', this.name = '', @JsonKey(name: 'company_key') this.companyKey = '', @JsonKey(name: 'custom_fields') final  Map<String, String> customFields = const <String, String>{}, @JsonKey(name: 'size_id') this.sizeId = '', @JsonKey(name: 'industry_id') this.industryId = '', @JsonKey(name: 'legal_entity_id') this.legalEntityId = 0, @JsonKey(name: 'enabled_modules') this.enabledModules = 0, final  Map<String, dynamic> settings = const <String, dynamic>{}, @JsonKey(name: 'task_statuses') final  List<TaskStatusApi> taskStatuses = const <TaskStatusApi>[], @JsonKey(name: 'company_gateways') final  List<CompanyGatewayApi> companyGateways = const <CompanyGatewayApi>[], @JsonKey(name: 'payment_terms') final  List<PaymentTermApi> paymentTerms = const <PaymentTermApi>[], @JsonKey(name: 'tax_rates') final  List<TaxRateApi> taxRates = const <TaxRateApi>[], @JsonKey(name: 'expense_categories') final  List<ExpenseCategoryApi> expenseCategories = const <ExpenseCategoryApi>[], @JsonKey(name: 'enabled_tax_rates') this.enabledTaxRates = 0, @JsonKey(name: 'enabled_item_tax_rates') this.enabledItemTaxRates = 0, @JsonKey(name: 'enabled_expense_tax_rates') this.enabledExpenseTaxRates = 0, @JsonKey(name: 'calculate_taxes') this.calculateTaxes = false, @JsonKey(name: 'tax_data') this.taxData, @JsonKey(name: 'track_inventory') this.trackInventory = false, @JsonKey(name: 'stock_notification') this.stockNotification = false, @JsonKey(name: 'inventory_notification_threshold') this.inventoryNotificationThreshold = 0, @JsonKey(name: 'enable_product_discount') this.enableProductDiscount = false, @JsonKey(name: 'enable_product_cost') this.enableProductCost = false, @JsonKey(name: 'enable_product_quantity') this.enableProductQuantity = false, @JsonKey(name: 'default_quantity') this.defaultQuantity = false, @JsonKey(name: 'show_product_details') this.showProductDetails = false, @JsonKey(name: 'fill_products') this.fillProducts = false, @JsonKey(name: 'update_products') this.updateProducts = false, @JsonKey(name: 'convert_products') this.convertProducts = false, @JsonKey(name: 'convert_rate_to_client') this.convertRateToClient = false}): _customFields = customFields,_settings = settings,_taskStatuses = taskStatuses,_companyGateways = companyGateways,_paymentTerms = paymentTerms,_taxRates = taxRates,_expenseCategories = expenseCategories;
  factory _CompanyEnvelopeApi.fromJson(Map<String, dynamic> json) => _$CompanyEnvelopeApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'company_key') final  String companyKey;
 final  Map<String, String> _customFields;
@override@JsonKey(name: 'custom_fields') Map<String, String> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

@override@JsonKey(name: 'size_id') final  String sizeId;
@override@JsonKey(name: 'industry_id') final  String industryId;
@override@JsonKey(name: 'legal_entity_id') final  int legalEntityId;
@override@JsonKey(name: 'enabled_modules') final  int enabledModules;
// `settings` stays as a raw map — every key the server sends is
// preserved verbatim through the round-trip. Strong-typing here would
// drop unknown keys at fromJson/toJson, silently corrupting fields
// we haven't modeled yet. The repository builds the typed view on
// demand via `CompanySettingsApi.fromJson`.
 final  Map<String, dynamic> _settings;
// `settings` stays as a raw map — every key the server sends is
// preserved verbatim through the round-trip. Strong-typing here would
// drop unknown keys at fromJson/toJson, silently corrupting fields
// we haven't modeled yet. The repository builds the typed view on
// demand via `CompanySettingsApi.fromJson`.
@override@JsonKey() Map<String, dynamic> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}

// Bundled reference arrays. `/refresh?first_load=true` delivers these
// alongside the company so the matching repos don't need a separate
// round-trip on first paint. The pattern matches CLAUDE.md § Data
// loading — bundled vs per-entity. Add new bundles here as more
// settings screens come online (tax_rates, designs, …).
 final  List<TaskStatusApi> _taskStatuses;
// Bundled reference arrays. `/refresh?first_load=true` delivers these
// alongside the company so the matching repos don't need a separate
// round-trip on first paint. The pattern matches CLAUDE.md § Data
// loading — bundled vs per-entity. Add new bundles here as more
// settings screens come online (tax_rates, designs, …).
@override@JsonKey(name: 'task_statuses') List<TaskStatusApi> get taskStatuses {
  if (_taskStatuses is EqualUnmodifiableListView) return _taskStatuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_taskStatuses);
}

 final  List<CompanyGatewayApi> _companyGateways;
@override@JsonKey(name: 'company_gateways') List<CompanyGatewayApi> get companyGateways {
  if (_companyGateways is EqualUnmodifiableListView) return _companyGateways;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_companyGateways);
}

 final  List<PaymentTermApi> _paymentTerms;
@override@JsonKey(name: 'payment_terms') List<PaymentTermApi> get paymentTerms {
  if (_paymentTerms is EqualUnmodifiableListView) return _paymentTerms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paymentTerms);
}

 final  List<TaxRateApi> _taxRates;
@override@JsonKey(name: 'tax_rates') List<TaxRateApi> get taxRates {
  if (_taxRates is EqualUnmodifiableListView) return _taxRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_taxRates);
}

 final  List<ExpenseCategoryApi> _expenseCategories;
@override@JsonKey(name: 'expense_categories') List<ExpenseCategoryApi> get expenseCategories {
  if (_expenseCategories is EqualUnmodifiableListView) return _expenseCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenseCategories);
}

// Top-level tax fields on the envelope, mirroring `CompanyApi`. Settings
// → Tax Settings writes these via `host.updateCompany(...)`.
@override@JsonKey(name: 'enabled_tax_rates') final  int enabledTaxRates;
@override@JsonKey(name: 'enabled_item_tax_rates') final  int enabledItemTaxRates;
@override@JsonKey(name: 'enabled_expense_tax_rates') final  int enabledExpenseTaxRates;
@override@JsonKey(name: 'calculate_taxes') final  bool calculateTaxes;
@override@JsonKey(name: 'tax_data') final  TaxConfigApi? taxData;
// Top-level product configuration on the envelope, mirroring `CompanyApi`.
// Settings → Product Settings writes these via `vm.updateCompany(...)`;
// the login envelope persists them straight into the `companies` Drift
// table so they're available offline before the first refresh.
@override@JsonKey(name: 'track_inventory') final  bool trackInventory;
@override@JsonKey(name: 'stock_notification') final  bool stockNotification;
@override@JsonKey(name: 'inventory_notification_threshold') final  int inventoryNotificationThreshold;
@override@JsonKey(name: 'enable_product_discount') final  bool enableProductDiscount;
@override@JsonKey(name: 'enable_product_cost') final  bool enableProductCost;
@override@JsonKey(name: 'enable_product_quantity') final  bool enableProductQuantity;
@override@JsonKey(name: 'default_quantity') final  bool defaultQuantity;
@override@JsonKey(name: 'show_product_details') final  bool showProductDetails;
@override@JsonKey(name: 'fill_products') final  bool fillProducts;
@override@JsonKey(name: 'update_products') final  bool updateProducts;
@override@JsonKey(name: 'convert_products') final  bool convertProducts;
@override@JsonKey(name: 'convert_rate_to_client') final  bool convertRateToClient;

/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyEnvelopeApiCopyWith<_CompanyEnvelopeApi> get copyWith => __$CompanyEnvelopeApiCopyWithImpl<_CompanyEnvelopeApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyEnvelopeApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyEnvelopeApi&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&const DeepCollectionEquality().equals(other._settings, _settings)&&const DeepCollectionEquality().equals(other._taskStatuses, _taskStatuses)&&const DeepCollectionEquality().equals(other._companyGateways, _companyGateways)&&const DeepCollectionEquality().equals(other._paymentTerms, _paymentTerms)&&const DeepCollectionEquality().equals(other._taxRates, _taxRates)&&const DeepCollectionEquality().equals(other._expenseCategories, _expenseCategories)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,const DeepCollectionEquality().hash(_customFields),sizeId,industryId,legalEntityId,enabledModules,const DeepCollectionEquality().hash(_settings),const DeepCollectionEquality().hash(_taskStatuses),const DeepCollectionEquality().hash(_companyGateways),const DeepCollectionEquality().hash(_paymentTerms),const DeepCollectionEquality().hash(_taxRates),const DeepCollectionEquality().hash(_expenseCategories),enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient]);

@override
String toString() {
  return 'CompanyEnvelopeApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, customFields: $customFields, sizeId: $sizeId, industryId: $industryId, legalEntityId: $legalEntityId, enabledModules: $enabledModules, settings: $settings, taskStatuses: $taskStatuses, companyGateways: $companyGateways, paymentTerms: $paymentTerms, taxRates: $taxRates, expenseCategories: $expenseCategories, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient)';
}


}

/// @nodoc
abstract mixin class _$CompanyEnvelopeApiCopyWith<$Res> implements $CompanyEnvelopeApiCopyWith<$Res> {
  factory _$CompanyEnvelopeApiCopyWith(_CompanyEnvelopeApi value, $Res Function(_CompanyEnvelopeApi) _then) = __$CompanyEnvelopeApiCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String displayName, String name,@JsonKey(name: 'company_key') String companyKey,@JsonKey(name: 'custom_fields') Map<String, String> customFields,@JsonKey(name: 'size_id') String sizeId,@JsonKey(name: 'industry_id') String industryId,@JsonKey(name: 'legal_entity_id') int legalEntityId,@JsonKey(name: 'enabled_modules') int enabledModules, Map<String, dynamic> settings,@JsonKey(name: 'task_statuses') List<TaskStatusApi> taskStatuses,@JsonKey(name: 'company_gateways') List<CompanyGatewayApi> companyGateways,@JsonKey(name: 'payment_terms') List<PaymentTermApi> paymentTerms,@JsonKey(name: 'tax_rates') List<TaxRateApi> taxRates,@JsonKey(name: 'expense_categories') List<ExpenseCategoryApi> expenseCategories,@JsonKey(name: 'enabled_tax_rates') int enabledTaxRates,@JsonKey(name: 'enabled_item_tax_rates') int enabledItemTaxRates,@JsonKey(name: 'enabled_expense_tax_rates') int enabledExpenseTaxRates,@JsonKey(name: 'calculate_taxes') bool calculateTaxes,@JsonKey(name: 'tax_data') TaxConfigApi? taxData,@JsonKey(name: 'track_inventory') bool trackInventory,@JsonKey(name: 'stock_notification') bool stockNotification,@JsonKey(name: 'inventory_notification_threshold') int inventoryNotificationThreshold,@JsonKey(name: 'enable_product_discount') bool enableProductDiscount,@JsonKey(name: 'enable_product_cost') bool enableProductCost,@JsonKey(name: 'enable_product_quantity') bool enableProductQuantity,@JsonKey(name: 'default_quantity') bool defaultQuantity,@JsonKey(name: 'show_product_details') bool showProductDetails,@JsonKey(name: 'fill_products') bool fillProducts,@JsonKey(name: 'update_products') bool updateProducts,@JsonKey(name: 'convert_products') bool convertProducts,@JsonKey(name: 'convert_rate_to_client') bool convertRateToClient
});


@override $TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class __$CompanyEnvelopeApiCopyWithImpl<$Res>
    implements _$CompanyEnvelopeApiCopyWith<$Res> {
  __$CompanyEnvelopeApiCopyWithImpl(this._self, this._then);

  final _CompanyEnvelopeApi _self;
  final $Res Function(_CompanyEnvelopeApi) _then;

/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? customFields = null,Object? sizeId = null,Object? industryId = null,Object? legalEntityId = null,Object? enabledModules = null,Object? settings = null,Object? taskStatuses = null,Object? companyGateways = null,Object? paymentTerms = null,Object? taxRates = null,Object? expenseCategories = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,}) {
  return _then(_CompanyEnvelopeApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,taskStatuses: null == taskStatuses ? _self._taskStatuses : taskStatuses // ignore: cast_nullable_to_non_nullable
as List<TaskStatusApi>,companyGateways: null == companyGateways ? _self._companyGateways : companyGateways // ignore: cast_nullable_to_non_nullable
as List<CompanyGatewayApi>,paymentTerms: null == paymentTerms ? _self._paymentTerms : paymentTerms // ignore: cast_nullable_to_non_nullable
as List<PaymentTermApi>,taxRates: null == taxRates ? _self._taxRates : taxRates // ignore: cast_nullable_to_non_nullable
as List<TaxRateApi>,expenseCategories: null == expenseCategories ? _self._expenseCategories : expenseCategories // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategoryApi>,enabledTaxRates: null == enabledTaxRates ? _self.enabledTaxRates : enabledTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledItemTaxRates: null == enabledItemTaxRates ? _self.enabledItemTaxRates : enabledItemTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledExpenseTaxRates: null == enabledExpenseTaxRates ? _self.enabledExpenseTaxRates : enabledExpenseTaxRates // ignore: cast_nullable_to_non_nullable
as int,calculateTaxes: null == calculateTaxes ? _self.calculateTaxes : calculateTaxes // ignore: cast_nullable_to_non_nullable
as bool,taxData: freezed == taxData ? _self.taxData : taxData // ignore: cast_nullable_to_non_nullable
as TaxConfigApi?,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockNotification: null == stockNotification ? _self.stockNotification : stockNotification // ignore: cast_nullable_to_non_nullable
as bool,inventoryNotificationThreshold: null == inventoryNotificationThreshold ? _self.inventoryNotificationThreshold : inventoryNotificationThreshold // ignore: cast_nullable_to_non_nullable
as int,enableProductDiscount: null == enableProductDiscount ? _self.enableProductDiscount : enableProductDiscount // ignore: cast_nullable_to_non_nullable
as bool,enableProductCost: null == enableProductCost ? _self.enableProductCost : enableProductCost // ignore: cast_nullable_to_non_nullable
as bool,enableProductQuantity: null == enableProductQuantity ? _self.enableProductQuantity : enableProductQuantity // ignore: cast_nullable_to_non_nullable
as bool,defaultQuantity: null == defaultQuantity ? _self.defaultQuantity : defaultQuantity // ignore: cast_nullable_to_non_nullable
as bool,showProductDetails: null == showProductDetails ? _self.showProductDetails : showProductDetails // ignore: cast_nullable_to_non_nullable
as bool,fillProducts: null == fillProducts ? _self.fillProducts : fillProducts // ignore: cast_nullable_to_non_nullable
as bool,updateProducts: null == updateProducts ? _self.updateProducts : updateProducts // ignore: cast_nullable_to_non_nullable
as bool,convertProducts: null == convertProducts ? _self.convertProducts : convertProducts // ignore: cast_nullable_to_non_nullable
as bool,convertRateToClient: null == convertRateToClient ? _self.convertRateToClient : convertRateToClient // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CompanyEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxConfigApiCopyWith<$Res>? get taxData {
    if (_self.taxData == null) {
    return null;
  }

  return $TaxConfigApiCopyWith<$Res>(_self.taxData!, (value) {
    return _then(_self.copyWith(taxData: value));
  });
}
}


/// @nodoc
mixin _$TokenApi {

 String get token; String get name;
/// Create a copy of TokenApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenApiCopyWith<TokenApi> get copyWith => _$TokenApiCopyWithImpl<TokenApi>(this as TokenApi, _$identity);

  /// Serializes this TokenApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenApi&&(identical(other.token, token) || other.token == token)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,name);

@override
String toString() {
  return 'TokenApi(token: $token, name: $name)';
}


}

/// @nodoc
abstract mixin class $TokenApiCopyWith<$Res>  {
  factory $TokenApiCopyWith(TokenApi value, $Res Function(TokenApi) _then) = _$TokenApiCopyWithImpl;
@useResult
$Res call({
 String token, String name
});




}
/// @nodoc
class _$TokenApiCopyWithImpl<$Res>
    implements $TokenApiCopyWith<$Res> {
  _$TokenApiCopyWithImpl(this._self, this._then);

  final TokenApi _self;
  final $Res Function(TokenApi) _then;

/// Create a copy of TokenApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? name = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenApi].
extension TokenApiPatterns on TokenApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenApi value)  $default,){
final _that = this;
switch (_that) {
case _TokenApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenApi value)?  $default,){
final _that = this;
switch (_that) {
case _TokenApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenApi() when $default != null:
return $default(_that.token,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String name)  $default,) {final _that = this;
switch (_that) {
case _TokenApi():
return $default(_that.token,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String name)?  $default,) {final _that = this;
switch (_that) {
case _TokenApi() when $default != null:
return $default(_that.token,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenApi implements TokenApi {
  const _TokenApi({this.token = '', this.name = ''});
  factory _TokenApi.fromJson(Map<String, dynamic> json) => _$TokenApiFromJson(json);

@override@JsonKey() final  String token;
@override@JsonKey() final  String name;

/// Create a copy of TokenApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenApiCopyWith<_TokenApi> get copyWith => __$TokenApiCopyWithImpl<_TokenApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenApi&&(identical(other.token, token) || other.token == token)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,name);

@override
String toString() {
  return 'TokenApi(token: $token, name: $name)';
}


}

/// @nodoc
abstract mixin class _$TokenApiCopyWith<$Res> implements $TokenApiCopyWith<$Res> {
  factory _$TokenApiCopyWith(_TokenApi value, $Res Function(_TokenApi) _then) = __$TokenApiCopyWithImpl;
@override @useResult
$Res call({
 String token, String name
});




}
/// @nodoc
class __$TokenApiCopyWithImpl<$Res>
    implements _$TokenApiCopyWith<$Res> {
  __$TokenApiCopyWithImpl(this._self, this._then);

  final _TokenApi _self;
  final $Res Function(_TokenApi) _then;

/// Create a copy of TokenApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? name = null,}) {
  return _then(_TokenApi(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AccountEnvelopeApi {

 String get id;@JsonKey(name: 'default_company_id') String get defaultCompanyId; String get plan;@JsonKey(name: 'num_trial_days') int get numTrialDays;@JsonKey(name: 'hosted_client_count') int get hostedClientCount;@JsonKey(name: 'hosted_company_count') int get hostedCompanyCount;
/// Create a copy of AccountEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountEnvelopeApiCopyWith<AccountEnvelopeApi> get copyWith => _$AccountEnvelopeApiCopyWithImpl<AccountEnvelopeApi>(this as AccountEnvelopeApi, _$identity);

  /// Serializes this AccountEnvelopeApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountEnvelopeApi&&(identical(other.id, id) || other.id == id)&&(identical(other.defaultCompanyId, defaultCompanyId) || other.defaultCompanyId == defaultCompanyId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.numTrialDays, numTrialDays) || other.numTrialDays == numTrialDays)&&(identical(other.hostedClientCount, hostedClientCount) || other.hostedClientCount == hostedClientCount)&&(identical(other.hostedCompanyCount, hostedCompanyCount) || other.hostedCompanyCount == hostedCompanyCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,defaultCompanyId,plan,numTrialDays,hostedClientCount,hostedCompanyCount);

@override
String toString() {
  return 'AccountEnvelopeApi(id: $id, defaultCompanyId: $defaultCompanyId, plan: $plan, numTrialDays: $numTrialDays, hostedClientCount: $hostedClientCount, hostedCompanyCount: $hostedCompanyCount)';
}


}

/// @nodoc
abstract mixin class $AccountEnvelopeApiCopyWith<$Res>  {
  factory $AccountEnvelopeApiCopyWith(AccountEnvelopeApi value, $Res Function(AccountEnvelopeApi) _then) = _$AccountEnvelopeApiCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'default_company_id') String defaultCompanyId, String plan,@JsonKey(name: 'num_trial_days') int numTrialDays,@JsonKey(name: 'hosted_client_count') int hostedClientCount,@JsonKey(name: 'hosted_company_count') int hostedCompanyCount
});




}
/// @nodoc
class _$AccountEnvelopeApiCopyWithImpl<$Res>
    implements $AccountEnvelopeApiCopyWith<$Res> {
  _$AccountEnvelopeApiCopyWithImpl(this._self, this._then);

  final AccountEnvelopeApi _self;
  final $Res Function(AccountEnvelopeApi) _then;

/// Create a copy of AccountEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? defaultCompanyId = null,Object? plan = null,Object? numTrialDays = null,Object? hostedClientCount = null,Object? hostedCompanyCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,defaultCompanyId: null == defaultCompanyId ? _self.defaultCompanyId : defaultCompanyId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,numTrialDays: null == numTrialDays ? _self.numTrialDays : numTrialDays // ignore: cast_nullable_to_non_nullable
as int,hostedClientCount: null == hostedClientCount ? _self.hostedClientCount : hostedClientCount // ignore: cast_nullable_to_non_nullable
as int,hostedCompanyCount: null == hostedCompanyCount ? _self.hostedCompanyCount : hostedCompanyCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountEnvelopeApi].
extension AccountEnvelopeApiPatterns on AccountEnvelopeApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountEnvelopeApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountEnvelopeApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountEnvelopeApi value)  $default,){
final _that = this;
switch (_that) {
case _AccountEnvelopeApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountEnvelopeApi value)?  $default,){
final _that = this;
switch (_that) {
case _AccountEnvelopeApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'default_company_id')  String defaultCompanyId,  String plan, @JsonKey(name: 'num_trial_days')  int numTrialDays, @JsonKey(name: 'hosted_client_count')  int hostedClientCount, @JsonKey(name: 'hosted_company_count')  int hostedCompanyCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountEnvelopeApi() when $default != null:
return $default(_that.id,_that.defaultCompanyId,_that.plan,_that.numTrialDays,_that.hostedClientCount,_that.hostedCompanyCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'default_company_id')  String defaultCompanyId,  String plan, @JsonKey(name: 'num_trial_days')  int numTrialDays, @JsonKey(name: 'hosted_client_count')  int hostedClientCount, @JsonKey(name: 'hosted_company_count')  int hostedCompanyCount)  $default,) {final _that = this;
switch (_that) {
case _AccountEnvelopeApi():
return $default(_that.id,_that.defaultCompanyId,_that.plan,_that.numTrialDays,_that.hostedClientCount,_that.hostedCompanyCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'default_company_id')  String defaultCompanyId,  String plan, @JsonKey(name: 'num_trial_days')  int numTrialDays, @JsonKey(name: 'hosted_client_count')  int hostedClientCount, @JsonKey(name: 'hosted_company_count')  int hostedCompanyCount)?  $default,) {final _that = this;
switch (_that) {
case _AccountEnvelopeApi() when $default != null:
return $default(_that.id,_that.defaultCompanyId,_that.plan,_that.numTrialDays,_that.hostedClientCount,_that.hostedCompanyCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountEnvelopeApi implements AccountEnvelopeApi {
  const _AccountEnvelopeApi({this.id = '', @JsonKey(name: 'default_company_id') this.defaultCompanyId = '', this.plan = '', @JsonKey(name: 'num_trial_days') this.numTrialDays = 0, @JsonKey(name: 'hosted_client_count') this.hostedClientCount = 0, @JsonKey(name: 'hosted_company_count') this.hostedCompanyCount = 0});
  factory _AccountEnvelopeApi.fromJson(Map<String, dynamic> json) => _$AccountEnvelopeApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(name: 'default_company_id') final  String defaultCompanyId;
@override@JsonKey() final  String plan;
@override@JsonKey(name: 'num_trial_days') final  int numTrialDays;
@override@JsonKey(name: 'hosted_client_count') final  int hostedClientCount;
@override@JsonKey(name: 'hosted_company_count') final  int hostedCompanyCount;

/// Create a copy of AccountEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountEnvelopeApiCopyWith<_AccountEnvelopeApi> get copyWith => __$AccountEnvelopeApiCopyWithImpl<_AccountEnvelopeApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountEnvelopeApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountEnvelopeApi&&(identical(other.id, id) || other.id == id)&&(identical(other.defaultCompanyId, defaultCompanyId) || other.defaultCompanyId == defaultCompanyId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.numTrialDays, numTrialDays) || other.numTrialDays == numTrialDays)&&(identical(other.hostedClientCount, hostedClientCount) || other.hostedClientCount == hostedClientCount)&&(identical(other.hostedCompanyCount, hostedCompanyCount) || other.hostedCompanyCount == hostedCompanyCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,defaultCompanyId,plan,numTrialDays,hostedClientCount,hostedCompanyCount);

@override
String toString() {
  return 'AccountEnvelopeApi(id: $id, defaultCompanyId: $defaultCompanyId, plan: $plan, numTrialDays: $numTrialDays, hostedClientCount: $hostedClientCount, hostedCompanyCount: $hostedCompanyCount)';
}


}

/// @nodoc
abstract mixin class _$AccountEnvelopeApiCopyWith<$Res> implements $AccountEnvelopeApiCopyWith<$Res> {
  factory _$AccountEnvelopeApiCopyWith(_AccountEnvelopeApi value, $Res Function(_AccountEnvelopeApi) _then) = __$AccountEnvelopeApiCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'default_company_id') String defaultCompanyId, String plan,@JsonKey(name: 'num_trial_days') int numTrialDays,@JsonKey(name: 'hosted_client_count') int hostedClientCount,@JsonKey(name: 'hosted_company_count') int hostedCompanyCount
});




}
/// @nodoc
class __$AccountEnvelopeApiCopyWithImpl<$Res>
    implements _$AccountEnvelopeApiCopyWith<$Res> {
  __$AccountEnvelopeApiCopyWithImpl(this._self, this._then);

  final _AccountEnvelopeApi _self;
  final $Res Function(_AccountEnvelopeApi) _then;

/// Create a copy of AccountEnvelopeApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? defaultCompanyId = null,Object? plan = null,Object? numTrialDays = null,Object? hostedClientCount = null,Object? hostedCompanyCount = null,}) {
  return _then(_AccountEnvelopeApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,defaultCompanyId: null == defaultCompanyId ? _self.defaultCompanyId : defaultCompanyId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,numTrialDays: null == numTrialDays ? _self.numTrialDays : numTrialDays // ignore: cast_nullable_to_non_nullable
as int,hostedClientCount: null == hostedClientCount ? _self.hostedClientCount : hostedClientCount // ignore: cast_nullable_to_non_nullable
as int,hostedCompanyCount: null == hostedCompanyCount ? _self.hostedCompanyCount : hostedCompanyCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
