import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/document_api_model.dart';

part 'vendor_api_model.freezed.dart';
part 'vendor_api_model.g.dart';

/// Raw JSON shape of `/api/v1/vendors/{id}` as returned by the server.
///
/// Field names mirror the server keys via `@JsonKey`. Numeric monetary
/// fields stay as `Object` here because the server is inconsistent
/// (sometimes `"100.00"`, sometimes `100`) — they get parsed via
/// `parseMoney` in `Vendor.fromApi`.
@freezed
abstract class VendorApi with _$VendorApi {
  const factory VendorApi({
    @Default('') String id,
    @Default('') String name,
    @Default('') String number,
    @JsonKey(name: 'id_number') @Default('') String idNumber,
    @JsonKey(name: 'vat_number') @Default('') String vatNumber,
    @Default('') String website,
    @Default('') String phone,
    @Default('') String address1,
    @Default('') String address2,
    @Default('') String city,
    @Default('') String state,
    @JsonKey(name: 'postal_code') @Default('') String postalCode,
    @JsonKey(name: 'country_id') @Default('') String countryId,
    @JsonKey(name: 'balance') @Default('0') Object balance,
    @JsonKey(name: 'paid_to_date') @Default('0') Object paidToDate,
    @JsonKey(name: 'currency_id') @Default('') String currencyId,
    @JsonKey(name: 'private_notes') @Default('') String privateNotes,
    @JsonKey(name: 'public_notes') @Default('') String publicNotes,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'assigned_user_id') @Default('') String assignedUserId,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @Default(<VendorContactApi>[]) List<VendorContactApi> contacts,
    // Nullable on purpose: the IN list endpoint omits `documents` unless
    // `?include=documents` is requested. Distinguishing "key missing"
    // (→ null) from "key present, array empty" (→ `const []`) lets
    // `_apiToCompanion` preserve local docs on responses that didn't
    // include them while still propagating server-side deletes on
    // responses that did. See `VendorRepository._apiToCompanion`.
    List<DocumentApi>? documents,
  }) = _VendorApi;

  factory VendorApi.fromJson(Map<String, dynamic> json) =>
      _$VendorApiFromJson(json);
}

/// Raw JSON shape of a `vendor.contacts[]` entry as returned by the server.
///
/// Mirrors the same set of fields admin-portal's `VendorContactEntity` ships
/// (id + name + email + phone + send_email + password + custom_value1..4).
/// Vendor contacts don't get an `is_primary` flag — the server doesn't
/// expose one and the legacy entity didn't model one either.
@freezed
abstract class VendorContactApi with _$VendorContactApi {
  const factory VendorContactApi({
    @Default('') String id,
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String password,
    @JsonKey(name: 'send_email') @Default(true) bool sendEmail,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _VendorContactApi;

  factory VendorContactApi.fromJson(Map<String, dynamic> json) =>
      _$VendorContactApiFromJson(json);
}

/// Envelope for `/api/v1/vendors` list responses.
@freezed
abstract class VendorListApi with _$VendorListApi {
  const factory VendorListApi({@Default(<VendorApi>[]) List<VendorApi> data}) =
      _VendorListApi;

  factory VendorListApi.fromJson(Map<String, dynamic> json) =>
      _$VendorListApiFromJson(json);
}

/// Envelope for `/api/v1/vendors/{id}` item responses.
@freezed
abstract class VendorItemApi with _$VendorItemApi {
  const factory VendorItemApi({required VendorApi data}) = _VendorItemApi;

  factory VendorItemApi.fromJson(Map<String, dynamic> json) =>
      _$VendorItemApiFromJson(json);
}
