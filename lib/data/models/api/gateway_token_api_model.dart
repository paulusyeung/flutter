import 'package:freezed_annotation/freezed_annotation.dart';

part 'gateway_token_api_model.freezed.dart';
part 'gateway_token_api_model.g.dart';

/// Raw JSON shape of a `client.gateway_tokens[]` entry — a saved payment
/// method (card / bank account) stored at the payment gateway. Read-only on
/// the client; surfaced in the "Payment Methods" detail card. Field names
/// mirror the server keys exactly so `fromJson` is mechanical. Map to the
/// cleaner [GatewayToken] domain type before exposing to ViewModels.
@freezed
abstract class GatewayTokenApi with _$GatewayTokenApi {
  const factory GatewayTokenApi({
    @Default('') String id,
    @JsonKey(name: 'company_gateway_id') @Default('') String companyGatewayId,
    @JsonKey(name: 'gateway_type_id') @Default('') String gatewayTypeId,
    @JsonKey(name: 'gateway_customer_reference')
    @Default('')
    String gatewayCustomerReference,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    // Open-ended gateway metadata — `{brand, last4, exp_month, exp_year,
    // type}` for cards. Value types vary by gateway (last4 / exp may arrive
    // as int or string), so keep it raw and coerce to String in the domain
    // mapper rather than risk a json_serializable type-cast crash.
    Map<String, dynamic>? meta,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _GatewayTokenApi;

  factory GatewayTokenApi.fromJson(Map<String, dynamic> json) =>
      _$GatewayTokenApiFromJson(json);
}
