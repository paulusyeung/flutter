/// Statics-bundle company size band (e.g. "1 - 3", "4 - 10").
/// Wire shape matches `admin-portal/lib/data/models/static/size_model.dart`.
class Size {
  const Size({required this.id, required this.name});

  final String id;
  final String name;

  factory Size.fromMap(Map<String, dynamic> json) => Size(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );
}
