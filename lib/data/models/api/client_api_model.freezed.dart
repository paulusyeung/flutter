// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ClientApi _$ClientApiFromJson(Map<String, dynamic> json) {
  return _ClientApi.fromJson(json);
}

/// @nodoc
mixin _$ClientApi {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String get number => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_number')
  String get idNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'vat_number')
  String get vatNumber => throw _privateConstructorUsedError;
  String get website => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone')
  String get phone => throw _privateConstructorUsedError;
  String get address1 => throw _privateConstructorUsedError;
  String get address2 => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'postal_code')
  String get postalCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_id')
  String get countryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_address1')
  String get shippingAddress1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_address2')
  String get shippingAddress2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_city')
  String get shippingCity => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_state')
  String get shippingState => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_postal_code')
  String get shippingPostalCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'shipping_country_id')
  String get shippingCountryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'balance')
  Object get balance => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_to_date')
  Object get paidToDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_balance')
  Object get creditBalance => throw _privateConstructorUsedError;
  @JsonKey(name: 'currency_id')
  String get currencyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'language_id')
  String get languageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_terms')
  String get paymentTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'private_notes')
  String get privateNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'public_notes')
  String get publicNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value1')
  String get customValue1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value2')
  String get customValue2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value3')
  String get customValue3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value4')
  String get customValue4 => throw _privateConstructorUsedError;
  @JsonKey(name: 'group_settings_id')
  String get groupSettingsId => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_user_id')
  String get assignedUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'archived_at')
  int get archivedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;
  List<ContactApi> get contacts => throw _privateConstructorUsedError;

  /// Serializes this ClientApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientApiCopyWith<ClientApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientApiCopyWith<$Res> {
  factory $ClientApiCopyWith(ClientApi value, $Res Function(ClientApi) then) =
      _$ClientApiCopyWithImpl<$Res, ClientApi>;
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'display_name') String displayName,
    String number,
    @JsonKey(name: 'id_number') String idNumber,
    @JsonKey(name: 'vat_number') String vatNumber,
    String website,
    @JsonKey(name: 'phone') String phone,
    String address1,
    String address2,
    String city,
    String state,
    @JsonKey(name: 'postal_code') String postalCode,
    @JsonKey(name: 'country_id') String countryId,
    @JsonKey(name: 'shipping_address1') String shippingAddress1,
    @JsonKey(name: 'shipping_address2') String shippingAddress2,
    @JsonKey(name: 'shipping_city') String shippingCity,
    @JsonKey(name: 'shipping_state') String shippingState,
    @JsonKey(name: 'shipping_postal_code') String shippingPostalCode,
    @JsonKey(name: 'shipping_country_id') String shippingCountryId,
    @JsonKey(name: 'balance') Object balance,
    @JsonKey(name: 'paid_to_date') Object paidToDate,
    @JsonKey(name: 'credit_balance') Object creditBalance,
    @JsonKey(name: 'currency_id') String currencyId,
    @JsonKey(name: 'language_id') String languageId,
    @JsonKey(name: 'payment_terms') String paymentTerms,
    @JsonKey(name: 'private_notes') String privateNotes,
    @JsonKey(name: 'public_notes') String publicNotes,
    @JsonKey(name: 'custom_value1') String customValue1,
    @JsonKey(name: 'custom_value2') String customValue2,
    @JsonKey(name: 'custom_value3') String customValue3,
    @JsonKey(name: 'custom_value4') String customValue4,
    @JsonKey(name: 'group_settings_id') String groupSettingsId,
    @JsonKey(name: 'assigned_user_id') String assignedUserId,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    List<ContactApi> contacts,
  });
}

