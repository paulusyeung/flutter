// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_response_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoginResponseApi _$LoginResponseApiFromJson(Map<String, dynamic> json) {
  return _LoginResponseApi.fromJson(json);
}

/// @nodoc
mixin _$LoginResponseApi {
  List<UserCompanyApi> get data => throw _privateConstructorUsedError;
  @JsonKey(name: 'static')
  Map<String, dynamic> get staticData => throw _privateConstructorUsedError;

  /// Serializes this LoginResponseApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginResponseApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginResponseApiCopyWith<LoginResponseApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginResponseApiCopyWith<$Res> {
  factory $LoginResponseApiCopyWith(
    LoginResponseApi value,
    $Res Function(LoginResponseApi) then,
  ) = _$LoginResponseApiCopyWithImpl<$Res, LoginResponseApi>;
  @useResult
  $Res call({
    List<UserCompanyApi> data,
    @JsonKey(name: 'static') Map<String, dynamic> staticData,
  });
}

/// @nodoc
class _$LoginResponseApiCopyWithImpl<$Res, $Val extends LoginResponseApi>
    implements $LoginResponseApiCopyWith<$Res> {
  _$LoginResponseApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginResponseApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null, Object? staticData = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<UserCompanyApi>,
            staticData: null == staticData
                ? _value.staticData
                : staticData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginResponseApiImplCopyWith<$Res>
    implements $LoginResponseApiCopyWith<$Res> {
  factory _$$LoginResponseApiImplCopyWith(
    _$LoginResponseApiImpl value,
    $Res Function(_$LoginResponseApiImpl) then,
  ) = __$$LoginResponseApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<UserCompanyApi> data,
    @JsonKey(name: 'static') Map<String, dynamic> staticData,
  });
}

