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

 String get id; String get displayName; String get name; String get companyKey; String get sizeId; String get industryId; String get firstMonthOfYear; String get firstDayOfWeek; int get enabledModules; int get legalEntityId; String get subdomain; String get portalDomain; String get portalMode; Map<String, String> get customFields; Map<String, dynamic> get rawSettings; CompanySettings get settings; List<Document> get documents; int get updatedAt; int get archivedAt;
/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyCopyWith<Company> get copyWith => _$CompanyCopyWithImpl<Company>(this as Company, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&const DeepCollectionEquality().equals(other.rawSettings, rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(customFields),const DeepCollectionEquality().hash(rawSettings),settings,const DeepCollectionEquality().hash(documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class $CompanyCopyWith<$Res>  {
  factory $CompanyCopyWith(Company value, $Res Function(Company) _then) = _$CompanyCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, List<Document> documents, int updatedAt, int archivedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
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
as CompanySettings,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  List<Document> documents,  int updatedAt,  int archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.documents,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  List<Document> documents,  int updatedAt,  int archivedAt)  $default,) {final _that = this;
switch (_that) {
case _Company():
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.documents,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  List<Document> documents,  int updatedAt,  int archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.documents,_that.updatedAt,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Company extends Company {
  const _Company({this.id = '', this.displayName = '', this.name = '', this.companyKey = '', this.sizeId = '', this.industryId = '', this.firstMonthOfYear = '', this.firstDayOfWeek = '', this.enabledModules = 0, this.legalEntityId = 0, this.subdomain = '', this.portalDomain = '', this.portalMode = '', final  Map<String, String> customFields = const <String, String>{}, final  Map<String, dynamic> rawSettings = const <String, dynamic>{}, this.settings = const CompanySettings(), final  List<Document> documents = const <Document>[], this.updatedAt = 0, this.archivedAt = 0}): _customFields = customFields,_rawSettings = rawSettings,_documents = documents,super._();
  

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
 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override@JsonKey() final  int updatedAt;
@override@JsonKey() final  int archivedAt;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyCopyWith<_Company> get copyWith => __$CompanyCopyWithImpl<_Company>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&const DeepCollectionEquality().equals(other._rawSettings, _rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(_customFields),const DeepCollectionEquality().hash(_rawSettings),settings,const DeepCollectionEquality().hash(_documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyCopyWith<$Res> implements $CompanyCopyWith<$Res> {
  factory _$CompanyCopyWith(_Company value, $Res Function(_Company) _then) = __$CompanyCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, List<Document> documents, int updatedAt, int archivedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
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
as CompanySettings,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
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

/// @nodoc
mixin _$Document {

 String get id; String get name; String get hash; String get type; String get url; int get size; bool get isPublic; int get createdAt; int get updatedAt;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,hash,type,url,size,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Document(id: $id, name: $name, hash: $hash, type: $type, url: $url, size: $size, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String hash, String type, String url, int size, bool isPublic, int createdAt, int updatedAt
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? hash = null,Object? type = null,Object? url = null,Object? size = null,Object? isPublic = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String hash,  String type,  String url,  int size,  bool isPublic,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.name,_that.hash,_that.type,_that.url,_that.size,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String hash,  String type,  String url,  int size,  bool isPublic,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.name,_that.hash,_that.type,_that.url,_that.size,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String hash,  String type,  String url,  int size,  bool isPublic,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.name,_that.hash,_that.type,_that.url,_that.size,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Document implements Document {
  const _Document({this.id = '', this.name = '', this.hash = '', this.type = '', this.url = '', this.size = 0, this.isPublic = true, this.createdAt = 0, this.updatedAt = 0});
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String hash;
@override@JsonKey() final  String type;
@override@JsonKey() final  String url;
@override@JsonKey() final  int size;
@override@JsonKey() final  bool isPublic;
@override@JsonKey() final  int createdAt;
@override@JsonKey() final  int updatedAt;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,hash,type,url,size,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Document(id: $id, name: $name, hash: $hash, type: $type, url: $url, size: $size, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String hash, String type, String url, int size, bool isPublic, int createdAt, int updatedAt
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? hash = null,Object? type = null,Object? url = null,Object? size = null,Object? isPublic = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
