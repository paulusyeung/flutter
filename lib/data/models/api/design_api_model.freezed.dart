// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DesignTemplateApi {

 String get body; String get header; String get footer; String get includes; String get product; String get task;
/// Create a copy of DesignTemplateApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTemplateApiCopyWith<DesignTemplateApi> get copyWith => _$DesignTemplateApiCopyWithImpl<DesignTemplateApi>(this as DesignTemplateApi, _$identity);

  /// Serializes this DesignTemplateApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTemplateApi&&(identical(other.body, body) || other.body == body)&&(identical(other.header, header) || other.header == header)&&(identical(other.footer, footer) || other.footer == footer)&&(identical(other.includes, includes) || other.includes == includes)&&(identical(other.product, product) || other.product == product)&&(identical(other.task, task) || other.task == task));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,header,footer,includes,product,task);

@override
String toString() {
  return 'DesignTemplateApi(body: $body, header: $header, footer: $footer, includes: $includes, product: $product, task: $task)';
}


}

/// @nodoc
abstract mixin class $DesignTemplateApiCopyWith<$Res>  {
  factory $DesignTemplateApiCopyWith(DesignTemplateApi value, $Res Function(DesignTemplateApi) _then) = _$DesignTemplateApiCopyWithImpl;
@useResult
$Res call({
 String body, String header, String footer, String includes, String product, String task
});




}
/// @nodoc
class _$DesignTemplateApiCopyWithImpl<$Res>
    implements $DesignTemplateApiCopyWith<$Res> {
  _$DesignTemplateApiCopyWithImpl(this._self, this._then);

  final DesignTemplateApi _self;
  final $Res Function(DesignTemplateApi) _then;

/// Create a copy of DesignTemplateApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? header = null,Object? footer = null,Object? includes = null,Object? product = null,Object? task = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,footer: null == footer ? _self.footer : footer // ignore: cast_nullable_to_non_nullable
as String,includes: null == includes ? _self.includes : includes // ignore: cast_nullable_to_non_nullable
as String,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignTemplateApi].
extension DesignTemplateApiPatterns on DesignTemplateApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTemplateApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTemplateApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTemplateApi value)  $default,){
final _that = this;
switch (_that) {
case _DesignTemplateApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTemplateApi value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTemplateApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body,  String header,  String footer,  String includes,  String product,  String task)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTemplateApi() when $default != null:
return $default(_that.body,_that.header,_that.footer,_that.includes,_that.product,_that.task);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body,  String header,  String footer,  String includes,  String product,  String task)  $default,) {final _that = this;
switch (_that) {
case _DesignTemplateApi():
return $default(_that.body,_that.header,_that.footer,_that.includes,_that.product,_that.task);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body,  String header,  String footer,  String includes,  String product,  String task)?  $default,) {final _that = this;
switch (_that) {
case _DesignTemplateApi() when $default != null:
return $default(_that.body,_that.header,_that.footer,_that.includes,_that.product,_that.task);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTemplateApi implements DesignTemplateApi {
  const _DesignTemplateApi({this.body = '', this.header = '', this.footer = '', this.includes = '', this.product = '', this.task = ''});
  factory _DesignTemplateApi.fromJson(Map<String, dynamic> json) => _$DesignTemplateApiFromJson(json);

@override@JsonKey() final  String body;
@override@JsonKey() final  String header;
@override@JsonKey() final  String footer;
@override@JsonKey() final  String includes;
@override@JsonKey() final  String product;
@override@JsonKey() final  String task;

/// Create a copy of DesignTemplateApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTemplateApiCopyWith<_DesignTemplateApi> get copyWith => __$DesignTemplateApiCopyWithImpl<_DesignTemplateApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTemplateApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTemplateApi&&(identical(other.body, body) || other.body == body)&&(identical(other.header, header) || other.header == header)&&(identical(other.footer, footer) || other.footer == footer)&&(identical(other.includes, includes) || other.includes == includes)&&(identical(other.product, product) || other.product == product)&&(identical(other.task, task) || other.task == task));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,header,footer,includes,product,task);

@override
String toString() {
  return 'DesignTemplateApi(body: $body, header: $header, footer: $footer, includes: $includes, product: $product, task: $task)';
}


}

/// @nodoc
abstract mixin class _$DesignTemplateApiCopyWith<$Res> implements $DesignTemplateApiCopyWith<$Res> {
  factory _$DesignTemplateApiCopyWith(_DesignTemplateApi value, $Res Function(_DesignTemplateApi) _then) = __$DesignTemplateApiCopyWithImpl;
@override @useResult
$Res call({
 String body, String header, String footer, String includes, String product, String task
});




}
/// @nodoc
class __$DesignTemplateApiCopyWithImpl<$Res>
    implements _$DesignTemplateApiCopyWith<$Res> {
  __$DesignTemplateApiCopyWithImpl(this._self, this._then);

  final _DesignTemplateApi _self;
  final $Res Function(_DesignTemplateApi) _then;

/// Create a copy of DesignTemplateApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? header = null,Object? footer = null,Object? includes = null,Object? product = null,Object? task = null,}) {
  return _then(_DesignTemplateApi(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,footer: null == footer ? _self.footer : footer // ignore: cast_nullable_to_non_nullable
as String,includes: null == includes ? _self.includes : includes // ignore: cast_nullable_to_non_nullable
as String,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DesignApi {

 String get id; String get name;@JsonKey(name: 'is_custom') bool get isCustom;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'is_template') bool get isTemplate;@JsonKey(name: 'is_free') bool get isFree; String get entities; DesignTemplateApi get design;@JsonKey(name: 'created_at') int get createdAt;@JsonKey(name: 'updated_at') int get updatedAt;@JsonKey(name: 'archived_at') int get archivedAt;@JsonKey(name: 'is_deleted') bool get isDeleted;
/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignApiCopyWith<DesignApi> get copyWith => _$DesignApiCopyWithImpl<DesignApi>(this as DesignApi, _$identity);

  /// Serializes this DesignApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignApi&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.entities, entities) || other.entities == entities)&&(identical(other.design, design) || other.design == design)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isCustom,isActive,isTemplate,isFree,entities,design,createdAt,updatedAt,archivedAt,isDeleted);

@override
String toString() {
  return 'DesignApi(id: $id, name: $name, isCustom: $isCustom, isActive: $isActive, isTemplate: $isTemplate, isFree: $isFree, entities: $entities, design: $design, createdAt: $createdAt, updatedAt: $updatedAt, archivedAt: $archivedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $DesignApiCopyWith<$Res>  {
  factory $DesignApiCopyWith(DesignApi value, $Res Function(DesignApi) _then) = _$DesignApiCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'is_custom') bool isCustom,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'is_free') bool isFree, String entities, DesignTemplateApi design,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt,@JsonKey(name: 'archived_at') int archivedAt,@JsonKey(name: 'is_deleted') bool isDeleted
});


$DesignTemplateApiCopyWith<$Res> get design;

}
/// @nodoc
class _$DesignApiCopyWithImpl<$Res>
    implements $DesignApiCopyWith<$Res> {
  _$DesignApiCopyWithImpl(this._self, this._then);

  final DesignApi _self;
  final $Res Function(DesignApi) _then;

/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isCustom = null,Object? isActive = null,Object? isTemplate = null,Object? isFree = null,Object? entities = null,Object? design = null,Object? createdAt = null,Object? updatedAt = null,Object? archivedAt = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,entities: null == entities ? _self.entities : entities // ignore: cast_nullable_to_non_nullable
as String,design: null == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as DesignTemplateApi,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTemplateApiCopyWith<$Res> get design {
  
  return $DesignTemplateApiCopyWith<$Res>(_self.design, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignApi].
extension DesignApiPatterns on DesignApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignApi value)  $default,){
final _that = this;
switch (_that) {
case _DesignApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignApi value)?  $default,){
final _that = this;
switch (_that) {
case _DesignApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'is_custom')  bool isCustom, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'is_free')  bool isFree,  String entities,  DesignTemplateApi design, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignApi() when $default != null:
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.design,_that.createdAt,_that.updatedAt,_that.archivedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'is_custom')  bool isCustom, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'is_free')  bool isFree,  String entities,  DesignTemplateApi design, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt, @JsonKey(name: 'is_deleted')  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _DesignApi():
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.design,_that.createdAt,_that.updatedAt,_that.archivedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'is_custom')  bool isCustom, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'is_free')  bool isFree,  String entities,  DesignTemplateApi design, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _DesignApi() when $default != null:
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.design,_that.createdAt,_that.updatedAt,_that.archivedAt,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignApi implements DesignApi {
  const _DesignApi({this.id = '', this.name = '', @JsonKey(name: 'is_custom') this.isCustom = false, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'is_template') this.isTemplate = false, @JsonKey(name: 'is_free') this.isFree = true, this.entities = '', this.design = const DesignTemplateApi(), @JsonKey(name: 'created_at') this.createdAt = 0, @JsonKey(name: 'updated_at') this.updatedAt = 0, @JsonKey(name: 'archived_at') this.archivedAt = 0, @JsonKey(name: 'is_deleted') this.isDeleted = false});
  factory _DesignApi.fromJson(Map<String, dynamic> json) => _$DesignApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'is_custom') final  bool isCustom;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'is_template') final  bool isTemplate;