/// @nodoc
class __$$LoginResponseApiImplCopyWithImpl<$Res>
    extends _$LoginResponseApiCopyWithImpl<$Res, _$LoginResponseApiImpl>
    implements _$$LoginResponseApiImplCopyWith<$Res> {
  __$$LoginResponseApiImplCopyWithImpl(
    _$LoginResponseApiImpl _value,
    $Res Function(_$LoginResponseApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginResponseApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null, Object? staticData = null}) {
    return _then(
      _$LoginResponseApiImpl(
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<UserCompanyApi>,
        staticData: null == staticData
            ? _value._staticData
            : staticData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginResponseApiImpl implements _LoginResponseApi {
  const _$LoginResponseApiImpl({
    final List<UserCompanyApi> data = const <UserCompanyApi>[],
    @JsonKey(name: 'static')
    final Map<String, dynamic> staticData = const <String, dynamic>{},
  }) : _data = data,
       _staticData = staticData;

  factory _$LoginResponseApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResponseApiImplFromJson(json);

  final List<UserCompanyApi> _data;
  @override
  @JsonKey()
  List<UserCompanyApi> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  final Map<String, dynamic> _staticData;
  @override
  @JsonKey(name: 'static')
  Map<String, dynamic> get staticData {
    if (_staticData is EqualUnmodifiableMapView) return _staticData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_staticData);
  }

  @override
  String toString() {
    return 'LoginResponseApi(data: $data, staticData: $staticData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginResponseApiImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            const DeepCollectionEquality().equals(
              other._staticData,
              _staticData,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_data),
    const DeepCollectionEquality().hash(_staticData),
  );

  /// Create a copy of LoginResponseApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginResponseApiImplCopyWith<_$LoginResponseApiImpl> get copyWith =>
      __$$LoginResponseApiImplCopyWithImpl<_$LoginResponseApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginResponseApiImplToJson(this);
  }
}

abstract class _LoginResponseApi implements LoginResponseApi {
  const factory _LoginResponseApi({
    final List<UserCompanyApi> data,
    @JsonKey(name: 'static') final Map<String, dynamic> staticData,
  }) = _$LoginResponseApiImpl;

  factory _LoginResponseApi.fromJson(Map<String, dynamic> json) =
      _$LoginResponseApiImpl.fromJson;

  @override
  List<UserCompanyApi> get data;
  @override
  @JsonKey(name: 'static')
  Map<String, dynamic> get staticData;

  /// Create a copy of LoginResponseApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResponseApiImplCopyWith<_$LoginResponseApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserCompanyApi _$UserCompanyApiFromJson(Map<String, dynamic> json) {
  return _UserCompanyApi.fromJson(json);
}

/// @nodoc
mixin _$UserCompanyApi {
  @JsonKey(name: 'is_admin')
  bool get isAdmin => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_owner')
  bool get isOwner => throw _privateConstructorUsedError;
  String get permissions => throw _privateConstructorUsedError;
  @JsonKey(name: 'permissions_updated_at')
  int get permissionsUpdatedAt => throw _privateConstructorUsedError;
  CompanyEnvelopeApi get company => throw _privateConstructorUsedError;
  TokenApi get token => throw _privateConstructorUsedError;
  AccountEnvelopeApi get account => throw _privateConstructorUsedError;
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;
  @JsonKey(name: 'user')
  UserSummaryApi get user => throw _privateConstructorUsedError;

  /// Serializes this UserCompanyApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCompanyApiCopyWith<UserCompanyApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCompanyApiCopyWith<$Res> {
  factory $UserCompanyApiCopyWith(
    UserCompanyApi value,
    $Res Function(UserCompanyApi) then,
  ) = _$UserCompanyApiCopyWithImpl<$Res, UserCompanyApi>;
  @useResult
  $Res call({
    @JsonKey(name: 'is_admin') bool isAdmin,
    @JsonKey(name: 'is_owner') bool isOwner,
    String permissions,
    @JsonKey(name: 'permissions_updated_at') int permissionsUpdatedAt,
    CompanyEnvelopeApi company,
    TokenApi token,
    AccountEnvelopeApi account,
    Map<String, dynamic> settings,
    @JsonKey(name: 'user') UserSummaryApi user,
  });

  $CompanyEnvelopeApiCopyWith<$Res> get company;
  $TokenApiCopyWith<$Res> get token;
  $AccountEnvelopeApiCopyWith<$Res> get account;
  $UserSummaryApiCopyWith<$Res> get user;
}

/// @nodoc
class _$UserCompanyApiCopyWithImpl<$Res, $Val extends UserCompanyApi>
    implements $UserCompanyApiCopyWith<$Res> {
  _$UserCompanyApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAdmin = null,
    Object? isOwner = null,
    Object? permissions = null,
    Object? permissionsUpdatedAt = null,
    Object? company = null,
    Object? token = null,
    Object? account = null,
    Object? settings = null,
    Object? user = null,
  }) {
    return _then(
      _value.copyWith(
            isAdmin: null == isAdmin
                ? _value.isAdmin
                : isAdmin // ignore: cast_nullable_to_non_nullable
                      as bool,
            isOwner: null == isOwner
                ? _value.isOwner
                : isOwner // ignore: cast_nullable_to_non_nullable
                      as bool,
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as String,
            permissionsUpdatedAt: null == permissionsUpdatedAt
                ? _value.permissionsUpdatedAt
                : permissionsUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as CompanyEnvelopeApi,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as TokenApi,
            account: null == account
                ? _value.account
                : account // ignore: cast_nullable_to_non_nullable
                      as AccountEnvelopeApi,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as UserSummaryApi,
          )
          as $Val,
    );
  }

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompanyEnvelopeApiCopyWith<$Res> get company {
    return $CompanyEnvelopeApiCopyWith<$Res>(_value.company, (value) {
      return _then(_value.copyWith(company: value) as $Val);
    });
  }

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TokenApiCopyWith<$Res> get token {
    return $TokenApiCopyWith<$Res>(_value.token, (value) {
      return _then(_value.copyWith(token: value) as $Val);
    });
  }

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountEnvelopeApiCopyWith<$Res> get account {
    return $AccountEnvelopeApiCopyWith<$Res>(_value.account, (value) {
      return _then(_value.copyWith(account: value) as $Val);
    });
  }

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSummaryApiCopyWith<$Res> get user {
    return $UserSummaryApiCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserCompanyApiImplCopyWith<$Res>
    implements $UserCompanyApiCopyWith<$Res> {
  factory _$$UserCompanyApiImplCopyWith(
    _$UserCompanyApiImpl value,
    $Res Function(_$UserCompanyApiImpl) then,
  ) = __$$UserCompanyApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'is_admin') bool isAdmin,
    @JsonKey(name: 'is_owner') bool isOwner,
    String permissions,
    @JsonKey(name: 'permissions_updated_at') int permissionsUpdatedAt,
    CompanyEnvelopeApi company,
    TokenApi token,
    AccountEnvelopeApi account,
    Map<String, dynamic> settings,
    @JsonKey(name: 'user') UserSummaryApi user,
  });

  @override
  $CompanyEnvelopeApiCopyWith<$Res> get company;
  @override
  $TokenApiCopyWith<$Res> get token;
  @override
  $AccountEnvelopeApiCopyWith<$Res> get account;
  @override
  $UserSummaryApiCopyWith<$Res> get user;
}

