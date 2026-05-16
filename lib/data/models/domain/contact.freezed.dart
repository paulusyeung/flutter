// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Contact {

 String get id; String get firstName; String get lastName; String get email; String get phone; bool get isPrimary; bool get sendEmail; String get password; DateTime get updatedAt; bool get isDeleted; String get link;
/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactCopyWith<Contact> get copyWith => _$ContactCopyWithImpl<Contact>(this as Contact, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sendEmail, sendEmail) || other.sendEmail == sendEmail)&&(identical(other.password, password) || other.password == password)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.link, link) || other.link == link));
}


@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName,email,phone,isPrimary,sendEmail,password,updatedAt,isDeleted,link);

@override
String toString() {
  return 'Contact(id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, isPrimary: $isPrimary, sendEmail: $sendEmail, password: $password, updatedAt: $updatedAt, isDeleted: $isDeleted, link: $link)';
}


}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res>  {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) = _$ContactCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName, String email, String phone, bool isPrimary, bool sendEmail, String password, DateTime updatedAt, bool isDeleted, String link
});




}
/// @nodoc
class _$ContactCopyWithImpl<$Res>
    implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = null,Object? isPrimary = null,Object? sendEmail = null,Object? password = null,Object? updatedAt = null,Object? isDeleted = null,Object? link = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sendEmail: null == sendEmail ? _self.sendEmail : sendEmail // ignore: cast_nullable_to_non_nullable
as bool,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Contact].
extension ContactPatterns on Contact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contact value)  $default,){
final _that = this;
switch (_that) {
case _Contact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contact value)?  $default,){
final _that = this;
switch (_that) {
case _Contact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String phone,  bool isPrimary,  bool sendEmail,  String password,  DateTime updatedAt,  bool isDeleted,  String link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.isPrimary,_that.sendEmail,_that.password,_that.updatedAt,_that.isDeleted,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String phone,  bool isPrimary,  bool sendEmail,  String password,  DateTime updatedAt,  bool isDeleted,  String link)  $default,) {final _that = this;
switch (_that) {
case _Contact():
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.isPrimary,_that.sendEmail,_that.password,_that.updatedAt,_that.isDeleted,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName,  String email,  String phone,  bool isPrimary,  bool sendEmail,  String password,  DateTime updatedAt,  bool isDeleted,  String link)?  $default,) {final _that = this;
switch (_that) {
case _Contact() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.phone,_that.isPrimary,_that.sendEmail,_that.password,_that.updatedAt,_that.isDeleted,_that.link);case _:
  return null;

}
}

}

/// @nodoc


class _Contact implements Contact {
  const _Contact({required this.id, required this.firstName, required this.lastName, required this.email, required this.phone, required this.isPrimary, required this.sendEmail, this.password = '', required this.updatedAt, required this.isDeleted, this.link = ''});
  

@override final  String id;
@override final  String firstName;
@override final  String lastName;
@override final  String email;
@override final  String phone;
@override final  bool isPrimary;
@override final  bool sendEmail;
@override@JsonKey() final  String password;
@override final  DateTime updatedAt;
@override final  bool isDeleted;
@override@JsonKey() final  String link;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactCopyWith<_Contact> get copyWith => __$ContactCopyWithImpl<_Contact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contact&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sendEmail, sendEmail) || other.sendEmail == sendEmail)&&(identical(other.password, password) || other.password == password)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.link, link) || other.link == link));
}


@override
int get hashCode => Object.hash(runtimeType,id,firstName,lastName,email,phone,isPrimary,sendEmail,password,updatedAt,isDeleted,link);

@override
String toString() {
  return 'Contact(id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, isPrimary: $isPrimary, sendEmail: $sendEmail, password: $password, updatedAt: $updatedAt, isDeleted: $isDeleted, link: $link)';
}


}

/// @nodoc
abstract mixin class _$ContactCopyWith<$Res> implements $ContactCopyWith<$Res> {
  factory _$ContactCopyWith(_Contact value, $Res Function(_Contact) _then) = __$ContactCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName, String email, String phone, bool isPrimary, bool sendEmail, String password, DateTime updatedAt, bool isDeleted, String link
});




}
/// @nodoc
class __$ContactCopyWithImpl<$Res>
    implements _$ContactCopyWith<$Res> {
  __$ContactCopyWithImpl(this._self, this._then);

  final _Contact _self;
  final $Res Function(_Contact) _then;

/// Create a copy of Contact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = null,Object? isPrimary = null,Object? sendEmail = null,Object? password = null,Object? updatedAt = null,Object? isDeleted = null,Object? link = null,}) {
  return _then(_Contact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sendEmail: null == sendEmail ? _self.sendEmail : sendEmail // ignore: cast_nullable_to_non_nullable
as bool,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
