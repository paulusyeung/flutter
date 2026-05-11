// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CompanyApi _$CompanyApiFromJson(Map<String, dynamic> json) {
  return _CompanyApi.fromJson(json);
}

/// @nodoc
mixin _$CompanyApi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'company_key')
  String get companyKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_id')
  String get sizeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'industry_id')
  String get industryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_month_of_year')
  String get firstMonthOfYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_day_of_week')
  String get firstDayOfWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'enabled_modules')
  int get enabledModules => throw _privateConstructorUsedError;
  @JsonKey(name: 'legal_entity_id')
  int get legalEntityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'subdomain')
  String get subdomain => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_domain')
  String get portalDomain => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_mode')
  String get portalMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields => throw _privateConstructorUsedError;
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'archived_at')
  int get archivedAt => throw _privateConstructorUsedError;

  /// Serializes this CompanyApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyApiCopyWith<CompanyApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyApiCopyWith<$Res> {
  factory $CompanyApiCopyWith(
    CompanyApi value,
    $Res Function(CompanyApi) then,
  ) = _$CompanyApiCopyWithImpl<$Res, CompanyApi>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'display_name') String displayName,
    String name,
    @JsonKey(name: 'company_key') String companyKey,
    @JsonKey(name: 'size_id') String sizeId,
    @JsonKey(name: 'industry_id') String industryId,
    @JsonKey(name: 'first_month_of_year') String firstMonthOfYear,
    @JsonKey(name: 'first_day_of_week') String firstDayOfWeek,
    @JsonKey(name: 'enabled_modules') int enabledModules,
    @JsonKey(name: 'legal_entity_id') int legalEntityId,
    @JsonKey(name: 'subdomain') String subdomain,
    @JsonKey(name: 'portal_domain') String portalDomain,
    @JsonKey(name: 'portal_mode') String portalMode,
    @JsonKey(name: 'custom_fields') Map<String, String> customFields,
    Map<String, dynamic> settings,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
  });
}

/// @nodoc
class _$CompanyApiCopyWithImpl<$Res, $Val extends CompanyApi>
    implements $CompanyApiCopyWith<$Res> {
  _$CompanyApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? name = null,
    Object? companyKey = null,
    Object? sizeId = null,
    Object? industryId = null,
    Object? firstMonthOfYear = null,
    Object? firstDayOfWeek = null,
    Object? enabledModules = null,
    Object? legalEntityId = null,
    Object? subdomain = null,
    Object? portalDomain = null,
    Object? portalMode = null,
    Object? customFields = null,
    Object? settings = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
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
            sizeId: null == sizeId
                ? _value.sizeId
                : sizeId // ignore: cast_nullable_to_non_nullable
                      as String,
            industryId: null == industryId
                ? _value.industryId
                : industryId // ignore: cast_nullable_to_non_nullable
                      as String,
            firstMonthOfYear: null == firstMonthOfYear
                ? _value.firstMonthOfYear
                : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
                      as String,
            firstDayOfWeek: null == firstDayOfWeek
                ? _value.firstDayOfWeek
                : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
                      as String,
            enabledModules: null == enabledModules
                ? _value.enabledModules
                : enabledModules // ignore: cast_nullable_to_non_nullable
                      as int,
            legalEntityId: null == legalEntityId
                ? _value.legalEntityId
                : legalEntityId // ignore: cast_nullable_to_non_nullable
                      as int,
            subdomain: null == subdomain
                ? _value.subdomain
                : subdomain // ignore: cast_nullable_to_non_nullable
                      as String,
            portalDomain: null == portalDomain
                ? _value.portalDomain
                : portalDomain // ignore: cast_nullable_to_non_nullable
                      as String,
            portalMode: null == portalMode
                ? _value.portalMode
                : portalMode // ignore: cast_nullable_to_non_nullable
                      as String,
            customFields: null == customFields
                ? _value.customFields
                : customFields // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            archivedAt: null == archivedAt
                ? _value.archivedAt
                : archivedAt // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanyApiImplCopyWith<$Res>
    implements $CompanyApiCopyWith<$Res> {
  factory _$$CompanyApiImplCopyWith(
    _$CompanyApiImpl value,
    $Res Function(_$CompanyApiImpl) then,
  ) = __$$CompanyApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'display_name') String displayName,
    String name,
    @JsonKey(name: 'company_key') String companyKey,
    @JsonKey(name: 'size_id') String sizeId,
    @JsonKey(name: 'industry_id') String industryId,
    @JsonKey(name: 'first_month_of_year') String firstMonthOfYear,
    @JsonKey(name: 'first_day_of_week') String firstDayOfWeek,
    @JsonKey(name: 'enabled_modules') int enabledModules,
    @JsonKey(name: 'legal_entity_id') int legalEntityId,
    @JsonKey(name: 'subdomain') String subdomain,
    @JsonKey(name: 'portal_domain') String portalDomain,
    @JsonKey(name: 'portal_mode') String portalMode,
    @JsonKey(name: 'custom_fields') Map<String, String> customFields,
    Map<String, dynamic> settings,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
  });
}

