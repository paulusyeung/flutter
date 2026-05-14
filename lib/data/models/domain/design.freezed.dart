// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Design {

 String get id; String get name; bool get isCustom; bool get isActive; bool get isTemplate; bool get isFree; List<String> get entities; DesignTemplate get template; DateTime get updatedAt; DateTime get createdAt; DateTime? get archivedAt; bool get isDeleted; bool get isDirty;
/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignCopyWith<Design> get copyWith => _$DesignCopyWithImpl<Design>(this as Design, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Design&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&const DeepCollectionEquality().equals(other.entities, entities)&&(identical(other.template, template) || other.template == template)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isCustom,isActive,isTemplate,isFree,const DeepCollectionEquality().hash(entities),template,updatedAt,createdAt,archivedAt,isDeleted,isDirty);

@override
String toString() {
  return 'Design(id: $id, name: $name, isCustom: $isCustom, isActive: $isActive, isTemplate: $isTemplate, isFree: $isFree, entities: $entities, template: $template, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $DesignCopyWith<$Res>  {
  factory $DesignCopyWith(Design value, $Res Function(Design) _then) = _$DesignCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isCustom, bool isActive, bool isTemplate, bool isFree, List<String> entities, DesignTemplate template, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});


$DesignTemplateCopyWith<$Res> get template;

}
/// @nodoc
class _$DesignCopyWithImpl<$Res>
    implements $DesignCopyWith<$Res> {
  _$DesignCopyWithImpl(this._self, this._then);

  final Design _self;
  final $Res Function(Design) _then;

/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isCustom = null,Object? isActive = null,Object? isTemplate = null,Object? isFree = null,Object? entities = null,Object? template = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,entities: null == entities ? _self.entities : entities // ignore: cast_nullable_to_non_nullable
as List<String>,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as DesignTemplate,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTemplateCopyWith<$Res> get template {
  
  return $DesignTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}


/// Adds pattern-matching-related methods to [Design].
extension DesignPatterns on Design {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Design value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Design() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Design value)  $default,){
final _that = this;
switch (_that) {
case _Design():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Design value)?  $default,){
final _that = this;
switch (_that) {
case _Design() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isCustom,  bool isActive,  bool isTemplate,  bool isFree,  List<String> entities,  DesignTemplate template,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Design() when $default != null:
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.template,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isCustom,  bool isActive,  bool isTemplate,  bool isFree,  List<String> entities,  DesignTemplate template,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _Design():
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.template,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isCustom,  bool isActive,  bool isTemplate,  bool isFree,  List<String> entities,  DesignTemplate template,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _Design() when $default != null:
return $default(_that.id,_that.name,_that.isCustom,_that.isActive,_that.isTemplate,_that.isFree,_that.entities,_that.template,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _Design implements Design {
  const _Design({required this.id, required this.name, required this.isCustom, required this.isActive, required this.isTemplate, required this.isFree, required final  List<String> entities, required this.template, required this.updatedAt, required this.createdAt, required this.archivedAt, required this.isDeleted, this.isDirty = false}): _entities = entities;
  

@override final  String id;
@override final  String name;
@override final  bool isCustom;
@override final  bool isActive;
@override final  bool isTemplate;
@override final  bool isFree;
 final  List<String> _entities;
@override List<String> get entities {
  if (_entities is EqualUnmodifiableListView) return _entities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entities);
}

@override final  DesignTemplate template;
@override final  DateTime updatedAt;
@override final  DateTime createdAt;
@override final  DateTime? archivedAt;
@override final  bool isDeleted;
@override@JsonKey() final  bool isDirty;

/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignCopyWith<_Design> get copyWith => __$DesignCopyWithImpl<_Design>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Design&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&const DeepCollectionEquality().equals(other._entities, _entities)&&(identical(other.template, template) || other.template == template)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isCustom,isActive,isTemplate,isFree,const DeepCollectionEquality().hash(_entities),template,updatedAt,createdAt,archivedAt,isDeleted,isDirty);

@override
String toString() {
  return 'Design(id: $id, name: $name, isCustom: $isCustom, isActive: $isActive, isTemplate: $isTemplate, isFree: $isFree, entities: $entities, template: $template, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$DesignCopyWith<$Res> implements $DesignCopyWith<$Res> {
  factory _$DesignCopyWith(_Design value, $Res Function(_Design) _then) = __$DesignCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isCustom, bool isActive, bool isTemplate, bool isFree, List<String> entities, DesignTemplate template, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});


@override $DesignTemplateCopyWith<$Res> get template;

}
/// @nodoc
class __$DesignCopyWithImpl<$Res>
    implements _$DesignCopyWith<$Res> {
  __$DesignCopyWithImpl(this._self, this._then);

  final _Design _self;
  final $Res Function(_Design) _then;

/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isCustom = null,Object? isActive = null,Object? isTemplate = null,Object? isFree = null,Object? entities = null,Object? template = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_Design(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,entities: null == entities ? _self._entities : entities // ignore: cast_nullable_to_non_nullable
as List<String>,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as DesignTemplate,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Design
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTemplateCopyWith<$Res> get template {
  
  return $DesignTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

/// @nodoc
mixin _$DesignTemplate {

 String get body; String get header; String get footer; String get includes; String get product; String get task;
/// Create a copy of DesignTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTemplateCopyWith<DesignTemplate> get copyWith => _$DesignTemplateCopyWithImpl<DesignTemplate>(this as DesignTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTemplate&&(identical(other.body, body) || other.body == body)&&(identical(other.header, header) || other.header == header)&&(identical(other.footer, footer) || other.footer == footer)&&(identical(other.includes, includes) || other.includes == includes)&&(identical(other.product, product) || other.product == product)&&(identical(other.task, task) || other.task == task));
}


@override
int get hashCode => Object.hash(runtimeType,body,header,footer,includes,product,task);

@override
String toString() {
  return 'DesignTemplate(body: $body, header: $header, footer: $footer, includes: $includes, product: $product, task: $task)';
}


}

/// @nodoc
abstract mixin class $DesignTemplateCopyWith<$Res>  {
  factory $DesignTemplateCopyWith(DesignTemplate value, $Res Function(DesignTemplate) _then) = _$DesignTemplateCopyWithImpl;
@useResult
$Res call({
 String body, String header, String footer, String includes, String product, String task
});




}
/// @nodoc
class _$DesignTemplateCopyWithImpl<$Res>
    implements $DesignTemplateCopyWith<$Res> {
  _$DesignTemplateCopyWithImpl(this._self, this._then);

  final DesignTemplate _self;
  final $Res Function(DesignTemplate) _then;

/// Create a copy of DesignTemplate
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


/// Adds pattern-matching-related methods to [DesignTemplate].
extension DesignTemplatePatterns on DesignTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTemplate value)  $default,){
final _that = this;
switch (_that) {
case _DesignTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTemplate() when $default != null:
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
case _DesignTemplate() when $default != null:
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
case _DesignTemplate():
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
case _DesignTemplate() when $default != null:
return $default(_that.body,_that.header,_that.footer,_that.includes,_that.product,_that.task);case _:
  return null;

}
}

}