/// @nodoc
class __$$UserCompanyApiImplCopyWithImpl<$Res>
    extends _$UserCompanyApiCopyWithImpl<$Res, _$UserCompanyApiImpl>
    implements _$$UserCompanyApiImplCopyWith<$Res> {
  __$$UserCompanyApiImplCopyWithImpl(
    _$UserCompanyApiImpl _value,
    $Res Function(_$UserCompanyApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAdmin = null,
    Object? isOwner = null,
    Object? permissions = null,
    Object? permissionsUpdatedAt = null,
    Object? company = null,
    Object? token = null,
    Object? account = null,
    Object? settings = null,
    Object? user = null,
  }) {
    return _then(
      _$UserCompanyApiImpl(
        isAdmin: null == isAdmin
            ? _value.isAdmin
            : isAdmin // ignore: cast_nullable_to_non_nullable
                  as bool,
        isOwner: null == isOwner
            ? _value.isOwner
            : isOwner // ignore: cast_nullable_to_non_nullable
                  as bool,
        permissions: null == permissions
            ? _value.permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as String,
        permissionsUpdatedAt: null == permissionsUpdatedAt
            ? _value.permissionsUpdatedAt
            : permissionsUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as CompanyEnvelopeApi,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as TokenApi,
        account: null == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as AccountEnvelopeApi,
        settings: null == settings
            ? _value._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as UserSummaryApi,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCompanyApiImpl implements _UserCompanyApi {
  const _$UserCompanyApiImpl({
    @JsonKey(name: 'is_admin') this.isAdmin = false,
    @JsonKey(name: 'is_owner') this.isOwner = false,
    this.permissions = '',
    @JsonKey(name: 'permissions_updated_at') this.permissionsUpdatedAt = 0,
    required this.company,
    required this.token,
    required this.account,
    final Map<String, dynamic> settings = const <String, dynamic>{},
    @JsonKey(name: 'user') this.user = const UserSummaryApi(),
  }) : _settings = settings;

  factory _$UserCompanyApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCompanyApiImplFromJson(json);

  @override
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @override
  @JsonKey(name: 'is_owner')
  final bool isOwner;
  @override
  @JsonKey()
  final String permissions;
  @override
  @JsonKey(name: 'permissions_updated_at')
  final int permissionsUpdatedAt;
  @override
  final CompanyEnvelopeApi company;
  @override
  final TokenApi token;
  @override
  final AccountEnvelopeApi account;
  final Map<String, dynamic> _settings;
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  @JsonKey(name: 'user')
  final UserSummaryApi user;

  @override
  String toString() {
    return 'UserCompanyApi(isAdmin: $isAdmin, isOwner: $isOwner, permissions: $permissions, permissionsUpdatedAt: $permissionsUpdatedAt, company: $company, token: $token, account: $account, settings: $settings, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCompanyApiImpl &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.isOwner, isOwner) || other.isOwner == isOwner) &&
            (identical(other.permissions, permissions) ||
                other.permissions == permissions) &&
            (identical(other.permissionsUpdatedAt, permissionsUpdatedAt) ||
                other.permissionsUpdatedAt == permissionsUpdatedAt) &&
            (identical(other.company, company) || other.company == company) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.account, account) || other.account == account) &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isAdmin,
    isOwner,
    permissions,
    permissionsUpdatedAt,
    company,
    token,
    account,
    const DeepCollectionEquality().hash(_settings),
    user,
  );

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCompanyApiImplCopyWith<_$UserCompanyApiImpl> get copyWith =>
      __$$UserCompanyApiImplCopyWithImpl<_$UserCompanyApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCompanyApiImplToJson(this);
  }
}

abstract class _UserCompanyApi implements UserCompanyApi {
  const factory _UserCompanyApi({
    @JsonKey(name: 'is_admin') final bool isAdmin,
    @JsonKey(name: 'is_owner') final bool isOwner,
    final String permissions,
    @JsonKey(name: 'permissions_updated_at') final int permissionsUpdatedAt,
    required final CompanyEnvelopeApi company,
    required final TokenApi token,
    required final AccountEnvelopeApi account,
    final Map<String, dynamic> settings,
    @JsonKey(name: 'user') final UserSummaryApi user,
  }) = _$UserCompanyApiImpl;

  factory _UserCompanyApi.fromJson(Map<String, dynamic> json) =
      _$UserCompanyApiImpl.fromJson;

  @override
  @JsonKey(name: 'is_admin')
  bool get isAdmin;
  @override
  @JsonKey(name: 'is_owner')
  bool get isOwner;
  @override
  String get permissions;
  @override
  @JsonKey(name: 'permissions_updated_at')
  int get permissionsUpdatedAt;
  @override
  CompanyEnvelopeApi get company;
  @override
  TokenApi get token;
  @override
  AccountEnvelopeApi get account;
  @override
  Map<String, dynamic> get settings;
  @override
  @JsonKey(name: 'user')
  UserSummaryApi get user;

  /// Create a copy of UserCompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCompanyApiImplCopyWith<_$UserCompanyApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSummaryApi _$UserSummaryApiFromJson(Map<String, dynamic> json) {
  return _UserSummaryApi.fromJson(json);
}

/// @nodoc
mixin _$UserSummaryApi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'email')
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone')
  String get phone => throw _privateConstructorUsedError; // Server sends a truthy string ("true"/"1") OR a bool depending on the
  // endpoint, so the JSON converter normalizes to a plain bool.
  @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
  bool get google2faSecret => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
  bool get verifiedPhoneNumber => throw _privateConstructorUsedError;

  /// Serializes this UserSummaryApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSummaryApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSummaryApiCopyWith<UserSummaryApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSummaryApiCopyWith<$Res> {
  factory $UserSummaryApiCopyWith(
    UserSummaryApi value,
    $Res Function(UserSummaryApi) then,
  ) = _$UserSummaryApiCopyWithImpl<$Res, UserSummaryApi>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'email') String email,
    @JsonKey(name: 'phone') String phone,
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    bool google2faSecret,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    bool verifiedPhoneNumber,
  });
}

