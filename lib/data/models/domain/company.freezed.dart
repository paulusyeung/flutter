// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Company {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get companyKey => throw _privateConstructorUsedError;
  String get sizeId => throw _privateConstructorUsedError;
  String get industryId => throw _privateConstructorUsedError;
  String get firstMonthOfYear => throw _privateConstructorUsedError;
  String get firstDayOfWeek => throw _privateConstructorUsedError;
  int get enabledModules => throw _privateConstructorUsedError;
  int get legalEntityId => throw _privateConstructorUsedError;
  String get subdomain => throw _privateConstructorUsedError;
  String get portalDomain => throw _privateConstructorUsedError;
  String get portalMode => throw _privateConstructorUsedError;
  Map<String, String> get customFields => throw _privateConstructorUsedError;
  Map<String, dynamic> get rawSettings => throw _privateConstructorUsedError;
  CompanySettingsApi get settings => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;
  int get archivedAt => throw _privateConstructorUsedError;

  /// Create a copy of Company
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyCopyWith<Company> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyCopyWith<$Res> {
  factory $CompanyCopyWith(Company value, $Res Function(Company) then) =
      _$CompanyCopyWithImpl<$Res, Company>;
  @useResult
  $Res call({
    String id,
    String displayName,
    String name,
    String companyKey,
    String sizeId,
    String industryId,
    String firstMonthOfYear,
    String firstDayOfWeek,
    int enabledModules,
    int legalEntityId,
    String subdomain,
    String portalDomain,
    String portalMode,
    Map<String, String> customFields,
    Map<String, dynamic> rawSettings,
    CompanySettingsApi settings,
    int updatedAt,
    int archivedAt,
  });

  $CompanySettingsApiCopyWith<$Res> get settings;
}

/// @nodoc
class _$CompanyCopyWithImpl<$Res, $Val extends Company>
    implements $CompanyCopyWith<$Res> {
  _$CompanyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Company
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
    Object? rawSettings = null,
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
            rawSettings: null == rawSettings
                ? _value.rawSettings
                : rawSettings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as CompanySettingsApi,
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

  /// Create a copy of Company
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompanySettingsApiCopyWith<$Res> get settings {
    return $CompanySettingsApiCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompanyImplCopyWith<$Res> implements $CompanyCopyWith<$Res> {
  factory _$$CompanyImplCopyWith(
    _$CompanyImpl value,
    $Res Function(_$CompanyImpl) then,
  ) = __$$CompanyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    String name,
    String companyKey,
    String sizeId,
    String industryId,
    String firstMonthOfYear,
    String firstDayOfWeek,
    int enabledModules,
    int legalEntityId,
    String subdomain,
    String portalDomain,
    String portalMode,
    Map<String, String> customFields,
    Map<String, dynamic> rawSettings,
    CompanySettingsApi settings,
    int updatedAt,
    int archivedAt,
  });

  @override
  $CompanySettingsApiCopyWith<$Res> get settings;
}

/// @nodoc
class __$$CompanyImplCopyWithImpl<$Res>
    extends _$CompanyCopyWithImpl<$Res, _$CompanyImpl>
    implements _$$CompanyImplCopyWith<$Res> {
  __$$CompanyImplCopyWithImpl(
    _$CompanyImpl _value,
    $Res Function(_$CompanyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Company
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
    Object? rawSettings = null,
    Object? settings = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
  }) {
    return _then(
      _$CompanyImpl(
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
        rawSettings: null == rawSettings
            ? _value._rawSettings
            : rawSettings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        settings: null == settings
            ? _value.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as CompanySettingsApi,
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

class _$CompanyImpl extends _Company {
  const _$CompanyImpl({
    this.id = '',
    this.displayName = '',
    this.name = '',
    this.companyKey = '',
    this.sizeId = '',
    this.industryId = '',
    this.firstMonthOfYear = '',
    this.firstDayOfWeek = '',
    this.enabledModules = 0,
    this.legalEntityId = 0,
    this.subdomain = '',
    this.portalDomain = '',
    this.portalMode = '',
    final Map<String, String> customFields = const <String, String>{},
    final Map<String, dynamic> rawSettings = const <String, dynamic>{},
    this.settings = const CompanySettings(),
    this.updatedAt = 0,
    this.archivedAt = 0,
  }) : _customFields = customFields,
       _rawSettings = rawSettings,
       super._();

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String displayName;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String companyKey;
  @override
  @JsonKey()
  final String sizeId;
  @override
  @JsonKey()
  final String industryId;
  @override
  @JsonKey()
  final String firstMonthOfYear;
  @override
  @JsonKey()
  final String firstDayOfWeek;
  @override
  @JsonKey()
  final int enabledModules;
  @override
  @JsonKey()
  final int legalEntityId;
  @override
  @JsonKey()
  final String subdomain;
  @override
  @JsonKey()
  final String portalDomain;
  @override
  @JsonKey()
  final String portalMode;
  final Map<String, String> _customFields;
  @override
  @JsonKey()
  Map<String, String> get customFields {
    if (_customFields is EqualUnmodifiableMapView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customFields);
  }

  final Map<String, dynamic> _rawSettings;
  @override
  @JsonKey()
  Map<String, dynamic> get rawSettings {
    if (_rawSettings is EqualUnmodifiableMapView) return _rawSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_rawSettings);
  }

  @override
  @JsonKey()
  final CompanySettingsApi settings;
  @override
  @JsonKey()
  final int updatedAt;
  @override
  @JsonKey()
  final int archivedAt;

  @override
  String toString() {
    return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, updatedAt: $updatedAt, archivedAt: $archivedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyImpl &&
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
            const DeepCollectionEquality().equals(
              other._rawSettings,
              _rawSettings,
            ) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt));
  }

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
    const DeepCollectionEquality().hash(_rawSettings),
    settings,
    updatedAt,
    archivedAt,
  );

  /// Create a copy of Company
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyImplCopyWith<_$CompanyImpl> get copyWith =>
      __$$CompanyImplCopyWithImpl<_$CompanyImpl>(this, _$identity);
}

abstract class _Company extends Company {
  const factory _Company({
    final String id,
    final String displayName,
    final String name,
    final String companyKey,
    final String sizeId,
    final String industryId,
    final String firstMonthOfYear,
    final String firstDayOfWeek,
    final int enabledModules,
    final int legalEntityId,
    final String subdomain,
    final String portalDomain,
    final String portalMode,
    final Map<String, String> customFields,
    final Map<String, dynamic> rawSettings,
    final CompanySettingsApi settings,
    final int updatedAt,
    final int archivedAt,
  }) = _$CompanyImpl;
  const _Company._() : super._();

  @override
  String get id;
  @override
  String get displayName;
  @override
  String get name;
  @override
  String get companyKey;
  @override
  String get sizeId;
  @override
  String get industryId;
  @override
  String get firstMonthOfYear;
  @override
  String get firstDayOfWeek;
  @override
  int get enabledModules;
  @override
  int get legalEntityId;
  @override
  String get subdomain;
  @override
  String get portalDomain;
  @override
  String get portalMode;
  @override
  Map<String, String> get customFields;
  @override
  Map<String, dynamic> get rawSettings;
  @override
  CompanySettingsApi get settings;
  @override
  int get updatedAt;
  @override
  int get archivedAt;

  /// Create a copy of Company
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyImplCopyWith<_$CompanyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