/// @nodoc
class __$$CompanyApiImplCopyWithImpl<$Res>
    extends _$CompanyApiCopyWithImpl<$Res, _$CompanyApiImpl>
    implements _$$CompanyApiImplCopyWith<$Res> {
  __$$CompanyApiImplCopyWithImpl(
    _$CompanyApiImpl _value,
    $Res Function(_$CompanyApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? name = null,
    Object? companyKey = null,
    Object? sizeId = null,
    Object? industryId = null,
    Object? firstMonthOfYear = null,
    Object? firstDayOfWeek = null,
    Object? enabledModules = null,
    Object? legalEntityId = null,
    Object? subdomain = null,
    Object? portalDomain = null,
    Object? portalMode = null,
    Object? customFields = null,
    Object? settings = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
  }) {
    return _then(
      _$CompanyApiImpl(
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
        sizeId: null == sizeId
            ? _value.sizeId
            : sizeId // ignore: cast_nullable_to_non_nullable
                  as String,
        industryId: null == industryId
            ? _value.industryId
            : industryId // ignore: cast_nullable_to_non_nullable
                  as String,
        firstMonthOfYear: null == firstMonthOfYear
            ? _value.firstMonthOfYear
            : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
                  as String,
        firstDayOfWeek: null == firstDayOfWeek
            ? _value.firstDayOfWeek
            : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
                  as String,
        enabledModules: null == enabledModules
            ? _value.enabledModules
            : enabledModules // ignore: cast_nullable_to_non_nullable
                  as int,
        legalEntityId: null == legalEntityId
            ? _value.legalEntityId
            : legalEntityId // ignore: cast_nullable_to_non_nullable
                  as int,
        subdomain: null == subdomain
            ? _value.subdomain
            : subdomain // ignore: cast_nullable_to_non_nullable
                  as String,
        portalDomain: null == portalDomain
            ? _value.portalDomain
            : portalDomain // ignore: cast_nullable_to_non_nullable
                  as String,
        portalMode: null == portalMode
            ? _value.portalMode
            : portalMode // ignore: cast_nullable_to_non_nullable
                  as String,
        customFields: null == customFields
            ? _value._customFields
            : customFields // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        settings: null == settings
            ? _value._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        archivedAt: null == archivedAt
            ? _value.archivedAt
            : archivedAt // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _$CompanyApiImpl implements _CompanyApi {
  const _$CompanyApiImpl({
    this.id = '',
    @JsonKey(name: 'display_name') this.displayName = '',
    this.name = '',
    @JsonKey(name: 'company_key') this.companyKey = '',
    @JsonKey(name: 'size_id') this.sizeId = '',
    @JsonKey(name: 'industry_id') this.industryId = '',
    @JsonKey(name: 'first_month_of_year') this.firstMonthOfYear = '',
    @JsonKey(name: 'first_day_of_week') this.firstDayOfWeek = '',
    @JsonKey(name: 'enabled_modules') this.enabledModules = 0,
    @JsonKey(name: 'legal_entity_id') this.legalEntityId = 0,
    @JsonKey(name: 'subdomain') this.subdomain = '',
    @JsonKey(name: 'portal_domain') this.portalDomain = '',
    @JsonKey(name: 'portal_mode') this.portalMode = '',
    @JsonKey(name: 'custom_fields')
    final Map<String, String> customFields = const <String, String>{},
    final Map<String, dynamic> settings = const <String, dynamic>{},
    @JsonKey(name: 'updated_at') this.updatedAt = 0,
    @JsonKey(name: 'archived_at') this.archivedAt = 0,
  }) : _customFields = customFields,
       _settings = settings;

  factory _$CompanyApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyApiImplFromJson(json);

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
  @override
  @JsonKey(name: 'size_id')
  final String sizeId;
  @override
  @JsonKey(name: 'industry_id')
  final String industryId;
  @override
  @JsonKey(name: 'first_month_of_year')
  final String firstMonthOfYear;
  @override
  @JsonKey(name: 'first_day_of_week')
  final String firstDayOfWeek;
  @override
  @JsonKey(name: 'enabled_modules')
  final int enabledModules;
  @override
  @JsonKey(name: 'legal_entity_id')
  final int legalEntityId;
  @override
  @JsonKey(name: 'subdomain')
  final String subdomain;
  @override
  @JsonKey(name: 'portal_domain')
  final String portalDomain;
  @override
  @JsonKey(name: 'portal_mode')
  final String portalMode;
  final Map<String, String> _customFields;
  @override
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields {
    if (_customFields is EqualUnmodifiableMapView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customFields);
  }

  final Map<String, dynamic> _settings;
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  @override
  @JsonKey(name: 'archived_at')
  final int archivedAt;

  @override
  String toString() {
    return 'CompanyApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, settings: $settings, updatedAt: $updatedAt, archivedAt: $archivedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.companyKey, companyKey) ||
                other.companyKey == companyKey) &&
            (identical(other.sizeId, sizeId) || other.sizeId == sizeId) &&
            (identical(other.industryId, industryId) ||
                other.industryId == industryId) &&
            (identical(other.firstMonthOfYear, firstMonthOfYear) ||
                other.firstMonthOfYear == firstMonthOfYear) &&
            (identical(other.firstDayOfWeek, firstDayOfWeek) ||
                other.firstDayOfWeek == firstDayOfWeek) &&
            (identical(other.enabledModules, enabledModules) ||
                other.enabledModules == enabledModules) &&
            (identical(other.legalEntityId, legalEntityId) ||
                other.legalEntityId == legalEntityId) &&
            (identical(other.subdomain, subdomain) ||
                other.subdomain == subdomain) &&
            (identical(other.portalDomain, portalDomain) ||
                other.portalDomain == portalDomain) &&
            (identical(other.portalMode, portalMode) ||
                other.portalMode == portalMode) &&
            const DeepCollectionEquality().equals(
              other._customFields,
              _customFields,
            ) &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    name,
    companyKey,
    sizeId,
    industryId,
    firstMonthOfYear,
    firstDayOfWeek,
    enabledModules,
    legalEntityId,
    subdomain,
    portalDomain,
    portalMode,
    const DeepCollectionEquality().hash(_customFields),
    const DeepCollectionEquality().hash(_settings),
    updatedAt,
    archivedAt,
  );

  /// Create a copy of CompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyApiImplCopyWith<_$CompanyApiImpl> get copyWith =>
      __$$CompanyApiImplCopyWithImpl<_$CompanyApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyApiImplToJson(this);
  }
}

abstract class _CompanyApi implements CompanyApi {
  const factory _CompanyApi({
    final String id,
    @JsonKey(name: 'display_name') final String displayName,
    final String name,
    @JsonKey(name: 'company_key') final String companyKey,
    @JsonKey(name: 'size_id') final String sizeId,
    @JsonKey(name: 'industry_id') final String industryId,
    @JsonKey(name: 'first_month_of_year') final String firstMonthOfYear,
    @JsonKey(name: 'first_day_of_week') final String firstDayOfWeek,
    @JsonKey(name: 'enabled_modules') final int enabledModules,
    @JsonKey(name: 'legal_entity_id') final int legalEntityId,
    @JsonKey(name: 'subdomain') final String subdomain,
    @JsonKey(name: 'portal_domain') final String portalDomain,
    @JsonKey(name: 'portal_mode') final String portalMode,
    @JsonKey(name: 'custom_fields') final Map<String, String> customFields,
    final Map<String, dynamic> settings,
    @JsonKey(name: 'updated_at') final int updatedAt,
    @JsonKey(name: 'archived_at') final int archivedAt,
  }) = _$CompanyApiImpl;

  factory _CompanyApi.fromJson(Map<String, dynamic> json) =
      _$CompanyApiImpl.fromJson;

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
  @JsonKey(name: 'size_id')
  String get sizeId;
  @override
  @JsonKey(name: 'industry_id')
  String get industryId;
  @override
  @JsonKey(name: 'first_month_of_year')
  String get firstMonthOfYear;
  @override
  @JsonKey(name: 'first_day_of_week')
  String get firstDayOfWeek;
  @override
  @JsonKey(name: 'enabled_modules')
  int get enabledModules;
  @override
  @JsonKey(name: 'legal_entity_id')
  int get legalEntityId;
  @override
  @JsonKey(name: 'subdomain')
  String get subdomain;
  @override
  @JsonKey(name: 'portal_domain')
  String get portalDomain;
  @override
  @JsonKey(name: 'portal_mode')
  String get portalMode;
  @override
  @JsonKey(name: 'custom_fields')
  Map<String, String> get customFields;
  @override
  Map<String, dynamic> get settings;
  @override
  @JsonKey(name: 'updated_at')
  int get updatedAt;
  @override
  @JsonKey(name: 'archived_at')
  int get archivedAt;

  /// Create a copy of CompanyApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyApiImplCopyWith<_$CompanyApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanyItemApi _$CompanyItemApiFromJson(Map<String, dynamic> json) {
  return _CompanyItemApi.fromJson(json);
}

/// @nodoc
mixin _$CompanyItemApi {
  CompanyApi get data => throw _privateConstructorUsedError;

  /// Serializes this CompanyItemApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyItemApiCopyWith<CompanyItemApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyItemApiCopyWith<$Res> {
  factory $CompanyItemApiCopyWith(
    CompanyItemApi value,
    $Res Function(CompanyItemApi) then,
  ) = _$CompanyItemApiCopyWithImpl<$Res, CompanyItemApi>;
  @useResult
  $Res call({CompanyApi data});

  $CompanyApiCopyWith<$Res> get data;
}

/// @nodoc
class _$CompanyItemApiCopyWithImpl<$Res, $Val extends CompanyItemApi>
    implements $CompanyItemApiCopyWith<$Res> {
  _$CompanyItemApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as CompanyApi,
          )
          as $Val,
    );
  }

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompanyApiCopyWith<$Res> get data {
    return $CompanyApiCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompanyItemApiImplCopyWith<$Res>
    implements $CompanyItemApiCopyWith<$Res> {
  factory _$$CompanyItemApiImplCopyWith(
    _$CompanyItemApiImpl value,
    $Res Function(_$CompanyItemApiImpl) then,
  ) = __$$CompanyItemApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({CompanyApi data});

  @override
  $CompanyApiCopyWith<$Res> get data;
}

/// @nodoc
class __$$CompanyItemApiImplCopyWithImpl<$Res>
    extends _$CompanyItemApiCopyWithImpl<$Res, _$CompanyItemApiImpl>
    implements _$$CompanyItemApiImplCopyWith<$Res> {
  __$$CompanyItemApiImplCopyWithImpl(
    _$CompanyItemApiImpl _value,
    $Res Function(_$CompanyItemApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$CompanyItemApiImpl(
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as CompanyApi,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanyItemApiImpl implements _CompanyItemApi {
  const _$CompanyItemApiImpl({required this.data});

  factory _$CompanyItemApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyItemApiImplFromJson(json);

  @override
  final CompanyApi data;

  @override
  String toString() {
    return 'CompanyItemApi(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyItemApiImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyItemApiImplCopyWith<_$CompanyItemApiImpl> get copyWith =>
      __$$CompanyItemApiImplCopyWithImpl<_$CompanyItemApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyItemApiImplToJson(this);
  }
}

abstract class _CompanyItemApi implements CompanyItemApi {
  const factory _CompanyItemApi({required final CompanyApi data}) =
      _$CompanyItemApiImpl;

  factory _CompanyItemApi.fromJson(Map<String, dynamic> json) =
      _$CompanyItemApiImpl.fromJson;

  @override
  CompanyApi get data;

  /// Create a copy of CompanyItemApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyItemApiImplCopyWith<_$CompanyItemApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