/// @nodoc
class _$UserSummaryApiCopyWithImpl<$Res, $Val extends UserSummaryApi>
    implements $UserSummaryApiCopyWith<$Res> {
  _$UserSummaryApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSummaryApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? phone = null,
    Object? google2faSecret = null,
    Object? verifiedPhoneNumber = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            google2faSecret: null == google2faSecret
                ? _value.google2faSecret
                : google2faSecret // ignore: cast_nullable_to_non_nullable
                      as bool,
            verifiedPhoneNumber: null == verifiedPhoneNumber
                ? _value.verifiedPhoneNumber
                : verifiedPhoneNumber // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSummaryApiImplCopyWith<$Res>
    implements $UserSummaryApiCopyWith<$Res> {
  factory _$$UserSummaryApiImplCopyWith(
    _$UserSummaryApiImpl value,
    $Res Function(_$UserSummaryApiImpl) then,
  ) = __$$UserSummaryApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'email') String email,
    @JsonKey(name: 'phone') String phone,
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    bool google2faSecret,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    bool verifiedPhoneNumber,
  });
}

/// @nodoc
class __$$UserSummaryApiImplCopyWithImpl<$Res>
    extends _$UserSummaryApiCopyWithImpl<$Res, _$UserSummaryApiImpl>
    implements _$$UserSummaryApiImplCopyWith<$Res> {
  __$$UserSummaryApiImplCopyWithImpl(
    _$UserSummaryApiImpl _value,
    $Res Function(_$UserSummaryApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserSummaryApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? phone = null,
    Object? google2faSecret = null,
    Object? verifiedPhoneNumber = null,
  }) {
    return _then(
      _$UserSummaryApiImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        google2faSecret: null == google2faSecret
            ? _value.google2faSecret
            : google2faSecret // ignore: cast_nullable_to_non_nullable
                  as bool,
        verifiedPhoneNumber: null == verifiedPhoneNumber
            ? _value.verifiedPhoneNumber
            : verifiedPhoneNumber // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSummaryApiImpl implements _UserSummaryApi {
  const _$UserSummaryApiImpl({
    this.id = '',
    @JsonKey(name: 'email') this.email = '',
    @JsonKey(name: 'phone') this.phone = '',
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    this.google2faSecret = false,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    this.verifiedPhoneNumber = false,
  });

  factory _$UserSummaryApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSummaryApiImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey(name: 'email')
  final String email;
  @override
  @JsonKey(name: 'phone')
  final String phone;
  // Server sends a truthy string ("true"/"1") OR a bool depending on the
  // endpoint, so the JSON converter normalizes to a plain bool.
  @override
  @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
  final bool google2faSecret;
  @override
  @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
  final bool verifiedPhoneNumber;

  @override
  String toString() {
    return 'UserSummaryApi(id: $id, email: $email, phone: $phone, google2faSecret: $google2faSecret, verifiedPhoneNumber: $verifiedPhoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSummaryApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.google2faSecret, google2faSecret) ||
                other.google2faSecret == google2faSecret) &&
            (identical(other.verifiedPhoneNumber, verifiedPhoneNumber) ||
                other.verifiedPhoneNumber == verifiedPhoneNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    phone,
    google2faSecret,
    verifiedPhoneNumber,
  );

  /// Create a copy of UserSummaryApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSummaryApiImplCopyWith<_$UserSummaryApiImpl> get copyWith =>
      __$$UserSummaryApiImplCopyWithImpl<_$UserSummaryApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSummaryApiImplToJson(this);
  }
}

abstract class _UserSummaryApi implements UserSummaryApi {
  const factory _UserSummaryApi({
    final String id,
    @JsonKey(name: 'email') final String email,
    @JsonKey(name: 'phone') final String phone,
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    final bool google2faSecret,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    final bool verifiedPhoneNumber,
  }) = _$UserSummaryApiImpl;

  factory _UserSummaryApi.fromJson(Map<String, dynamic> json) =
      _$UserSummaryApiImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'email')
  String get email;
  @override
  @JsonKey(name: 'phone')
  String get phone; // Server sends a truthy string ("true"/"1") OR a bool depending on the
  // endpoint, so the JSON converter normalizes to a plain bool.
  @override
  @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
  bool get google2faSecret;
  @override
  @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
  bool get verifiedPhoneNumber;

  /// Create a copy of UserSummaryApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSummaryApiImplCopyWith<_$UserSummaryApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanyEnvelopeApi _$CompanyEnvelopeApiFromJson(Map<String, dynamic> json) {
  return _CompanyEnvelopeApi.fromJson(json);
}