/// @nodoc
class _$ClientApiCopyWithImpl<$Res, $Val extends ClientApi>
    implements $ClientApiCopyWith<$Res> {
  _$ClientApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? number = null,
    Object? idNumber = null,
    Object? vatNumber = null,
    Object? website = null,
    Object? phone = null,
    Object? address1 = null,
    Object? address2 = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? countryId = null,
    Object? shippingAddress1 = null,
    Object? shippingAddress2 = null,
    Object? shippingCity = null,
    Object? shippingState = null,
    Object? shippingPostalCode = null,
    Object? shippingCountryId = null,
    Object? balance = null,
    Object? paidToDate = null,
    Object? creditBalance = null,
    Object? currencyId = null,
    Object? languageId = null,
    Object? paymentTerms = null,
    Object? privateNotes = null,
    Object? publicNotes = null,
    Object? customValue1 = null,
    Object? customValue2 = null,
    Object? customValue3 = null,
    Object? customValue4 = null,
    Object? groupSettingsId = null,
    Object? assignedUserId = null,
    Object? userId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
    Object? isDeleted = null,
    Object? contacts = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            number: null == number
                ? _value.number
                : number // ignore: cast_nullable_to_non_nullable
                      as String,
            idNumber: null == idNumber
                ? _value.idNumber
                : idNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            vatNumber: null == vatNumber
                ? _value.vatNumber
                : vatNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            website: null == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            address1: null == address1
                ? _value.address1
                : address1 // ignore: cast_nullable_to_non_nullable
                      as String,
            address2: null == address2
                ? _value.address2
                : address2 // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            postalCode: null == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String,
            countryId: null == countryId
                ? _value.countryId
                : countryId // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingAddress1: null == shippingAddress1
                ? _value.shippingAddress1
                : shippingAddress1 // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingAddress2: null == shippingAddress2
                ? _value.shippingAddress2
                : shippingAddress2 // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingCity: null == shippingCity
                ? _value.shippingCity
                : shippingCity // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingState: null == shippingState
                ? _value.shippingState
                : shippingState // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingPostalCode: null == shippingPostalCode
                ? _value.shippingPostalCode
                : shippingPostalCode // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingCountryId: null == shippingCountryId
                ? _value.shippingCountryId
                : shippingCountryId // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: null == balance ? _value.balance : balance,
            paidToDate: null == paidToDate ? _value.paidToDate : paidToDate,
            creditBalance: null == creditBalance
                ? _value.creditBalance
                : creditBalance,
            currencyId: null == currencyId
                ? _value.currencyId
                : currencyId // ignore: cast_nullable_to_non_nullable
                      as String,
            languageId: null == languageId
                ? _value.languageId
                : languageId // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentTerms: null == paymentTerms
                ? _value.paymentTerms
                : paymentTerms // ignore: cast_nullable_to_non_nullable
                      as String,
            privateNotes: null == privateNotes
                ? _value.privateNotes
                : privateNotes // ignore: cast_nullable_to_non_nullable
                      as String,
            publicNotes: null == publicNotes
                ? _value.publicNotes
                : publicNotes // ignore: cast_nullable_to_non_nullable
                      as String,
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
            groupSettingsId: null == groupSettingsId
                ? _value.groupSettingsId
                : groupSettingsId // ignore: cast_nullable_to_non_nullable
                      as String,
            assignedUserId: null == assignedUserId
                ? _value.assignedUserId
                : assignedUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
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
            contacts: null == contacts
                ? _value.contacts
                : contacts // ignore: cast_nullable_to_non_nullable
                      as List<ContactApi>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClientApiImplCopyWith<$Res>
    implements $ClientApiCopyWith<$Res> {
  factory _$$ClientApiImplCopyWith(
    _$ClientApiImpl value,
    $Res Function(_$ClientApiImpl) then,
  ) = __$$ClientApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'display_name') String displayName,
    String number,
    @JsonKey(name: 'id_number') String idNumber,
    @JsonKey(name: 'vat_number') String vatNumber,
    String website,
    @JsonKey(name: 'phone') String phone,
    String address1,
    String address2,
    String city,
    String state,
    @JsonKey(name: 'postal_code') String postalCode,
    @JsonKey(name: 'country_id') String countryId,
    @JsonKey(name: 'shipping_address1') String shippingAddress1,
    @JsonKey(name: 'shipping_address2') String shippingAddress2,
    @JsonKey(name: 'shipping_city') String shippingCity,
    @JsonKey(name: 'shipping_state') String shippingState,
    @JsonKey(name: 'shipping_postal_code') String shippingPostalCode,
    @JsonKey(name: 'shipping_country_id') String shippingCountryId,
    @JsonKey(name: 'balance') Object balance,
    @JsonKey(name: 'paid_to_date') Object paidToDate,
    @JsonKey(name: 'credit_balance') Object creditBalance,
    @JsonKey(name: 'currency_id') String currencyId,
    @JsonKey(name: 'language_id') String languageId,
    @JsonKey(name: 'payment_terms') String paymentTerms,
    @JsonKey(name: 'private_notes') String privateNotes,
    @JsonKey(name: 'public_notes') String publicNotes,
    @JsonKey(name: 'custom_value1') String customValue1,
    @JsonKey(name: 'custom_value2') String customValue2,
    @JsonKey(name: 'custom_value3') String customValue3,
    @JsonKey(name: 'custom_value4') String customValue4,
    @JsonKey(name: 'group_settings_id') String groupSettingsId,
    @JsonKey(name: 'assigned_user_id') String assignedUserId,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    @JsonKey(name: 'archived_at') int archivedAt,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    List<ContactApi> contacts,
  });
}

