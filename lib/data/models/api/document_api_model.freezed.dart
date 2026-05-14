// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentApi {

 String get id; String get name; String get hash; String get type; String get url; int get size;@JsonKey(name: 'is_public') bool get isPublic;@JsonKey(name: 'created_at') int get createdAt;@JsonKey(name: 'updated_at') int get updatedAt;
/// Create a copy of DocumentApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentApiCopyWith<DocumentApi> get copyWith => _$DocumentApiCopyWithImpl<DocumentApi>(this as DocumentApi, _$identity);

  /// Serializes this DocumentApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentApi&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hash,type,url,size,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentApi(id: $id, name: $name, hash: $hash, type: $type, url: $url, size: $size, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentApiCopyWith<$Res>  {
  factory $DocumentApiCopyWith(DocumentApi value, $Res Function(DocumentApi) _then) = _$DocumentApiCopyWithImpl;
@useResult
$Res call({
 String id, String name, String hash, String type, String url, int size,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt
});




}
/// @nodoc
class _$DocumentApiCopyWithImpl<$Res>
    implements $DocumentApiCopyWith<$Res> {
  _$DocumentApiCopyWithImpl(this._self, this._then);

  final DocumentApi _self;
  final $Res Function(DocumentApi) _then;

/// Create a copy of DocumentApi
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


/// Adds pattern-matching-related methods to [DocumentApi].
extension DocumentApiPatterns on DocumentApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentApi value)  $default,){
final _that = this;
switch (_that) {
case _DocumentApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentApi value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String hash,  String type,  String url,  int size, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentApi() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String hash,  String type,  String url,  int size, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentApi():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String hash,  String type,  String url,  int size, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  int createdAt, @JsonKey(name: 'updated_at')  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentApi() when $default != null:
return $default(_that.id,_that.name,_that.hash,_that.type,_that.url,_that.size,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _DocumentApi implements DocumentApi {
  const _DocumentApi({this.id = '', this.name = '', this.hash = '', this.type = '', this.url = '', this.size = 0, @JsonKey(name: 'is_public') this.isPublic = true, @JsonKey(name: 'created_at') this.createdAt = 0, @JsonKey(name: 'updated_at') this.updatedAt = 0});
  factory _DocumentApi.fromJson(Map<String, dynamic> json) => _$DocumentApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String hash;
@override@JsonKey() final  String type;
@override@JsonKey() final  String url;
@override@JsonKey() final  int size;
@override@JsonKey(name: 'is_public') final  bool isPublic;
@override@JsonKey(name: 'created_at') final  int createdAt;
@override@JsonKey(name: 'updated_at') final  int updatedAt;

/// Create a copy of DocumentApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentApiCopyWith<_DocumentApi> get copyWith => __$DocumentApiCopyWithImpl<_DocumentApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentApi&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hash,type,url,size,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentApi(id: $id, name: $name, hash: $hash, type: $type, url: $url, size: $size, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentApiCopyWith<$Res> implements $DocumentApiCopyWith<$Res> {
  factory _$DocumentApiCopyWith(_DocumentApi value, $Res Function(_DocumentApi) _then) = __$DocumentApiCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String hash, String type, String url, int size,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at') int createdAt,@JsonKey(name: 'updated_at') int updatedAt
});




}
/// @nodoc
class __$DocumentApiCopyWithImpl<$Res>
    implements _$DocumentApiCopyWith<$Res> {
  __$DocumentApiCopyWithImpl(this._self, this._then);

  final _DocumentApi _self;
  final $Res Function(_DocumentApi) _then;

/// Create a copy of DocumentApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? hash = null,Object? type = null,Object? url = null,Object? size = null,Object? isPublic = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DocumentApi(
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
