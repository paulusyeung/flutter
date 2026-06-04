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

  /// Union of all webhook events across this provider's payment-type options,
  /// deduped and order-stable. Mirrors admin-portal's
  /// `GatewayEntity.supportedEvents`. Empty when no option declares webhooks.
  List<String> supportedEvents() {
    final seen = <String>{};
    final result = <String>[];
    for (final option in options.values) {
      for (final event in option.webhooks) {
        if (seen.add(event)) result.add(event);
      }
    }
    return result;
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
    this.webhooks = const <String>[],
  });

  final bool supportTokenBilling;
  final bool supportRefunds;

  /// Webhook event names this provider emits for the payment type (e.g.
  /// `net.authorize.payment.void.created`). Surfaced on the gateway detail so
  /// the merchant knows which events to expect. Empty when none are declared.
  final List<String> webhooks;

  factory GatewayOptions.fromMap(Map<String, dynamic> json) => GatewayOptions(
    supportTokenBilling: json['support_token_billing'] == true,
    supportRefunds: json['support_refunds'] == true,
    webhooks: json['webhooks'] is List
        ? (json['webhooks'] as List)
              .map((e) => e.toString())
              .toList(growable: false)
        : const <String>[],
  );
}
