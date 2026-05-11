import 'package:freezed_annotation/freezed_annotation.dart';

import 'contact_api_model.dart';

part 'client_api_model.freezed.dart';
part 'client_api_model.g.dart';

/// Raw JSON shape of `/api/v1/clients/{id}` as returned by the server.
///
/// Field names mirror the server keys via `@JsonKey`. Numeric monetary fields
/// stay as `String` here because the server is inconsistent (sometimes
/// `"100.00"`, sometimes `100`) — they get parsed via `parseMoney` in
/// `Client.fromApi`.
@freezed
class ClientApi with _$ClientApi {
  const factory ClientApi({
    @Default('') String id,
    @Default('') String name,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String number,
    @JsonKey(name: 'id_number') @Default('') String idNumber,
    @JsonKey(name: 'vat_number') @Default('') String vatNumber,
    @Default('') String website,
    @JsonKey(name: 'phone') @Default('') String phone,
    @Default('') String address1,
    @Default('') String address2,
    @Default('') String city,
    @Default('') String state,
    @JsonKey(name: 'postal_code') @Default('') String postalCode,
    @JsonKey(name: 'country_id') @Default('') String countryId,
    @JsonKey(name: 'shipping_address1') @Default('') String shippingAddress1,
    @JsonKey(name: 'shipping_address2') @Default('') String shippingAddress2,
    @JsonKey(name: 'shipping_city') @Default('') String shippingCity,
    @JsonKey(name: 'shipping_state') @Default('') String shippingState,
    @JsonKey(name: 'shipping_postal_code')
    @Default('')
    String shippingPostalCode,
    @JsonKey(name: 'shipping_country_id') @Default('') String shippingCountryId,
    @JsonKey(name: 'balance') @Default('0') Object balance,
    @JsonKey(name: 'paid_to_date') @Default('0') Object paidToDate,
    @JsonKey(name: 'credit_balance') @Default('0') Object creditBalance,
    @JsonKey(name: 'currency_id') @Default('') String currencyId,
    @JsonKey(name: 'language_id') @Default('') String languageId,
    @JsonKey(name: 'payment_terms') @Default('') String paymentTerms,
    @JsonKey(name: 'private_notes') @Default('') String privateNotes,
    @JsonKey(name: 'public_notes') @Default('') String publicNotes,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'group_settings_id') @Default('') String groupSettingsId,
    @JsonKey(name: 'assigned_user_id') @Default('') String assignedUserId,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @Default(<ContactApi>[]) List<ContactApi> contacts,
  }) = _ClientApi;

  factory ClientApi.fromJson(Map<String, dynamic> json) =>
      _$ClientApiFromJson(json);
}

/// Envelope for `/api/v1/clients` list responses.
@freezed
class ClientListApi with _$ClientListApi {
  const factory ClientListApi({@Default(<ClientApi>[]) List<ClientApi> data}) =
      _ClientListApi;

  factory ClientListApi.fromJson(Map<String, dynamic> json) =>
      _$ClientListApiFromJson(json);
}

/// Envelope for `/api/v1/clients/{id}` item responses.
@freezed
class ClientItemApi with _$ClientItemApi {
  const factory ClientItemApi({required ClientApi data}) = _ClientItemApi;

  factory ClientItemApi.fromJson(Map<String, dynamic> json) =>
      _$ClientItemApiFromJson(json);
}
