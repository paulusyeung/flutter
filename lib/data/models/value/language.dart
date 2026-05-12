/// Statics-bundle language (UI / portal language, not country-locale).
/// Wire shape matches `admin-portal/lib/data/models/static/language_model.dart`.
class Language {
  const Language({required this.id, required this.name, required this.locale});

  final String id;
  final String name;

  /// IETF locale (`en`, `fr_CA`). Useful for matching against device
  /// locale; the filter UI only uses `name` for display.
  final String locale;

  factory Language.fromMap(Map<String, dynamic> json) => Language(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    locale: json['locale']?.toString() ?? '',
  );
}