@override@JsonKey(name: 'is_free') final  bool isFree;
@override@JsonKey() final  String entities;
@override@JsonKey() final  DesignTemplateApi design;
@override@JsonKey(name: 'created_at') final  int createdAt;
@override@JsonKey(name: 'updated_at') final  int updatedAt;
@override@JsonKey(name: 'archived_at') final  int archivedAt;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;

/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignApiCopyWith<_DesignApi> get copyWith => __$DesignApiCopyWithImpl<_DesignApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignApi&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.entities, entities) || other.entities == entities)&&(identical(other.design, design) || other.design == design)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isCustom,isActive,isTemplate,isFree,entities,design,createdAt,updatedAt,archivedAt,isDeleted);

@override
String toString() {
  return 'DesignApi(id: $id, name: $name, isCustom: $isCustom, isActive: $isActive, isTemplate: $isTemplate, isFree: $isFree, entities: $entities, design: $design, createdAt: $createdAt, updatedAt: $updatedAt, archivedAt: $archivedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$DesignApiCopyWith<$Res> implements $DesignApiCopyWith<$Res> {
  factory _$DesignApiCopyWith(_DesignApi value, $Res Function(_DesignApi) _then) = __$DesignApiCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'is_custom') bool isCustom,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'is_free') bool isFree, String entities, DesignTemplateApi design,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt,@JsonKey(name: 'archived_at') int archivedAt,@JsonKey(name: 'is_deleted') bool isDeleted
});


