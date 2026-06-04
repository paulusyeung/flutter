import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/gateway_token_api_model.dart';

part 'gateway_token.freezed.dart';

/// Clean domain shape for a saved payment method (gateway token), read-
/// embedded on [Client]. Display-only: the "Payment Methods" card surfaces
/// brand + last4 + expiry + a default badge. Managed server-side only — never
/// part of the client save payload.
@freezed
abstract class GatewayToken with _$GatewayToken {
  const factory GatewayToken({
    required String id,
    required String companyGatewayId,
    required String gatewayTypeId,
    required String customerReference,
    required bool isDefault,
    @Default('') String brand,
    @Default('') String last4,
    @Default('') String expMonth,
    @Default('') String expYear,
    @Default('') String cardType,
  }) = _GatewayToken;

  factory GatewayToken.fromApi(GatewayTokenApi a) {
    final m = a.meta ?? const <String, dynamic>{};
    String s(String key) => m[key]?.toString() ?? '';
    return GatewayToken(
      id: a.id,
      companyGatewayId: a.companyGatewayId,
      gatewayTypeId: a.gatewayTypeId,
      customerReference: a.gatewayCustomerReference,
      isDefault: a.isDefault,
      brand: s('brand'),
      last4: s('last4'),
      expMonth: s('exp_month'),
      expYear: s('exp_year'),
      cardType: s('type'),
    );
  }
}

extension GatewayTokenCopy on GatewayToken {
  /// Reconstruct the API JSON so a read-only token survives a local client
  /// save round-trip through the Drift `payload` column (injected in
  /// `ClientRepository._domainToCompanion`). Never sent to the server.
  Map<String, dynamic> toApiJson() => {
    'id': id,
    'company_gateway_id': companyGatewayId,
    'gateway_type_id': gatewayTypeId,
    'gateway_customer_reference': customerReference,
    'is_default': isDefault,
    'meta': {
      'brand': brand,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
      'type': cardType,
    },
  };
}