/// @nodoc
mixin _$CompanyEnvelopeApi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'company_key')
  String get companyKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_id')
  String get sizeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'industry_id')
  String get industryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'legal_entity_id')
  int get legalEntityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'enabled_modules')
  int get enabledModules => throw _privateConstructorUsedError; // `settings` stays as a raw map — every key the server sends is
  // preserved verbatim through the round-trip. Strong-typing here would
  // drop unknown keys at fromJson/toJson, silently corrupting fields
  // we haven't modeled yet. The repository builds the typed view on
  // demand via `CompanySettingsApi.fromJson`.
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;

  /// Serializes this CompanyEnvelopeApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyEnvelopeApiCopyWith<CompanyEnvelopeApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyEnvelopeApiCopyWith<$Res> {
  factory $CompanyEnvelopeApiCopyWith(
    CompanyEnvelopeApi value,
    $Res Function(CompanyEnvelopeApi) then,
  ) = _$CompanyEnvelopeApiCopyWithImpl<$Res, CompanyEnvelopeApi>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'display_name') String displayName,
    String name,
    @JsonKey(name: 'company_key') String companyKey,
    @JsonKey(name: 'custom_fields') Map<String, String> customFields,
    @JsonKey(name: 'size_id') String sizeId,
    @JsonKey(name: 'industry_id') String industryId,
    @JsonKey(name: 'legal_entity_id') int legalEntityId,
    @JsonKey(name: 'enabled_modules') int enabledModules,
    Map<String, dynamic> settings,
  });
}

/// @nodoc
class _$CompanyEnvelopeApiCopyWithImpl<$Res, $Val extends CompanyEnvelopeApi>
    implements $CompanyEnvelopeApiCopyWith<$Res> {
  _$CompanyEnvelopeApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? name = null,
    Object? companyKey = null,
    Object? customFields = null,
    Object? sizeId = null,
    Object? industryId = null,
    Object? legalEntityId = null,
    Object? enabledModules = null,
    Object? settings = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            companyKey: null == companyKey
                ? _value.companyKey
                : companyKey // ignore: cast_nullable_to_non_nullable
                      as String,
            customFields: null == customFields
                ? _value.customFields
                : customFields // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            sizeId: null == sizeId
                ? _value.sizeId
                : sizeId // ignore: cast_nullable_to_non_nullable
                      as String,
            industryId: null == industryId
                ? _value.industryId
                : industryId // ignore: cast_nullable_to_non_nullable
                      as String,
            legalEntityId: null == legalEntityId
                ? _value.legalEntityId
                : legalEntityId // ignore: cast_nullable_to_non_nullable
                      as int,
            enabledModules: null == enabledModules
                ? _value.enabledModules
                : enabledModules // ignore: cast_nullable_to_non_nullable
                      as int,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanyEnvelopeApiImplCopyWith<$Res>
    implements $CompanyEnvelopeApiCopyWith<$Res> {
  factory _$$CompanyEnvelopeApiImplCopyWith(
    _$CompanyEnvelopeApiImpl value,
    $Res Function(_$CompanyEnvelopeApiImpl) then,
  ) = __$$CompanyEnvelopeApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'display_name') String displayName,
    String name,
    @JsonKey(name: 'company_key') String companyKey,
    @JsonKey(name: 'custom_fields') Map<String, String> customFields,
    @JsonKey(name: 'size_id') String sizeId,
    @JsonKey(name: 'industry_id') String industryId,
    @JsonKey(name: 'legal_entity_id') int legalEntityId,
    @JsonKey(name: 'enabled_modules') int enabledModules,
    Map<String, dynamic> settings,
  });
}

