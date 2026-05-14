/// Statics-bundle gateway-type entry — a payment method type accepted by a
/// gateway (credit_card, bank_transfer, paypal, sepa, …). Keyed by stable
/// numeric id as a string; the [name] is the server label (snake_case English
/// — the UI typically displays the matching translation key).
class GatewayType {
  const GatewayType({required this.id, required this.name});

  final String id;
  final String name;

  factory GatewayType.fromMap(Map<String, dynamic> json) => GatewayType(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}
