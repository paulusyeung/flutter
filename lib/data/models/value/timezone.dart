/// Statics-bundle timezone. Wire shape matches
/// `admin-portal/lib/data/models/static/timezone_model.dart` — the server ships
/// `id`, `name` (IANA tzdb identifier, e.g. `Europe/London`) and `location`
/// (the human-readable city/region, e.g. `London`).
class Timezone {
  const Timezone({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;
  final String location;

  factory Timezone.fromMap(Map<String, dynamic> json) => Timezone(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
  );
}