/// @nodoc
class __$$CompanyEnvelopeApiImplCopyWithImpl<$Res>
    extends _$CompanyEnvelopeApiCopyWithImpl<$Res, _$CompanyEnvelopeApiImpl>
    implements _$$CompanyEnvelopeApiImplCopyWith<$Res> {
  __$$CompanyEnvelopeApiImplCopyWithImpl(
    _$CompanyEnvelopeApiImpl _value,
    $Res Function(_$CompanyEnvelopeApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? name = null,
    Object? companyKey = null,
    Object? customFields = null,
    Object? sizeId = null,
    Object? industryId = null,
    Object? legalEntityId = null,
    Object? enabledModules = null,
    Object? settings = null,
  }) {
    return _then(
      _$CompanyEnvelopeApiImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        companyKey: null == companyKey
            ? _value.companyKey
            : companyKey // ignore: cast_nullable_to_non_nullable
                  as String,
        customFields: null == customFields
            ? _value._customFields
            : customFields // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        sizeId: null == sizeId
            ? _value.sizeId
            : sizeId // ignore: cast_nullable_to_non_nullable
                  as String,
        industryId: null == industryId
            ? _value.industryId
            : industryId // ignore: cast_nullable_to_non_nullable
                  as String,
        legalEntityId: null == legalEntityId
            ? _value.legalEntityId
            : legalEntityId // ignore: cast_nullable_to_non_nullable
                  as int,
        enabledModules: null == enabledModules
            ? _value.enabledModules
            : enabledModules // ignore: cast_nullable_to_non_nullable
                  as int,
        settings: null == settings
            ? _value._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanyEnvelopeApiImpl implements _CompanyEnvelopeApi {
  const _$CompanyEnvelopeApiImpl({
    this.id = '',
    @JsonKey(name: 'display_name') this.displayName = '',
    this.name = '',
    @JsonKey(name: 'company_key') this.companyKey = '',
    @JsonKey(name: 'custom_fields')
    final Map<String, String> customFields = const <String, String>{},
    @JsonKey(name: 'size_id') this.sizeId = '',
    @JsonKey(name: 'industry_id') this.industryId = '',
    @JsonKey(name: 'legal_entity_id') this.legalEntityId = 0,
    @JsonKey(name: 'enabled_modules') this.enabledModules = 0,
    final Map<String, dynamic> settings = const <String, dynamic>{},
  }) : _customFields = customFields,
       _settings = settings;

  factory _$CompanyEnvelopeApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyEnvelopeApiImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(name: 'company_key')
  final String companyKey;
  final Map<String, String> _customFields;
  @override
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields {
    if (_customFields is EqualUnmodifiableMapView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customFields);
  }

  @override
  @JsonKey(name: 'size_id')
  final String sizeId;
  @override
  @JsonKey(name: 'industry_id')
  final String industryId;
  @override
  @JsonKey(name: 'legal_entity_id')
  final int legalEntityId;
  @override
  @JsonKey(name: 'enabled_modules')
  final int enabledModules;
  // `settings` stays as a raw map — every key the server sends is
  // preserved verbatim through the round-trip. Strong-typing here would
  // drop unknown keys at fromJson/toJson, silently corrupting fields
  // we haven't modeled yet. The repository builds the typed view on
  // demand via `CompanySettingsApi.fromJson`.
  final Map<String, dynamic> _settings;
  // `settings` stays as a raw map — every key the server sends is
  // preserved verbatim through the round-trip. Strong-typing here would
  // drop unknown keys at fromJson/toJson, silently corrupting fields
  // we haven't modeled yet. The repository builds the typed view on
  // demand via `CompanySettingsApi.fromJson`.
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  String toString() {
    return 'CompanyEnvelopeApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, customFields: $customFields, sizeId: $sizeId, industryId: $industryId, legalEntityId: $legalEntityId, enabledModules: $enabledModules, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyEnvelopeApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.companyKey, companyKey) ||
                other.companyKey == companyKey) &&
            const DeepCollectionEquality().equals(
              other._customFields,
              _customFields,
            ) &&
            (identical(other.sizeId, sizeId) || other.sizeId == sizeId) &&
            (identical(other.industryId, industryId) ||
                other.industryId == industryId) &&
            (identical(other.legalEntityId, legalEntityId) ||
                other.legalEntityId == legalEntityId) &&
            (identical(other.enabledModules, enabledModules) ||
                other.enabledModules == enabledModules) &&
            const DeepCollectionEquality().equals(other._settings, _settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    name,
    companyKey,
    const DeepCollectionEquality().hash(_customFields),
    sizeId,
    industryId,
    legalEntityId,
    enabledModules,
    const DeepCollectionEquality().hash(_settings),
  );

  /// Create a copy of CompanyEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyEnvelopeApiImplCopyWith<_$CompanyEnvelopeApiImpl> get copyWith =>
      __$$CompanyEnvelopeApiImplCopyWithImpl<_$CompanyEnvelopeApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyEnvelopeApiImplToJson(this);
  }
}

abstract class _CompanyEnvelopeApi implements CompanyEnvelopeApi {
  const factory _CompanyEnvelopeApi({
    final String id,
    @JsonKey(name: 'display_name') final String displayName,
    final String name,
    @JsonKey(name: 'company_key') final String companyKey,
    @JsonKey(name: 'custom_fields') final Map<String, String> customFields,
    @JsonKey(name: 'size_id') final String sizeId,
    @JsonKey(name: 'industry_id') final String industryId,
    @JsonKey(name: 'legal_entity_id') final int legalEntityId,
    @JsonKey(name: 'enabled_modules') final int enabledModules,
    final Map<String, dynamic> settings,
  }) = _$CompanyEnvelopeApiImpl;

  factory _CompanyEnvelopeApi.fromJson(Map<String, dynamic> json) =
      _$CompanyEnvelopeApiImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String get name;
  @override
  @JsonKey(name: 'company_key')
  String get companyKey;
  @override
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields;
  @override
  @JsonKey(name: 'size_id')
  String get sizeId;
  @override
  @JsonKey(name: 'industry_id')
  String get industryId;
  @override
  @JsonKey(name: 'legal_entity_id')
  int get legalEntityId;
  @override
  @JsonKey(name: 'enabled_modules')
  int get enabledModules; // `settings` stays as a raw map — every key the server sends is
  // preserved verbatim through the round-trip. Strong-typing here would
  // drop unknown keys at fromJson/toJson, silently corrupting fields
  // we haven't modeled yet. The repository builds the typed view on
  // demand via `CompanySettingsApi.fromJson`.
  @override
  Map<String, dynamic> get settings;

  /// Create a copy of CompanyEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyEnvelopeApiImplCopyWith<_$CompanyEnvelopeApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TokenApi _$TokenApiFromJson(Map<String, dynamic> json) {
  return _TokenApi.fromJson(json);
}

/// @nodoc
mixin _$TokenApi {
  String get token => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this TokenApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TokenApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TokenApiCopyWith<TokenApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TokenApiCopyWith<$Res> {
  factory $TokenApiCopyWith(TokenApi value, $Res Function(TokenApi) then) =
      _$TokenApiCopyWithImpl<$Res, TokenApi>;
  @useResult
  $Res call({String token, String name});
}

/// @nodoc
class _$TokenApiCopyWithImpl<$Res, $Val extends TokenApi>
    implements $TokenApiCopyWith<$Res> {
  _$TokenApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TokenApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? token = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TokenApiImplCopyWith<$Res>
    implements $TokenApiCopyWith<$Res> {
  factory _$$TokenApiImplCopyWith(
    _$TokenApiImpl value,
    $Res Function(_$TokenApiImpl) then,
  ) = __$$TokenApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String token, String name});
}

/// @nodoc
class __$$TokenApiImplCopyWithImpl<$Res>
    extends _$TokenApiCopyWithImpl<$Res, _$TokenApiImpl>
    implements _$$TokenApiImplCopyWith<$Res> {
  __$$TokenApiImplCopyWithImpl(
    _$TokenApiImpl _value,
    $Res Function(_$TokenApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TokenApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? token = null, Object? name = null}) {
    return _then(
      _$TokenApiImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TokenApiImpl implements _TokenApi {
  const _$TokenApiImpl({this.token = '', this.name = ''});

  factory _$TokenApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$TokenApiImplFromJson(json);

  @override
  @JsonKey()
  final String token;
  @override
  @JsonKey()
  final String name;

  @override
  String toString() {
    return 'TokenApi(token: $token, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TokenApiImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, token, name);

  /// Create a copy of TokenApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TokenApiImplCopyWith<_$TokenApiImpl> get copyWith =>
      __$$TokenApiImplCopyWithImpl<_$TokenApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TokenApiImplToJson(this);
  }
}

abstract class _TokenApi implements TokenApi {
  const factory _TokenApi({final String token, final String name}) =
      _$TokenApiImpl;

  factory _TokenApi.fromJson(Map<String, dynamic> json) =
      _$TokenApiImpl.fromJson;

  @override
  String get token;
  @override
  String get name;

  /// Create a copy of TokenApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TokenApiImplCopyWith<_$TokenApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccountEnvelopeApi _$AccountEnvelopeApiFromJson(Map<String, dynamic> json) {
  return _AccountEnvelopeApi.fromJson(json);
}

/// @nodoc
mixin _$AccountEnvelopeApi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_company_id')
  String get defaultCompanyId => throw _privateConstructorUsedError;
  String get plan => throw _privateConstructorUsedError;
  @JsonKey(name: 'num_trial_days')
  int get numTrialDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'hosted_client_count')
  int get hostedClientCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'hosted_company_count')
  int get hostedCompanyCount => throw _privateConstructorUsedError;

  /// Serializes this AccountEnvelopeApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountEnvelopeApiCopyWith<AccountEnvelopeApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountEnvelopeApiCopyWith<$Res> {
  factory $AccountEnvelopeApiCopyWith(
    AccountEnvelopeApi value,
    $Res Function(AccountEnvelopeApi) then,
  ) = _$AccountEnvelopeApiCopyWithImpl<$Res, AccountEnvelopeApi>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'default_company_id') String defaultCompanyId,
    String plan,
    @JsonKey(name: 'num_trial_days') int numTrialDays,
    @JsonKey(name: 'hosted_client_count') int hostedClientCount,
    @JsonKey(name: 'hosted_company_count') int hostedCompanyCount,
  });
}