/// @nodoc
class __$$ClientApiImplCopyWithImpl<$Res>
    extends _$ClientApiCopyWithImpl<$Res, _$ClientApiImpl>
    implements _$$ClientApiImplCopyWith<$Res> {
  __$$ClientApiImplCopyWithImpl(
    _$ClientApiImpl _value,
    $Res Function(_$ClientApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClientApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? number = null,
    Object? idNumber = null,
    Object? vatNumber = null,
    Object? website = null,
    Object? phone = null,
    Object? address1 = null,
    Object? address2 = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? countryId = null,
    Object? shippingAddress1 = null,
    Object? shippingAddress2 = null,
    Object? shippingCity = null,
    Object? shippingState = null,
    Object? shippingPostalCode = null,
    Object? shippingCountryId = null,
    Object? balance = null,
    Object? paidToDate = null,
    Object? creditBalance = null,
    Object? currencyId = null,
    Object? languageId = null,
    Object? paymentTerms = null,
    Object? privateNotes = null,
    Object? publicNotes = null,
    Object? customValue1 = null,
    Object? customValue2 = null,
    Object? customValue3 = null,
    Object? customValue4 = null,
    Object? groupSettingsId = null,
    Object? assignedUserId = null,
    Object? userId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? archivedAt = null,
    Object? isDeleted = null,
    Object? contacts = null,
  }) {
    return _then(
      _$ClientApiImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        number: null == number
            ? _value.number
            : number // ignore: cast_nullable_to_non_nullable
                  as String,
        idNumber: null == idNumber
            ? _value.idNumber
            : idNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        vatNumber: null == vatNumber
            ? _value.vatNumber
            : vatNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        website: null == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        address1: null == address1
            ? _value.address1
            : address1 // ignore: cast_nullable_to_non_nullable
                  as String,
        address2: null == address2
            ? _value.address2
            : address2 // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        postalCode: null == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String,
        countryId: null == countryId
            ? _value.countryId
            : countryId // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingAddress1: null == shippingAddress1
            ? _value.shippingAddress1
            : shippingAddress1 // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingAddress2: null == shippingAddress2
            ? _value.shippingAddress2
            : shippingAddress2 // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingCity: null == shippingCity
            ? _value.shippingCity
            : shippingCity // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingState: null == shippingState
            ? _value.shippingState
            : shippingState // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingPostalCode: null == shippingPostalCode
            ? _value.shippingPostalCode
            : shippingPostalCode // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingCountryId: null == shippingCountryId
            ? _value.shippingCountryId
            : shippingCountryId // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: null == balance ? _value.balance : balance,
        paidToDate: null == paidToDate ? _value.paidToDate : paidToDate,
        creditBalance: null == creditBalance
            ? _value.creditBalance
            : creditBalance,
        currencyId: null == currencyId
            ? _value.currencyId
            : currencyId // ignore: cast_nullable_to_non_nullable
                  as String,
        languageId: null == languageId
            ? _value.languageId
            : languageId // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentTerms: null == paymentTerms
            ? _value.paymentTerms
            : paymentTerms // ignore: cast_nullable_to_non_nullable
                  as String,
        privateNotes: null == privateNotes
            ? _value.privateNotes
            : privateNotes // ignore: cast_nullable_to_non_nullable
                  as String,
        publicNotes: null == publicNotes
            ? _value.publicNotes
            : publicNotes // ignore: cast_nullable_to_non_nullable
                  as String,
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
        groupSettingsId: null == groupSettingsId
            ? _value.groupSettingsId
            : groupSettingsId // ignore: cast_nullable_to_non_nullable
                  as String,
        assignedUserId: null == assignedUserId
            ? _value.assignedUserId
            : assignedUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
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
        contacts: null == contacts
            ? _value._contacts
            : contacts // ignore: cast_nullable_to_non_nullable
                  as List<ContactApi>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientApiImpl implements _ClientApi {
  const _$ClientApiImpl({
    this.id = '',
    this.name = '',
    @JsonKey(name: 'display_name') this.displayName = '',
    this.number = '',
    @JsonKey(name: 'id_number') this.idNumber = '',
    @JsonKey(name: 'vat_number') this.vatNumber = '',
    this.website = '',
    @JsonKey(name: 'phone') this.phone = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    @JsonKey(name: 'postal_code') this.postalCode = '',
    @JsonKey(name: 'country_id') this.countryId = '',
    @JsonKey(name: 'shipping_address1') this.shippingAddress1 = '',
    @JsonKey(name: 'shipping_address2') this.shippingAddress2 = '',
    @JsonKey(name: 'shipping_city') this.shippingCity = '',
    @JsonKey(name: 'shipping_state') this.shippingState = '',
    @JsonKey(name: 'shipping_postal_code') this.shippingPostalCode = '',
    @JsonKey(name: 'shipping_country_id') this.shippingCountryId = '',
    @JsonKey(name: 'balance') this.balance = '0',
    @JsonKey(name: 'paid_to_date') this.paidToDate = '0',
    @JsonKey(name: 'credit_balance') this.creditBalance = '0',
    @JsonKey(name: 'currency_id') this.currencyId = '',
    @JsonKey(name: 'language_id') this.languageId = '',
    @JsonKey(name: 'payment_terms') this.paymentTerms = '',
    @JsonKey(name: 'private_notes') this.privateNotes = '',
    @JsonKey(name: 'public_notes') this.publicNotes = '',
    @JsonKey(name: 'custom_value1') this.customValue1 = '',
    @JsonKey(name: 'custom_value2') this.customValue2 = '',
    @JsonKey(name: 'custom_value3') this.customValue3 = '',
    @JsonKey(name: 'custom_value4') this.customValue4 = '',
    @JsonKey(name: 'group_settings_id') this.groupSettingsId = '',
    @JsonKey(name: 'assigned_user_id') this.assignedUserId = '',
    @JsonKey(name: 'user_id') this.userId = '',
    @JsonKey(name: 'created_at') this.createdAt = 0,
    @JsonKey(name: 'updated_at') this.updatedAt = 0,
    @JsonKey(name: 'archived_at') this.archivedAt = 0,
    @JsonKey(name: 'is_deleted') this.isDeleted = false,
    final List<ContactApi> contacts = const <ContactApi>[],
  }) : _contacts = contacts;

  factory _$ClientApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientApiImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey()
  final String number;
  @override
  @JsonKey(name: 'id_number')
  final String idNumber;
  @override
  @JsonKey(name: 'vat_number')
  final String vatNumber;
  @override
  @JsonKey()
  final String website;
  @override
  @JsonKey(name: 'phone')
  final String phone;
  @override
  @JsonKey()
  final String address1;
  @override
  @JsonKey()
  final String address2;
  @override
  @JsonKey()
  final String city;
  @override
  @JsonKey()
  final String state;
  @override
  @JsonKey(name: 'postal_code')
  final String postalCode;
  @override
  @JsonKey(name: 'country_id')
  final String countryId;
  @override
  @JsonKey(name: 'shipping_address1')
  final String shippingAddress1;
  @override
  @JsonKey(name: 'shipping_address2')
  final String shippingAddress2;
  @override
  @JsonKey(name: 'shipping_city')
  final String shippingCity;
  @override
  @JsonKey(name: 'shipping_state')
  final String shippingState;
  @override
  @JsonKey(name: 'shipping_postal_code')
  final String shippingPostalCode;
  @override
  @JsonKey(name: 'shipping_country_id')
  final String shippingCountryId;
  @override
  @JsonKey(name: 'balance')
  final Object balance;
  @override
  @JsonKey(name: 'paid_to_date')
  final Object paidToDate;
  @override
  @JsonKey(name: 'credit_balance')
  final Object creditBalance;
  @override
  @JsonKey(name: 'currency_id')
  final String currencyId;
  @override
  @JsonKey(name: 'language_id')
  final String languageId;
  @override
  @JsonKey(name: 'payment_terms')
  final String paymentTerms;
  @override
  @JsonKey(name: 'private_notes')
  final String privateNotes;
  @override
  @JsonKey(name: 'public_notes')
  final String publicNotes;
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
  @JsonKey(name: 'group_settings_id')
  final String groupSettingsId;
  @override
  @JsonKey(name: 'assigned_user_id')
  final String assignedUserId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
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
  final List<ContactApi> _contacts;
  @override
  @JsonKey()
  List<ContactApi> get contacts {
    if (_contacts is EqualUnmodifiableListView) return _contacts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contacts);
  }

  @override
  String toString() {
    return 'ClientApi(id: $id, name: $name, displayName: $displayName, number: $number, idNumber: $idNumber, vatNumber: $vatNumber, website: $website, phone: $phone, address1: $address1, address2: $address2, city: $city, state: $state, postalCode: $postalCode, countryId: $countryId, shippingAddress1: $shippingAddress1, shippingAddress2: $shippingAddress2, shippingCity: $shippingCity, shippingState: $shippingState, shippingPostalCode: $shippingPostalCode, shippingCountryId: $shippingCountryId, balance: $balance, paidToDate: $paidToDate, creditBalance: $creditBalance, currencyId: $currencyId, languageId: $languageId, paymentTerms: $paymentTerms, privateNotes: $privateNotes, publicNotes: $publicNotes, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, groupSettingsId: $groupSettingsId, assignedUserId: $assignedUserId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, archivedAt: $archivedAt, isDeleted: $isDeleted, contacts: $contacts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.idNumber, idNumber) ||
                other.idNumber == idNumber) &&
            (identical(other.vatNumber, vatNumber) ||
                other.vatNumber == vatNumber) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address1, address1) ||
                other.address1 == address1) &&
            (identical(other.address2, address2) ||
                other.address2 == address2) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.shippingAddress1, shippingAddress1) ||
                other.shippingAddress1 == shippingAddress1) &&
            (identical(other.shippingAddress2, shippingAddress2) ||
                other.shippingAddress2 == shippingAddress2) &&
            (identical(other.shippingCity, shippingCity) ||
                other.shippingCity == shippingCity) &&
            (identical(other.shippingState, shippingState) ||
                other.shippingState == shippingState) &&
            (identical(other.shippingPostalCode, shippingPostalCode) ||
                other.shippingPostalCode == shippingPostalCode) &&
            (identical(other.shippingCountryId, shippingCountryId) ||
                other.shippingCountryId == shippingCountryId) &&
            const DeepCollectionEquality().equals(other.balance, balance) &&
            const DeepCollectionEquality().equals(
              other.paidToDate,
              paidToDate,
            ) &&
            const DeepCollectionEquality().equals(
              other.creditBalance,
              creditBalance,
            ) &&
            (identical(other.currencyId, currencyId) ||
                other.currencyId == currencyId) &&
            (identical(other.languageId, languageId) ||
                other.languageId == languageId) &&
            (identical(other.paymentTerms, paymentTerms) ||
                other.paymentTerms == paymentTerms) &&
            (identical(other.privateNotes, privateNotes) ||
                other.privateNotes == privateNotes) &&
            (identical(other.publicNotes, publicNotes) ||
                other.publicNotes == publicNotes) &&
            (identical(other.customValue1, customValue1) ||
                other.customValue1 == customValue1) &&
            (identical(other.customValue2, customValue2) ||
                other.customValue2 == customValue2) &&
            (identical(other.customValue3, customValue3) ||
                other.customValue3 == customValue3) &&
            (identical(other.customValue4, customValue4) ||
                other.customValue4 == customValue4) &&
            (identical(other.groupSettingsId, groupSettingsId) ||
                other.groupSettingsId == groupSettingsId) &&
            (identical(other.assignedUserId, assignedUserId) ||
                other.assignedUserId == assignedUserId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            const DeepCollectionEquality().equals(other._contacts, _contacts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    displayName,
    number,
    idNumber,
    vatNumber,
    website,
    phone,
    address1,
    address2,
    city,
    state,
    postalCode,
    countryId,
    shippingAddress1,
    shippingAddress2,
    shippingCity,
    shippingState,
    shippingPostalCode,
    shippingCountryId,
    const DeepCollectionEquality().hash(balance),
    const DeepCollectionEquality().hash(paidToDate),
    const DeepCollectionEquality().hash(creditBalance),
    currencyId,
    languageId,
    paymentTerms,
    privateNotes,
    publicNotes,
    customValue1,
    customValue2,
    customValue3,
    customValue4,
    groupSettingsId,
    assignedUserId,
    userId,
    createdAt,
    updatedAt,
    archivedAt,
    isDeleted,
    const DeepCollectionEquality().hash(_contacts),
  ]);

  /// Create a copy of ClientApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientApiImplCopyWith<_$ClientApiImpl> get copyWith =>
      __$$ClientApiImplCopyWithImpl<_$ClientApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientApiImplToJson(this);
  }
}

