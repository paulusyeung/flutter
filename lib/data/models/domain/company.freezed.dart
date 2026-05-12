// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Company {

 String get id; String get displayName; String get name; String get companyKey; String get sizeId; String get industryId; String get firstMonthOfYear; String get firstDayOfWeek; int get enabledModules; int get legalEntityId; String get subdomain; String get portalDomain; String get portalMode; Map<String, String> get customFields; Map<String, dynamic> get rawSettings; CompanySettings get settings; int get updatedAt; int get archivedAt;
/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyCopyWith<Company> get copyWith => _$CompanyCopyWithImpl<Company>(this as Company, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&const DeepCollectionEquality().equals(other.rawSettings, rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(customFields),const DeepCollectionEquality().hash(rawSettings),settings,updatedAt,archivedAt);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class $CompanyCopyWith<$Res>  {
  factory $CompanyCopyWith(Company value, $Res Function(Company) _then) = _$CompanyCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, int updatedAt, int archivedAt
});


$CompanySettingsApiCopyWith<$Res> get settings;

}
/// @nodoc
class _$CompanyCopyWithImpl<$Res>
    implements $CompanyCopyWith<$Res> {
  _$CompanyCopyWithImpl(this._self, this._then);

  final Company _self;
  final $Res Function(Company) _then;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? updatedAt = null,Object? archivedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,firstMonthOfYear: null == firstMonthOfYear ? _self.firstMonthOfYear : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
as String,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as String,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,portalDomain: null == portalDomain ? _self.portalDomain : portalDomain // ignore: cast_nullable_to_non_nullable
as String,portalMode: null == portalMode ? _self.portalMode : portalMode // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,rawSettings: null == rawSettings ? _self.rawSettings : rawSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompanySettings,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanySettingsApiCopyWith<$Res> get settings {
  
  return $CompanySettingsApiCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [Company].
extension CompanyPatterns on Company {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Company value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Company() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Company value)  $default,){
final _that = this;
switch (_that) {
case _Company():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Company value)?  $default,){
final _that = this;
switch (_that) {
case _Company() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  int updatedAt,  int archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  int updatedAt,  int archivedAt)  $default,) {final _that = this;
switch (_that) {
case _Company():
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  int updatedAt,  int archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.updatedAt,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Company extends Company {
  const _Company({this.id = '', this.displayName = '', this.name = '', this.companyKey = '', this.sizeId = '', this.industryId = '', this.firstMonthOfYear = '', this.firstDayOfWeek = '', this.enabledModules = 0, this.legalEntityId = 0, this.subdomain = '', this.portalDomain = '', this.portalMode = '', final  Map<String, String> customFields = const <String, String>{}, final  Map<String, dynamic> rawSettings = const <String, dynamic>{}, this.settings = const CompanySettings(), this.updatedAt = 0, this.archivedAt = 0}): _customFields = customFields,_rawSettings = rawSettings,super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String name;
@override@JsonKey() final  String companyKey;
@override@JsonKey() final  String sizeId;
@override@JsonKey() final  String industryId;
@override@JsonKey() final  String firstMonthOfYear;
@override@JsonKey() final  String firstDayOfWeek;
@override@JsonKey() final  int enabledModules;
@override@JsonKey() final  int legalEntityId;
@override@JsonKey() final  String subdomain;
@override@JsonKey() final  String portalDomain;
@override@JsonKey() final  String portalMode;
 final  Map<String, String> _customFields;
@override@JsonKey() Map<String, String> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

 final  Map<String, dynamic> _rawSettings;
@override@JsonKey() Map<String, dynamic> get rawSettings {
  if (_rawSettings is EqualUnmodifiableMapView) return _rawSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rawSettings);
}

@override@JsonKey() final  CompanySettings settings;
@override@JsonKey() final  int updatedAt;
@override@JsonKey() final  int archivedAt;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyCopyWith<_Company> get copyWith => __$CompanyCopyWithImpl<_Company>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&const DeepCollectionEquality().equals(other._rawSettings, _rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(_customFields),const DeepCollectionEquality().hash(_rawSettings),settings,updatedAt,archivedAt);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyCopyWith<$Res> implements $CompanyCopyWith<$Res> {
  factory _$CompanyCopyWith(_Company value, $Res Function(_Company) _then) = __$CompanyCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, int updatedAt, int archivedAt
});


@override $CompanySettingsApiCopyWith<$Res> get settings;

}
/// @nodoc
class __$CompanyCopyWithImpl<$Res>
    implements _$CompanyCopyWith<$Res> {
  __$CompanyCopyWithImpl(this._self, this._then);

  final _Company _self;
  final $Res Function(_Company) _then;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? updatedAt = null,Object? archivedAt = null,}) {
  return _then(_Company(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,firstMonthOfYear: null == firstMonthOfYear ? _self.firstMonthOfYear : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
as String,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as String,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,portalDomain: null == portalDomain ? _self.portalDomain : portalDomain // ignore: cast_nullable_to_non_nullable
as String,portalMode: null == portalMode ? _self.portalMode : portalMode // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,rawSettings: null == rawSettings ? _self._rawSettings : rawSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompanySettings,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanySettingsApiCopyWith<$Res> get settings {
  
  return $CompanySettingsApiCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