/// @nodoc
class _$AccountEnvelopeApiCopyWithImpl<$Res, $Val extends AccountEnvelopeApi>
    implements $AccountEnvelopeApiCopyWith<$Res> {
  _$AccountEnvelopeApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? defaultCompanyId = null,
    Object? plan = null,
    Object? numTrialDays = null,
    Object? hostedClientCount = null,
    Object? hostedCompanyCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            defaultCompanyId: null == defaultCompanyId
                ? _value.defaultCompanyId
                : defaultCompanyId // ignore: cast_nullable_to_non_nullable
                      as String,
            plan: null == plan
                ? _value.plan
                : plan // ignore: cast_nullable_to_non_nullable
                      as String,
            numTrialDays: null == numTrialDays
                ? _value.numTrialDays
                : numTrialDays // ignore: cast_nullable_to_non_nullable
                      as int,
            hostedClientCount: null == hostedClientCount
                ? _value.hostedClientCount
                : hostedClientCount // ignore: cast_nullable_to_non_nullable
                      as int,
            hostedCompanyCount: null == hostedCompanyCount
                ? _value.hostedCompanyCount
                : hostedCompanyCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountEnvelopeApiImplCopyWith<$Res>
    implements $AccountEnvelopeApiCopyWith<$Res> {
  factory _$$AccountEnvelopeApiImplCopyWith(
    _$AccountEnvelopeApiImpl value,
    $Res Function(_$AccountEnvelopeApiImpl) then,
  ) = __$$AccountEnvelopeApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'default_company_id') String defaultCompanyId,
    String plan,
    @JsonKey(name: 'num_trial_days') int numTrialDays,
    @JsonKey(name: 'hosted_client_count') int hostedClientCount,
    @JsonKey(name: 'hosted_company_count') int hostedCompanyCount,
  });
}

