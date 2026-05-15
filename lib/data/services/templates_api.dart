import 'package:admin/data/services/api_client.dart';

/// Renders an email template against a sample entity, returning the
/// server-substituted subject, body, and full HTML wrapper used by the
/// preview panel on Settings → Templates & Reminders.
///
/// The `/api/v1/templates` endpoint takes a subject + body string and a
/// template type, runs it through the server-side variable substitution
/// engine (`$client`, `$amount`, `$due_date`, …), and returns the rendered
/// HTML. We POST with empty `entity` / `entity_id` so the server picks a
/// generic sample — there's no need to ship a real invoice id from the
/// client, and React does the same (TemplatesAndReminders.tsx:323).
///
/// `readOnly: true` on the POST bypasses the demo-mode short-circuit; this
/// endpoint mutates nothing.
class TemplatesApi {
  TemplatesApi(this._client);

  final ApiClient _client;

  /// [template] is the bare template id (`'invoice'`, `'quote_reminder1'`,
  /// `'custom2'`, …). This function transforms it to the wire name the
  /// server expects (`'email_template_invoice'`, `'email_quote_template_
  /// reminder1'`, …) before POSTing — mirrors v1 (`admin-portal/lib/utils/
  /// templates.dart:44-51`).
  ///
  /// The returned [TemplatePreview.wrapper] has the body substituted in
  /// for the `$body` placeholder that the server emits in the wrapper
  /// template, so callers can pass it straight to a WebView without an
  /// extra splice step (v1 + React both do
  /// `wrapper.replace('$body', body)` at the call site; we centralize it
  /// here).
  Future<TemplatePreview> render({
    required String template,
    required String subject,
    required String body,
  }) async {
    final wireTemplate = _toWireName(template);
    final response = await _client.postJson(
      '/api/v1/templates',
      readOnly: true,
      body: <String, dynamic>{
        'entity': '',
        'entity_id': '',
        'template': wireTemplate,
        'subject': subject,
        'body': body,
      },
    );
    final json = response is Map<String, dynamic>
        ? response
        : const <String, dynamic>{};
    final rawWrapper = (json['wrapper'] as String?) ?? '';
    final renderedBody = (json['body'] as String?) ?? '';
    return TemplatePreview(
      subject: (json['subject'] as String?) ?? '',
      body: renderedBody,
      wrapper: rawWrapper.replaceFirst(r'$body', renderedBody),
      rawSubject: (json['raw_subject'] as String?) ?? '',
      rawBody: (json['raw_body'] as String?) ?? '',
    );
  }

  /// Map a bare template id to its server wire name. Special-cased for
  /// `quote_reminder1`, which uses the `email_quote_(subject|template)_
  /// reminder1` form (verified against `admin-portal/lib/data/models/
  /// settings_model.dart:848,851`).
  static String _toWireName(String template) {
    if (template == 'quote_reminder1') return 'email_quote_template_reminder1';
    return 'email_template_$template';
  }
}

class TemplatePreview {
  const TemplatePreview({
    required this.subject,
    required this.body,
    required this.wrapper,
    required this.rawSubject,
    required this.rawBody,
  });

  /// Subject line with variables substituted.
  final String subject;

  /// Rendered body HTML (no `<html>` wrapper).
  final String body;

  /// Full HTML document — `<html>` + `<style>` + body — suitable for
  /// `WebViewController.loadHtmlString`. Already has [body] substituted
  /// in for the server-side `$body` placeholder.
  final String wrapper;

  /// Original subject string echoed back (matches the request).
  final String rawSubject;

  /// Original body string echoed back.
  final String rawBody;
}