@override $DesignTemplateApiCopyWith<$Res> get design;

}
/// @nodoc
class __$DesignApiCopyWithImpl<$Res>
    implements _$DesignApiCopyWith<$Res> {
  __$DesignApiCopyWithImpl(this._self, this._then);

  final _DesignApi _self;
  final $Res Function(_DesignApi) _then;

/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isCustom = null,Object? isActive = null,Object? isTemplate = null,Object? isFree = null,Object? entities = null,Object? design = null,Object? createdAt = null,Object? updatedAt = null,Object? archivedAt = null,Object? isDeleted = null,}) {
  return _then(_DesignApi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,entities: null == entities ? _self.entities : entities // ignore: cast_nullable_to_non_nullable
as String,design: null == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as DesignTemplateApi,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DesignApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTemplateApiCopyWith<$Res> get design {
  
  return $DesignTemplateApiCopyWith<$Res>(_self.design, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}


/// @nodoc
mixin _$DesignListApi {

 List<DesignApi> get data;
/// Create a copy of DesignListApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignListApiCopyWith<DesignListApi> get copyWith => _$DesignListApiCopyWithImpl<DesignListApi>(this as DesignListApi, _$identity);

  /// Serializes this DesignListApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignListApi&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DesignListApi(data: $data)';
}


}

/// @nodoc
abstract mixin class $DesignListApiCopyWith<$Res>  {
  factory $DesignListApiCopyWith(DesignListApi value, $Res Function(DesignListApi) _then) = _$DesignListApiCopyWithImpl;
@useResult
$Res call({
 List<DesignApi> data
});




}
/// @nodoc
class _$DesignListApiCopyWithImpl<$Res>
    implements $DesignListApiCopyWith<$Res> {
  _$DesignListApiCopyWithImpl(this._self, this._then);

  final DesignListApi _self;
  final $Res Function(DesignListApi) _then;

/// Create a copy of DesignListApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<DesignApi>,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignListApi].
extension DesignListApiPatterns on DesignListApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignListApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignListApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignListApi value)  $default,){
final _that = this;
switch (_that) {
case _DesignListApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignListApi value)?  $default,){
final _that = this;
switch (_that) {
case _DesignListApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DesignApi> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignListApi() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DesignApi> data)  $default,) {final _that = this;
switch (_that) {
case _DesignListApi():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DesignApi> data)?  $default,) {final _that = this;
switch (_that) {
case _DesignListApi() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignListApi implements DesignListApi {
  const _DesignListApi({final  List<DesignApi> data = const <DesignApi>[]}): _data = data;
  factory _DesignListApi.fromJson(Map<String, dynamic> json) => _$DesignListApiFromJson(json);

 final  List<DesignApi> _data;
@override@JsonKey() List<DesignApi> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of DesignListApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignListApiCopyWith<_DesignListApi> get copyWith => __$DesignListApiCopyWithImpl<_DesignListApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignListApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignListApi&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'DesignListApi(data: $data)';
}


}

/// @nodoc
abstract mixin class _$DesignListApiCopyWith<$Res> implements $DesignListApiCopyWith<$Res> {
  factory _$DesignListApiCopyWith(_DesignListApi value, $Res Function(_DesignListApi) _then) = __$DesignListApiCopyWithImpl;
@override @useResult
$Res call({
 List<DesignApi> data
});




}
/// @nodoc
class __$DesignListApiCopyWithImpl<$Res>
    implements _$DesignListApiCopyWith<$Res> {
  __$DesignListApiCopyWithImpl(this._self, this._then);

  final _DesignListApi _self;
  final $Res Function(_DesignListApi) _then;

/// Create a copy of DesignListApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_DesignListApi(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<DesignApi>,
  ));
}


}