/// @nodoc


class _DesignTemplate implements DesignTemplate {
  const _DesignTemplate({this.body = '', this.header = '', this.footer = '', this.includes = '', this.product = '', this.task = ''});
  

@override@JsonKey() final  String body;
@override@JsonKey() final  String header;
@override@JsonKey() final  String footer;
@override@JsonKey() final  String includes;
@override@JsonKey() final  String product;
@override@JsonKey() final  String task;

/// Create a copy of DesignTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTemplateCopyWith<_DesignTemplate> get copyWith => __$DesignTemplateCopyWithImpl<_DesignTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTemplate&&(identical(other.body, body) || other.body == body)&&(identical(other.header, header) || other.header == header)&&(identical(other.footer, footer) || other.footer == footer)&&(identical(other.includes, includes) || other.includes == includes)&&(identical(other.product, product) || other.product == product)&&(identical(other.task, task) || other.task == task));
}


@override
int get hashCode => Object.hash(runtimeType,body,header,footer,includes,product,task);

@override
String toString() {
  return 'DesignTemplate(body: $body, header: $header, footer: $footer, includes: $includes, product: $product, task: $task)';
}


}

/// @nodoc
abstract mixin class _$DesignTemplateCopyWith<$Res> implements $DesignTemplateCopyWith<$Res> {
  factory _$DesignTemplateCopyWith(_DesignTemplate value, $Res Function(_DesignTemplate) _then) = __$DesignTemplateCopyWithImpl;
@override @useResult
$Res call({
 String body, String header, String footer, String includes, String product, String task
});




}
/// @nodoc
class __$DesignTemplateCopyWithImpl<$Res>
    implements _$DesignTemplateCopyWith<$Res> {
  __$DesignTemplateCopyWithImpl(this._self, this._then);

  final _DesignTemplate _self;
  final $Res Function(_DesignTemplate) _then;

/// Create a copy of DesignTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? header = null,Object? footer = null,Object? includes = null,Object? product = null,Object? task = null,}) {
  return _then(_DesignTemplate(
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

// dart format on
