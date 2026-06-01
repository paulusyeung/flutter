import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Smoke test for the Client Portal field-binding registrations.
/// `Overridable*.bind(apiKey: ...)` calls go through `settingsBindingOf(apiKey)`,
/// which throws `StateError` on a missing entry; asserting each key exists
/// here catches typos at CI time instead of at the first frame of the screen.
void main() {
  group('client portal settings bindings', () {
    const apiKeys = <String>[
      // Settings tab — Portal Features / Uploads & Approvals
      'enable_client_portal',
      'enable_client_portal_dashboard',
      'show_pdfhtml_on_mobile',
      'preference_product_notes_for_html_view',
      'enable_client_profile_update',
      'client_portal_enable_uploads',
      'vendor_portal_enable_uploads',
      'accept_client_input_quote_approval',
      // Settings tab — Legal
      'client_portal_terms',
      'client_portal_privacy_policy',
      // Authorization tab
      'enable_client_portal_password',
      'show_accept_invoice_terms',
      'show_accept_quote_terms',
      'require_invoice_signature',
      'require_quote_signature',
      'require_purchase_order_signature',
      'signature_on_pdf',
      // Registration tab
      'client_can_register',
      // Messages tab
      'custom_message_dashboard',
      'custom_message_unpaid_invoice',
      'custom_message_paid_invoice',
      'custom_message_unapproved_quote',
      // Customize tab
      'portal_custom_head',
      'portal_custom_footer',
      'portal_custom_css',
      'portal_custom_js',
    ];

    test('every Client Portal apiKey resolves to a binding', () {
      for (final key in apiKeys) {
        expect(
          () => settingsBindingOf(key),
          returnsNormally,
          reason:
              'missing binding for $key — '
              'add it to settings_field_bindings.dart',
        );
      }
    });

    test('bool bindings round-trip true/false/null', () {
      const settings = CompanySettings();
      const boolKeys = <String>[
        'enable_client_portal',
        'enable_client_portal_dashboard',
        'enable_client_portal_password',
        'enable_client_profile_update',
        'client_portal_enable_uploads',
        'vendor_portal_enable_uploads',
        'accept_client_input_quote_approval',
        'show_pdfhtml_on_mobile',
        'preference_product_notes_for_html_view',
        'show_accept_invoice_terms',
        'show_accept_quote_terms',
        'require_invoice_signature',
        'require_quote_signature',
        'require_purchase_order_signature',
        'signature_on_pdf',
        'client_can_register',
      ];
      for (final key in boolKeys) {
        final b = settingsBindingOf(key);
        final on = b.write(settings, 'true');
        expect(b.read(on), 'true', reason: '$key did not store true');
        final off = b.write(on, 'false');
        expect(b.read(off), 'false', reason: '$key did not store false');
        final cleared = b.write(off, null);
        expect(b.read(cleared), isNull, reason: '$key did not clear');
      }
    });

    test('string bindings round-trip a non-null value', () {
      const settings = CompanySettings();
      const stringKeys = <String>[
        'client_portal_terms',
        'client_portal_privacy_policy',
        'custom_message_dashboard',
        'custom_message_unpaid_invoice',
        'custom_message_paid_invoice',
        'custom_message_unapproved_quote',
        'portal_custom_head',
        'portal_custom_footer',
        'portal_custom_css',
        'portal_custom_js',
      ];
      for (final key in stringKeys) {
        final b = settingsBindingOf(key);
        final next = b.write(settings, 'foo');
        expect(b.read(next), 'foo', reason: 'binding "$key" lost the value');
        final cleared = b.write(next, null);
        expect(b.read(cleared), isNull, reason: 'binding "$key" lost null');
      }
    });
  });
}
