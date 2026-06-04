// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupSetting {

 String get id; String get name; String get customValue1; String get customValue2; String get customValue3; String get customValue4; DateTime get updatedAt; DateTime get createdAt; DateTime? get archivedAt; bool get isDeleted;// Sparse cascade overrides. Stored raw because keys vary widely;
// the typed `CompanySettings` view is reconstructed on demand.
 Map<String, dynamic>? get settings; List<Document> get documents; bool get isDirty;
/// Create a copy of GroupSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupSettingCopyWith<GroupSetting> get copyWith => _$GroupSettingCopyWithImpl<GroupSetting>(this as GroupSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&const DeepCollectionEquality().equals(other.settings, settings)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,customValue1,customValue2,customValue3,customValue4,updatedAt,createdAt,archivedAt,isDeleted,const DeepCollectionEquality().hash(settings),const DeepCollectionEquality().hash(documents),isDirty);

@override
String toString() {
  return 'GroupSetting(id: $id, name: $name, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, settings: $settings, documents: $documents, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $GroupSettingCopyWith<$Res>  {
  factory $GroupSettingCopyWith(GroupSetting value, $Res Function(GroupSetting) _then) = _$GroupSettingCopyWithImpl;
@useResult
$Res call({
 String id, String name, String customValue1, String customValue2, String customValue3, String customValue4, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, Map<String, dynamic>? settings, List<Document> documents, bool isDirty
});




}
/// @nodoc
class _$GroupSettingCopyWithImpl<$Res>
    implements $GroupSettingCopyWith<$Res> {
  _$GroupSettingCopyWithImpl(this._self, this._then);

  final GroupSetting _self;
  final $Res Function(GroupSetting) _then;

/// Create a copy of GroupSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? settings = freezed,Object? documents = null,Object? isDirty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupSetting].
extension GroupSettingPatterns on GroupSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupSetting value)  $default,){
final _that = this;
switch (_that) {
case _GroupSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupSetting value)?  $default,){
final _that = this;
switch (_that) {
case _GroupSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  Map<String, dynamic>? settings,  List<Document> documents,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupSetting() when $default != null:
return $default(_that.id,_that.name,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.settings,_that.documents,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  Map<String, dynamic>? settings,  List<Document> documents,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _GroupSetting():
return $default(_that.id,_that.name,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.settings,_that.documents,_that.isDirty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  Map<String, dynamic>? settings,  List<Document> documents,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _GroupSetting() when $default != null:
return $default(_that.id,_that.name,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.settings,_that.documents,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _GroupSetting extends GroupSetting {
  const _GroupSetting({required this.id, required this.name, required this.customValue1, required this.customValue2, required this.customValue3, required this.customValue4, required this.updatedAt, required this.createdAt, required this.archivedAt, required this.isDeleted, final  Map<String, dynamic>? settings, final  List<Document> documents = const <Document>[], this.isDirty = false}): _settings = settings,_documents = documents,super._();
  

@override final  String id;
@override final  String name;
@override final  String customValue1;
@override final  String customValue2;
@override final  String customValue3;
@override final  String customValue4;
@override final  DateTime updatedAt;
@override final  DateTime createdAt;
@override final  DateTime? archivedAt;
@override final  bool isDeleted;
// Sparse cascade overrides. Stored raw because keys vary widely;
// the typed `CompanySettings` view is reconstructed on demand.
 final  Map<String, dynamic>? _settings;
// Sparse cascade overrides. Stored raw because keys vary widely;
// the typed `CompanySettings` view is reconstructed on demand.
@override Map<String, dynamic>? get settings {
  final value = _settings;
  if (value == null) return null;
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override@JsonKey() final  bool isDirty;

/// Create a copy of GroupSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupSettingCopyWith<_GroupSetting> get copyWith => __$GroupSettingCopyWithImpl<_GroupSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&const DeepCollectionEquality().equals(other._settings, _settings)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,customValue1,customValue2,customValue3,customValue4,updatedAt,createdAt,archivedAt,isDeleted,const DeepCollectionEquality().hash(_settings),const DeepCollectionEquality().hash(_documents),isDirty);

@override
String toString() {
  return 'GroupSetting(id: $id, name: $name, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, settings: $settings, documents: $documents, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$GroupSettingCopyWith<$Res> implements $GroupSettingCopyWith<$Res> {
  factory _$GroupSettingCopyWith(_GroupSetting value, $Res Function(_GroupSetting) _then) = __$GroupSettingCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String customValue1, String customValue2, String customValue3, String customValue4, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, Map<String, dynamic>? settings, List<Document> documents, bool isDirty
});




}
/// @nodoc
class __$GroupSettingCopyWithImpl<$Res>
    implements _$GroupSettingCopyWith<$Res> {
  __$GroupSettingCopyWithImpl(this._self, this._then);

  final _GroupSetting _self;
  final $Res Function(_GroupSetting) _then;

/// Create a copy of GroupSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? settings = freezed,Object? documents = null,Object? isDirty = null,}) {
  return _then(_GroupSetting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,settings: freezed == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
