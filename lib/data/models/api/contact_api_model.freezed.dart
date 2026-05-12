// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ContactApi _$ContactApiFromJson(Map<String, dynamic> json) {
  return _ContactApi.fromJson(json);
}

/// @nodoc
mixin _$ContactApi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String get lastName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_primary')
  bool get isPrimary => throw _privateConstructorUsedError;
  @JsonKey(name: 'send_email')
  bool get sendEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value1')
  String get customValue1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value2')
  String get customValue2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value3')
  String get customValue3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value4')
  String get customValue4 => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'archived_at')
  int get archivedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this ContactApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContactApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContactApiCopyWith<ContactApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContactApiCopyWith<$Res> {
  factory $ContactApiCopyWith(
    ContactApi value,
    $Res Function(ContactApi) then,
  ) = _$ContactApiCopyWithImpl<$Res, ContactApi>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    String email,
    String phone,
    @JsonKey(name: 'is_primary') bool isPrimary,
    @JsonKey(name: 'send_email') bool sendEmail,
    @JsonKey(name: 'custom_value1') String customValue1,
    @JsonKey(name: 'custom_value2') String customValue2,
    @JsonKey(name: 'custom_value3') String customValue3,
    @JsonKey(name: 'custom_value4') String customValue4,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
    @JsonKey(name: 'is_deleted') bool isDeleted,
  });
}

/// @nodoc
class _$ContactApiCopyWithImpl<$Res, $Val extends ContactApi>
    implements $ContactApiCopyWith<$Res> {
  _$ContactApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContactApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? phone = null,
    Object? isPrimary = null,
    Object? sendEmail = null,
    Object? customValue1 = null,
    Object? customValue2 = null,
    Object? customValue3 = null,
    Object? customValue4 = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            isPrimary: null == isPrimary
                ? _value.isPrimary
                : isPrimary // ignore: cast_nullable_to_non_nullable
                      as bool,
            sendEmail: null == sendEmail
                ? _value.sendEmail
                : sendEmail // ignore: cast_nullable_to_non_nullable
                      as bool,
            customValue1: null == customValue1
                ? _value.customValue1
                : customValue1 // ignore: cast_nullable_to_non_nullable
                      as String,
            customValue2: null == customValue2
                ? _value.customValue2
                : customValue2 // ignore: cast_nullable_to_non_nullable
                      as String,
            customValue3: null == customValue3
                ? _value.customValue3
                : customValue3 // ignore: cast_nullable_to_non_nullable
                      as String,
            customValue4: null == customValue4
                ? _value.customValue4
                : customValue4 // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            archivedAt: null == archivedAt
                ? _value.archivedAt
                : archivedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContactApiImplCopyWith<$Res>
    implements $ContactApiCopyWith<$Res> {
  factory _$$ContactApiImplCopyWith(
    _$ContactApiImpl value,
    $Res Function(_$ContactApiImpl) then,
  ) = __$$ContactApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    String email,
    String phone,
    @JsonKey(name: 'is_primary') bool isPrimary,
    @JsonKey(name: 'send_email') bool sendEmail,
    @JsonKey(name: 'custom_value1') String customValue1,
    @JsonKey(name: 'custom_value2') String customValue2,
    @JsonKey(name: 'custom_value3') String customValue3,
    @JsonKey(name: 'custom_value4') String customValue4,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
    @JsonKey(name: 'is_deleted') bool isDeleted,
  });
}