/// @nodoc
mixin _$DesignItemApi {

 DesignApi get data;
/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignItemApiCopyWith<DesignItemApi> get copyWith => _$DesignItemApiCopyWithImpl<DesignItemApi>(this as DesignItemApi, _$identity);

  /// Serializes this DesignItemApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignItemApi&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'DesignItemApi(data: $data)';
}


}

/// @nodoc
abstract mixin class $DesignItemApiCopyWith<$Res>  {
  factory $DesignItemApiCopyWith(DesignItemApi value, $Res Function(DesignItemApi) _then) = _$DesignItemApiCopyWithImpl;
@useResult
$Res call({
 DesignApi data
});


$DesignApiCopyWith<$Res> get data;

}
/// @nodoc
class _$DesignItemApiCopyWithImpl<$Res>
    implements $DesignItemApiCopyWith<$Res> {
  _$DesignItemApiCopyWithImpl(this._self, this._then);

  final DesignItemApi _self;
  final $Res Function(DesignItemApi) _then;

/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DesignApi,
  ));
}
/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignApiCopyWith<$Res> get data {
  
  return $DesignApiCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignItemApi].
extension DesignItemApiPatterns on DesignItemApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignItemApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignItemApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignItemApi value)  $default,){
final _that = this;
switch (_that) {
case _DesignItemApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignItemApi value)?  $default,){
final _that = this;
switch (_that) {
case _DesignItemApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DesignApi data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignItemApi() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DesignApi data)  $default,) {final _that = this;
switch (_that) {
case _DesignItemApi():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DesignApi data)?  $default,) {final _that = this;
switch (_that) {
case _DesignItemApi() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignItemApi implements DesignItemApi {
  const _DesignItemApi({required this.data});
  factory _DesignItemApi.fromJson(Map<String, dynamic> json) => _$DesignItemApiFromJson(json);

@override final  DesignApi data;

/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignItemApiCopyWith<_DesignItemApi> get copyWith => __$DesignItemApiCopyWithImpl<_DesignItemApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignItemApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignItemApi&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'DesignItemApi(data: $data)';
}


}

/// @nodoc
abstract mixin class _$DesignItemApiCopyWith<$Res> implements $DesignItemApiCopyWith<$Res> {
  factory _$DesignItemApiCopyWith(_DesignItemApi value, $Res Function(_DesignItemApi) _then) = __$DesignItemApiCopyWithImpl;
@override @useResult
$Res call({
 DesignApi data
});


@override $DesignApiCopyWith<$Res> get data;

}
/// @nodoc
class __$DesignItemApiCopyWithImpl<$Res>
    implements _$DesignItemApiCopyWith<$Res> {
  __$DesignItemApiCopyWithImpl(this._self, this._then);

  final _DesignItemApi _self;
  final $Res Function(_DesignItemApi) _then;

/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_DesignItemApi(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DesignApi,
  ));
}

/// Create a copy of DesignItemApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignApiCopyWith<$Res> get data {
  
  return $DesignApiCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
