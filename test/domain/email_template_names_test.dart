import 'package:admin/domain/email_template_names.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the single source of truth for email-template → `CompanySettings`
/// wire keys. The `quote_reminder1` exception is the one that caused a
/// launch-blocking quote-email send bug (the send path used to hand-roll the
/// prefix and miss it). Keep `emailTemplateWireName` / `emailSubjectWireName`
/// the only producers of these strings.
void main() {
  group('emailTemplateWireName', () {
    test('regular ids get the email_template_ prefix', () {
      expect(emailTemplateWireName('invoice'), 'email_template_invoice');
      expect(emailTemplateWireName('quote'), 'email_template_quote');
      expect(emailTemplateWireName('reminder1'), 'email_template_reminder1');
      expect(emailTemplateWireName('custom2'), 'email_template_custom2');
    });

    test('quote_reminder1 uses the irregular `quote_` infix key', () {
      // Server property is email_quote_template_reminder1, NOT the symmetric
      // email_template_quote_reminder1 (which 422s — not a settings property).
      expect(
        emailTemplateWireName('quote_reminder1'),
        'email_quote_template_reminder1',
      );
    });
  });

  group('emailSubjectWireName', () {
    test('regular ids get the email_subject_ prefix', () {
      expect(emailSubjectWireName('invoice'), 'email_subject_invoice');
      expect(emailSubjectWireName('custom2'), 'email_subject_custom2');
    });

    test('quote_reminder1 uses the irregular `quote_` infix key', () {
      expect(
        emailSubjectWireName('quote_reminder1'),
        'email_quote_subject_reminder1',
      );
    });
  });
}
