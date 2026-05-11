/// Statics-bundle industry classification.
/// Wire shape matches `admin-portal/lib/data/models/static/industry_model.dart`.
class Industry {
  const Industry({required this.id, required this.name});

  final String id;
  final String name;

  factory Industry.fromMap(Map<String, dynamic> json) => Industry(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}
