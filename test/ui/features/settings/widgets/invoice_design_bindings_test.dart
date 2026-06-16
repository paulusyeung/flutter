import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Smoke test for the Invoice Design field-binding registrations. The page's
/// `Overridable*.bind(apiKey: ...)` calls go through
/// `settingsBindingOf(apiKey)`, which throws `StateError` on a missing entry;
/// asserting each key exists here catches typos at CI time instead of at the
/// first frame of the screen.
void main() {
  group('invoice design settings bindings', () {
    const apiKeys = <String>[
      // Design ids
      'invoice_design_id',
      'quote_design_id',
      'credit_design_id',
      'purchase_order_design_id',
      'delivery_note_design_id',
      'statement_design_id',
      'payment_receipt_design_id',
      'payment_refund_design_id',
      // Layout / typography
      'page_size',
      'page_layout',
      'font_size',
      'company_logo_size',
      'primary_font',
      'secondary_font',
      'primary_color',
      'secondary_color',
      // Display / pagination
      'show_paid_stamp',
      'show_shipping_address',
      'embed_documents',
      'hide_empty_columns_on_pdf',
      'page_numbering',
      'page_numbering_alignment',
      'sync_invoice_quote_columns',
    ];

    test('every Invoice Design apiKey resolves to a binding', () {
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

    test('string bindings round-trip a non-null value', () {
      const settings = CompanySettings();
      for (final key in const <String>[
        'invoice_design_id',
        'primary_color',
        'primary_font',
        'page_size',
        'page_layout',
        'page_numbering_alignment',
        'company_logo_size',
      ]) {
        final b = settingsBindingOf(key);
        final next = b.write(settings, 'foo');
        expect(b.read(next), 'foo', reason: 'binding "$key" lost the value');
        final cleared = b.write(next, null);
        expect(b.read(cleared), isNull, reason: 'binding "$key" lost null');
      }
    });

    test(
      'int binding (font_size) round-trips through string serialization',
      () {
        const settings = CompanySettings();
        final b = settingsBindingOf('font_size');
        final next = b.write(settings, '14');
        expect(b.read(next), '14');
        final cleared = b.write(next, null);
        expect(b.read(cleared), isNull);
      },
    );

    test('bool bindings round-trip true/false/null', () {
      const settings = CompanySettings();
      for (final key in const <String>[
        'show_paid_stamp',
        'embed_documents',
        'hide_empty_columns_on_pdf',
        'page_numbering',
        'sync_invoice_quote_columns',
      ]) {
        final b = settingsBindingOf(key);
        final on = b.write(settings, 'true');
        expect(b.read(on), 'true', reason: '$key did not store true');
        final off = b.write(on, 'false');
        expect(b.read(off), 'false', reason: '$key did not store false');
        final cleared = b.write(off, null);
        expect(b.read(cleared), isNull, reason: '$key did not clear');
      }
    });
  });

  group('reminder-days clear sentinel (M3)', () {
    test(
      'an empty clear maps to 0 (server unset), not null — so a company '
      'scope clear is not omitted by includeIfNull toJson and resurrected',
      () {
        const settings = CompanySettings();
        for (final key in const <String>[
          'num_days_reminder1',
          'num_days_reminder2',
          'num_days_reminder3',
          'quote_num_days_reminder1',
        ]) {
          final b = settingsBindingOf(key);
          final seeded = b.write(settings, '5');
          expect(b.read(seeded), '5', reason: '$key lost its value');
          final cleared = b.write(seeded, '');
          expect(
            b.read(cleared),
            '0',
            reason: '$key must clear to 0, not null (would resurrect on save)',
          );
        }
      },
    );
  });
}
