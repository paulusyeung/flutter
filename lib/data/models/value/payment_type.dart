/// Statics-bundle payment-type entry (Apple Pay, Bitcoin, Cash, Credit Card,
/// …). Wire shape matches `admin-portal/lib/data/models/static/payment_type_model.dart`.
class PaymentType {
  const PaymentType({required this.id, required this.name});

  final String id;
  final String name;

  factory PaymentType.fromMap(Map<String, dynamic> json) => PaymentType(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}