abstract class _ClientApi implements ClientApi {
  const factory _ClientApi({
    final String id,
    final String name,
    @JsonKey(name: 'display_name') final String displayName,
    final String number,
    @JsonKey(name: 'id_number') final String idNumber,
    @JsonKey(name: 'vat_number') final String vatNumber,
    final String website,
    @JsonKey(name: 'phone') final String phone,
    final String address1,
    final String address2,
    final String city,
    final String state,
    @JsonKey(name: 'postal_code') final String postalCode,
    @JsonKey(name: 'country_id') final String countryId,
    @JsonKey(name: 'shipping_address1') final String shippingAddress1,
    @JsonKey(name: 'shipping_address2') final String shippingAddress2,
    @JsonKey(name: 'shipping_city') final String shippingCity,
    @JsonKey(name: 'shipping_state') final String shippingState,
    @JsonKey(name: 'shipping_postal_code') final String shippingPostalCode,
    @JsonKey(name: 'shipping_country_id') final String shippingCountryId,
    @JsonKey(name: 'balance') final Object balance,
    @JsonKey(name: 'paid_to_date') final Object paidToDate,
    @JsonKey(name: 'credit_balance') final Object creditBalance,
    @JsonKey(name: 'currency_id') final String currencyId,
    @JsonKey(name: 'language_id') final String languageId,
    @JsonKey(name: 'payment_terms') final String paymentTerms,
    @JsonKey(name: 'private_notes') final String privateNotes,
    @JsonKey(name: 'public_notes') final String publicNotes,
    @JsonKey(name: 'custom_value1') final String customValue1,
    @JsonKey(name: 'custom_value2') final String customValue2,
    @JsonKey(name: 'custom_value3') final String customValue3,
    @JsonKey(name: 'custom_value4') final String customValue4,
    @JsonKey(name: 'group_settings_id') final String groupSettingsId,
    @JsonKey(name: 'assigned_user_id') final String assignedUserId,
    @JsonKey(name: 'user_id') final String userId,
    @JsonKey(name: 'created_at') final int createdAt,
    @JsonKey(name: 'updated_at') final int updatedAt,
    @JsonKey(name: 'archived_at') final int archivedAt,
    @JsonKey(name: 'is_deleted') final bool isDeleted,
    final List<ContactApi> contacts,
  }) = _$ClientApiImpl;

