/// Statics-bundle date format. The server returns a separate `format` (PHP)
/// and `format_dart` (Dart `DateFormat` pattern) — we use the Dart one.
class DatetimeFormat {
  const DatetimeFormat({required this.id, required this.format});

  final String id;
  final String format;

  factory DatetimeFormat.fromMap(Map<String, dynamic> json) => DatetimeFormat(
    id: json['id']?.toString() ?? '',
    format: json['format_dart']?.toString() ?? '',
  );
}
