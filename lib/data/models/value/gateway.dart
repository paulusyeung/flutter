import 'dart:convert';

/// Statics-bundle gateway-type entry (Stripe, PayPal, Authorize.Net, …). Each
/// entry describes one available *gateway provider* (not a configured
/// instance); the user creates a `CompanyGateway` against one of these.
///
/// Wire shape mirrors `admin-portal/lib/data/models/company_model.dart`'s
/// `GatewayEntity`. The `fields` blob is a JSON-encoded schema describing the
/// provider's credential form — see [parsedFields] for the parsed view.
class Gateway {
  Gateway({
    required this.id,
    required this.name,
    required this.fields,
    required this.defaultGatewayTypeId,
    required this.sortOrder,
    required this.isOffsite,
    required this.isVisible,
    required this.siteUrl,
    required this.options,
  });

  /// Server-side stable id (the `key` JSON field).
  final String id;
  final String name;

  /// Raw `fields` JSON blob. Lazily parsed via [parsedFields].
  final String fields;

  final String defaultGatewayTypeId;
  final int sortOrder;
  final bool isOffsite;
  final bool isVisible;
  final String siteUrl;

  /// Per-gateway-type options (keyed by `GatewayType.id`). Values describe
  /// whether the provider supports token billing / refunds for that payment
  /// type.
  final Map<String, GatewayOptions> options;

  Map<String, dynamic>? _parsedFields;

  /// Decoded form of [fields]. The map's keys are credential field names; the
  /// values describe how to render them:
  ///  * `bool` → toggle.
  ///  * `String` of `[a,b,c]` → dropdown.
  ///  * Hex-looking string → color picker.
  ///  * Anything else → text input (auto-obscured for password/secret/key/token).
  Map<String, dynamic> get parsedFields {
    if (_parsedFields != null) return _parsedFields!;
    if (fields.isEmpty) return _parsedFields = const {};
    try {
      final decoded = jsonDecode(fields);
      return _parsedFields = decoded is Map<String, dynamic>
          ? decoded
          : const {};
    } catch (_) {
      return _parsedFields = const {};
    }
  }

  factory Gateway.fromMap(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, GatewayOptions>{};
    if (rawOptions is Map) {
      rawOptions.forEach((k, v) {
        if (v is Map) {
          options[k.toString()] = GatewayOptions.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    return Gateway(
      id: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fields: json['fields']?.toString() ?? '',
      defaultGatewayTypeId: json['default_gateway_type_id']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isOffsite: json['is_offsite'] == true,
      isVisible: json['visible'] == true,
      siteUrl: json['site_url']?.toString() ?? '',
      options: options,
    );
  }
}

class GatewayOptions {
  const GatewayOptions({
    required this.supportTokenBilling,
    required this.supportRefunds,
  });

  final bool supportTokenBilling;
  final bool supportRefunds;

  factory GatewayOptions.fromMap(Map<String, dynamic> json) => GatewayOptions(
    supportTokenBilling: json['support_token_billing'] == true,
    supportRefunds: json['support_refunds'] == true,
  );
}