  factory _ClientApi.fromJson(Map<String, dynamic> json) =
      _$ClientApiImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String get number;
  @override
  @JsonKey(name: 'id_number')
  String get idNumber;
  @override
  @JsonKey(name: 'vat_number')
  String get vatNumber;
  @override
  String get website;
  @override
  @JsonKey(name: 'phone')
  String get phone;
  @override
  String get address1;
  @override
  String get address2;
  @override
  String get city;
  @override
  String get state;
  @override
  @JsonKey(name: 'postal_code')
  String get postalCode;
  @override
  @JsonKey(name: 'country_id')
  String get countryId;
  @override
  @JsonKey(name: 'shipping_address1')
  String get shippingAddress1;
  @override
  @JsonKey(name: 'shipping_address2')
  String get shippingAddress2;
  @override
  @JsonKey(name: 'shipping_city')
  String get shippingCity;
  @override
  @JsonKey(name: 'shipping_state')
  String get shippingState;
  @override
  @JsonKey(name: 'shipping_postal_code')
  String get shippingPostalCode;
  @override
  @JsonKey(name: 'shipping_country_id')
  String get shippingCountryId;
  @override
  @JsonKey(name: 'balance')
  Object get balance;
  @override
  @JsonKey(name: 'paid_to_date')
  Object get paidToDate;
  @override
  @JsonKey(name: 'credit_balance')
  Object get creditBalance;
  @override
  @JsonKey(name: 'currency_id')
  String get currencyId;
  @override
  @JsonKey(name: 'language_id')
  String get languageId;
  @override
  @JsonKey(name: 'payment_terms')
  String get paymentTerms;
  @override
  @JsonKey(name: 'private_notes')
  String get privateNotes;
  @override
  @JsonKey(name: 'public_notes')
  String get publicNotes;
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
  @JsonKey(name: 'group_settings_id')
  String get groupSettingsId;
  @override
  @JsonKey(name: 'assigned_user_id')
  String get assignedUserId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
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
  @override
  List<ContactApi> get contacts;