/// @nodoc
class __$$ContactApiImplCopyWithImpl<$Res>
    extends _$ContactApiCopyWithImpl<$Res, _$ContactApiImpl>
    implements _$$ContactApiImplCopyWith<$Res> {
  __$$ContactApiImplCopyWithImpl(
    _$ContactApiImpl _value,
    $Res Function(_$ContactApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContactApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = null,
    Object? phone = null,
    Object? isPrimary = null,
    Object? sendEmail = null,
    Object? customValue1 = null,
    Object? customValue2 = null,
    Object? customValue3 = null,
    Object? customValue4 = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _$ContactApiImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        isPrimary: null == isPrimary
            ? _value.isPrimary
            : isPrimary // ignore: cast_nullable_to_non_nullable
                  as bool,
        sendEmail: null == sendEmail
            ? _value.sendEmail
            : sendEmail // ignore: cast_nullable_to_non_nullable
                  as bool,
        customValue1: null == customValue1
            ? _value.customValue1
            : customValue1 // ignore: cast_nullable_to_non_nullable
                  as String,
        customValue2: null == customValue2
            ? _value.customValue2
            : customValue2 // ignore: cast_nullable_to_non_nullable
                  as String,
        customValue3: null == customValue3
            ? _value.customValue3
            : customValue3 // ignore: cast_nullable_to_non_nullable
                  as String,
        customValue4: null == customValue4
            ? _value.customValue4
            : customValue4 // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        archivedAt: null == archivedAt
            ? _value.archivedAt
            : archivedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ContactApiImpl implements _ContactApi {
  const _$ContactApiImpl({
    this.id = '',
    @JsonKey(name: 'first_name') this.firstName = '',
    @JsonKey(name: 'last_name') this.lastName = '',
    this.email = '',
    this.phone = '',
    @JsonKey(name: 'is_primary') this.isPrimary = false,
    @JsonKey(name: 'send_email') this.sendEmail = true,
    @JsonKey(name: 'custom_value1') this.customValue1 = '',
    @JsonKey(name: 'custom_value2') this.customValue2 = '',
    @JsonKey(name: 'custom_value3') this.customValue3 = '',
    @JsonKey(name: 'custom_value4') this.customValue4 = '',
    @JsonKey(name: 'created_at') this.createdAt = 0,
    @JsonKey(name: 'updated_at') this.updatedAt = 0,
    @JsonKey(name: 'archived_at') this.archivedAt = 0,
    @JsonKey(name: 'is_deleted') this.isDeleted = false,
  });

  factory _$ContactApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContactApiImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey(name: 'first_name')
  final String firstName;
  @override
  @JsonKey(name: 'last_name')
  final String lastName;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  @override
  @JsonKey(name: 'send_email')
  final bool sendEmail;
  @override
  @JsonKey(name: 'custom_value1')
  final String customValue1;
  @override
  @JsonKey(name: 'custom_value2')
  final String customValue2;
  @override
  @JsonKey(name: 'custom_value3')
  final String customValue3;
  @override
  @JsonKey(name: 'custom_value4')
  final String customValue4;
  @override
  @JsonKey(name: 'created_at')
  final int createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  @override
  @JsonKey(name: 'archived_at')
  final int archivedAt;
  @override
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  @override
  String toString() {
    return 'ContactApi(id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, isPrimary: $isPrimary, sendEmail: $sendEmail, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, createdAt: $createdAt, updatedAt: $updatedAt, archivedAt: $archivedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContactApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary) &&
            (identical(other.sendEmail, sendEmail) ||
                other.sendEmail == sendEmail) &&
            (identical(other.customValue1, customValue1) ||
                other.customValue1 == customValue1) &&
            (identical(other.customValue2, customValue2) ||
                other.customValue2 == customValue2) &&
            (identical(other.customValue3, customValue3) ||
                other.customValue3 == customValue3) &&
            (identical(other.customValue4, customValue4) ||
                other.customValue4 == customValue4) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    firstName,
    lastName,
    email,
    phone,
    isPrimary,
    sendEmail,
    customValue1,
    customValue2,
    customValue3,
    customValue4,
    createdAt,
    updatedAt,
    archivedAt,
    isDeleted,
  );

  /// Create a copy of ContactApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContactApiImplCopyWith<_$ContactApiImpl> get copyWith =>
      __$$ContactApiImplCopyWithImpl<_$ContactApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContactApiImplToJson(this);
  }
}

abstract class _ContactApi implements ContactApi {
  const factory _ContactApi({
    final String id,
    @JsonKey(name: 'first_name') final String firstName,
    @JsonKey(name: 'last_name') final String lastName,
    final String email,
    final String phone,
    @JsonKey(name: 'is_primary') final bool isPrimary,
    @JsonKey(name: 'send_email') final bool sendEmail,
    @JsonKey(name: 'custom_value1') final String customValue1,
    @JsonKey(name: 'custom_value2') final String customValue2,
    @JsonKey(name: 'custom_value3') final String customValue3,
    @JsonKey(name: 'custom_value4') final String customValue4,
    @JsonKey(name: 'created_at') final int createdAt,
    @JsonKey(name: 'updated_at') final int updatedAt,
    @JsonKey(name: 'archived_at') final int archivedAt,
    @JsonKey(name: 'is_deleted') final bool isDeleted,
  }) = _$ContactApiImpl;

  factory _ContactApi.fromJson(Map<String, dynamic> json) =
      _$ContactApiImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'first_name')
  String get firstName;
  @override
  @JsonKey(name: 'last_name')
  String get lastName;
  @override
  String get email;
  @override
  String get phone;
  @override
  @JsonKey(name: 'is_primary')
  bool get isPrimary;
  @override
  @JsonKey(name: 'send_email')
  bool get sendEmail;
  @override
  @JsonKey(name: 'custom_value1')
  String get customValue1;
  @override
  @JsonKey(name: 'custom_value2')
  String get customValue2;
  @override
  @JsonKey(name: 'custom_value3')
  String get customValue3;
  @override
  @JsonKey(name: 'custom_value4')
  String get customValue4;
  @override
  @JsonKey(name: 'created_at')
  int get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  int get updatedAt;
  @override
  @JsonKey(name: 'archived_at')
  int get archivedAt;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;

  /// Create a copy of ContactApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContactApiImplCopyWith<_$ContactApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
