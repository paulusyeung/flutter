import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_api_model.freezed.dart';
part 'location_api_model.g.dart';

/// Raw JSON shape of a `client.locations[]` entry (also the body shape for
/// the standalone `/api/v1/locations` CRUD endpoints). Field names mirror
/// the server keys exactly so `fromJson` is mechanical. Map to the cleaner
/// [Location] domain type before exposing to ViewModels.
@freezed
abstract class LocationApi with _$LocationApi {
  const factory LocationApi({
    @Default('') String id,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'vendor_id') @Default('') String vendorId,
    @JsonKey(name: 'client_id') @Default('') String clientId,
    @Default('') String name,
    @Default('') String address1,
    @Default('') String address2,
    @Default('') String city,
    @Default('') String state,
    @JsonKey(name: 'postal_code') @Default('') String postalCode,
    @JsonKey(name: 'country_id') @Default('') String countryId,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'is_shipping_location')
    @Default(false)
    bool isShippingLocation,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _LocationApi;

  factory LocationApi.fromJson(Map<String, dynamic> json) =>
      _$LocationApiFromJson(json);
}