/// @nodoc
class __$$AccountEnvelopeApiImplCopyWithImpl<$Res>
    extends _$AccountEnvelopeApiCopyWithImpl<$Res, _$AccountEnvelopeApiImpl>
    implements _$$AccountEnvelopeApiImplCopyWith<$Res> {
  __$$AccountEnvelopeApiImplCopyWithImpl(
    _$AccountEnvelopeApiImpl _value,
    $Res Function(_$AccountEnvelopeApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? defaultCompanyId = null,
    Object? plan = null,
    Object? numTrialDays = null,
    Object? hostedClientCount = null,
    Object? hostedCompanyCount = null,
  }) {
    return _then(
      _$AccountEnvelopeApiImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultCompanyId: null == defaultCompanyId
            ? _value.defaultCompanyId
            : defaultCompanyId // ignore: cast_nullable_to_non_nullable
                  as String,
        plan: null == plan
            ? _value.plan
            : plan // ignore: cast_nullable_to_non_nullable
                  as String,
        numTrialDays: null == numTrialDays
            ? _value.numTrialDays
            : numTrialDays // ignore: cast_nullable_to_non_nullable
                  as int,
        hostedClientCount: null == hostedClientCount
            ? _value.hostedClientCount
            : hostedClientCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hostedCompanyCount: null == hostedCompanyCount
            ? _value.hostedCompanyCount
            : hostedCompanyCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountEnvelopeApiImpl implements _AccountEnvelopeApi {
  const _$AccountEnvelopeApiImpl({
    this.id = '',
    @JsonKey(name: 'default_company_id') this.defaultCompanyId = '',
    this.plan = '',
    @JsonKey(name: 'num_trial_days') this.numTrialDays = 0,
    @JsonKey(name: 'hosted_client_count') this.hostedClientCount = 0,
    @JsonKey(name: 'hosted_company_count') this.hostedCompanyCount = 0,
  });

  factory _$AccountEnvelopeApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountEnvelopeApiImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey(name: 'default_company_id')
  final String defaultCompanyId;
  @override
  @JsonKey()
  final String plan;
  @override
  @JsonKey(name: 'num_trial_days')
  final int numTrialDays;
  @override
  @JsonKey(name: 'hosted_client_count')
  final int hostedClientCount;
  @override
  @JsonKey(name: 'hosted_company_count')
  final int hostedCompanyCount;

  @override
  String toString() {
    return 'AccountEnvelopeApi(id: $id, defaultCompanyId: $defaultCompanyId, plan: $plan, numTrialDays: $numTrialDays, hostedClientCount: $hostedClientCount, hostedCompanyCount: $hostedCompanyCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountEnvelopeApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.defaultCompanyId, defaultCompanyId) ||
                other.defaultCompanyId == defaultCompanyId) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.numTrialDays, numTrialDays) ||
                other.numTrialDays == numTrialDays) &&
            (identical(other.hostedClientCount, hostedClientCount) ||
                other.hostedClientCount == hostedClientCount) &&
            (identical(other.hostedCompanyCount, hostedCompanyCount) ||
                other.hostedCompanyCount == hostedCompanyCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    defaultCompanyId,
    plan,
    numTrialDays,
    hostedClientCount,
    hostedCompanyCount,
  );

  /// Create a copy of AccountEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountEnvelopeApiImplCopyWith<_$AccountEnvelopeApiImpl> get copyWith =>
      __$$AccountEnvelopeApiImplCopyWithImpl<_$AccountEnvelopeApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountEnvelopeApiImplToJson(this);
  }
}

abstract class _AccountEnvelopeApi implements AccountEnvelopeApi {
  const factory _AccountEnvelopeApi({
    final String id,
    @JsonKey(name: 'default_company_id') final String defaultCompanyId,
    final String plan,
    @JsonKey(name: 'num_trial_days') final int numTrialDays,
    @JsonKey(name: 'hosted_client_count') final int hostedClientCount,
    @JsonKey(name: 'hosted_company_count') final int hostedCompanyCount,
  }) = _$AccountEnvelopeApiImpl;

  factory _AccountEnvelopeApi.fromJson(Map<String, dynamic> json) =
      _$AccountEnvelopeApiImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'default_company_id')
  String get defaultCompanyId;
  @override
  String get plan;
  @override
  @JsonKey(name: 'num_trial_days')
  int get numTrialDays;
  @override
  @JsonKey(name: 'hosted_client_count')
  int get hostedClientCount;
  @override
  @JsonKey(name: 'hosted_company_count')
  int get hostedCompanyCount;

  /// Create a copy of AccountEnvelopeApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountEnvelopeApiImplCopyWith<_$AccountEnvelopeApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