  /// Create a copy of ClientApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientApiImplCopyWith<_$ClientApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientListApi _$ClientListApiFromJson(Map<String, dynamic> json) {
  return _ClientListApi.fromJson(json);
}

/// @nodoc
mixin _$ClientListApi {
  List<ClientApi> get data => throw _privateConstructorUsedError;

  /// Serializes this ClientListApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientListApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientListApiCopyWith<ClientListApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientListApiCopyWith<$Res> {
  factory $ClientListApiCopyWith(
    ClientListApi value,
    $Res Function(ClientListApi) then,
  ) = _$ClientListApiCopyWithImpl<$Res, ClientListApi>;
  @useResult
  $Res call({List<ClientApi> data});
}

/// @nodoc
class _$ClientListApiCopyWithImpl<$Res, $Val extends ClientListApi>
    implements $ClientListApiCopyWith<$Res> {
  _$ClientListApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientListApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<ClientApi>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClientListApiImplCopyWith<$Res>
    implements $ClientListApiCopyWith<$Res> {
  factory _$$ClientListApiImplCopyWith(
    _$ClientListApiImpl value,
    $Res Function(_$ClientListApiImpl) then,
  ) = __$$ClientListApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ClientApi> data});
}

/// @nodoc
class __$$ClientListApiImplCopyWithImpl<$Res>
    extends _$ClientListApiCopyWithImpl<$Res, _$ClientListApiImpl>
    implements _$$ClientListApiImplCopyWith<$Res> {
  __$$ClientListApiImplCopyWithImpl(
    _$ClientListApiImpl _value,
    $Res Function(_$ClientListApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClientListApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$ClientListApiImpl(
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<ClientApi>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientListApiImpl implements _ClientListApi {
  const _$ClientListApiImpl({final List<ClientApi> data = const <ClientApi>[]})
    : _data = data;

  factory _$ClientListApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientListApiImplFromJson(json);

  final List<ClientApi> _data;
  @override
  @JsonKey()
  List<ClientApi> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  String toString() {
    return 'ClientListApi(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientListApiImpl &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  /// Create a copy of ClientListApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientListApiImplCopyWith<_$ClientListApiImpl> get copyWith =>
      __$$ClientListApiImplCopyWithImpl<_$ClientListApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientListApiImplToJson(this);
  }
}

abstract class _ClientListApi implements ClientListApi {
  const factory _ClientListApi({final List<ClientApi> data}) =
      _$ClientListApiImpl;

  factory _ClientListApi.fromJson(Map<String, dynamic> json) =
      _$ClientListApiImpl.fromJson;

  @override
  List<ClientApi> get data;

  /// Create a copy of ClientListApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientListApiImplCopyWith<_$ClientListApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientItemApi _$ClientItemApiFromJson(Map<String, dynamic> json) {
  return _ClientItemApi.fromJson(json);
}

/// @nodoc
mixin _$ClientItemApi {
  ClientApi get data => throw _privateConstructorUsedError;

  /// Serializes this ClientItemApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientItemApiCopyWith<ClientItemApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientItemApiCopyWith<$Res> {
  factory $ClientItemApiCopyWith(
    ClientItemApi value,
    $Res Function(ClientItemApi) then,
  ) = _$ClientItemApiCopyWithImpl<$Res, ClientItemApi>;
  @useResult
  $Res call({ClientApi data});

  $ClientApiCopyWith<$Res> get data;
}

/// @nodoc
class _$ClientItemApiCopyWithImpl<$Res, $Val extends ClientItemApi>
    implements $ClientItemApiCopyWith<$Res> {
  _$ClientItemApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as ClientApi,
          )
          as $Val,
    );
  }

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientApiCopyWith<$Res> get data {
    return $ClientApiCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClientItemApiImplCopyWith<$Res>
    implements $ClientItemApiCopyWith<$Res> {
  factory _$$ClientItemApiImplCopyWith(
    _$ClientItemApiImpl value,
    $Res Function(_$ClientItemApiImpl) then,
  ) = __$$ClientItemApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ClientApi data});

  @override
  $ClientApiCopyWith<$Res> get data;
}

/// @nodoc
class __$$ClientItemApiImplCopyWithImpl<$Res>
    extends _$ClientItemApiCopyWithImpl<$Res, _$ClientItemApiImpl>
    implements _$$ClientItemApiImplCopyWith<$Res> {
  __$$ClientItemApiImplCopyWithImpl(
    _$ClientItemApiImpl _value,
    $Res Function(_$ClientItemApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$ClientItemApiImpl(
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as ClientApi,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientItemApiImpl implements _ClientItemApi {
  const _$ClientItemApiImpl({required this.data});

  factory _$ClientItemApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientItemApiImplFromJson(json);

  @override
  final ClientApi data;

  @override
  String toString() {
    return 'ClientItemApi(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientItemApiImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientItemApiImplCopyWith<_$ClientItemApiImpl> get copyWith =>
      __$$ClientItemApiImplCopyWithImpl<_$ClientItemApiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientItemApiImplToJson(this);
  }
}

abstract class _ClientItemApi implements ClientItemApi {
  const factory _ClientItemApi({required final ClientApi data}) =
      _$ClientItemApiImpl;

  factory _ClientItemApi.fromJson(Map<String, dynamic> json) =
      _$ClientItemApiImpl.fromJson;

  @override
  ClientApi get data;

  /// Create a copy of ClientItemApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientItemApiImplCopyWith<_$ClientItemApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
