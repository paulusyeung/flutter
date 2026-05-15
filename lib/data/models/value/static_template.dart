/// Server-provided default subject + body for one email template type.
/// Delivered via `/api/v1/statics`'s `templates` map, keyed by template
/// type (`invoice`, `quote`, `reminder1`, …). Used by Settings →
/// Templates & Reminders to render placeholder hints showing what the
/// factory default would be when no override is set.
class StaticTemplate {
  const StaticTemplate({required this.subject, required this.body});

  final String subject;
  final String body;

  factory StaticTemplate.fromMap(Map<String, dynamic> json) {
    return StaticTemplate(
      subject: (json['subject'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
    );
  }
}
