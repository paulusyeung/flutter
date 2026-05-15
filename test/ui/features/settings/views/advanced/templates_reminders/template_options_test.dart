import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/template_options.dart';

void main() {
  group('TemplateOption.subjectKey / templateKey', () {
    test('non-quote templates use the symmetric form', () {
      final invoice =
          kTemplateOptions.firstWhere((o) => o.key == 'invoice');
      expect(invoice.subjectKey, 'email_subject_invoice');
      expect(invoice.templateKey, 'email_template_invoice');

      final r1 = kTemplateOptions.firstWhere((o) => o.key == 'reminder1');
      expect(r1.subjectKey, 'email_subject_reminder1');
      expect(r1.templateKey, 'email_template_reminder1');

      final custom = kTemplateOptions.firstWhere((o) => o.key == 'custom2');
      expect(custom.subjectKey, 'email_subject_custom2');
      expect(custom.templateKey, 'email_template_custom2');
    });

    test('quote_reminder1 swaps to the `email_quote_*` form', () {
      // Wire names per admin-portal settings_model.dart:848-851 — the
      // server expects `email_quote_subject_reminder1`, not the symmetric
      // `email_subject_quote_reminder1`. A regression here silently drops
      // saves on the quote reminder template.
      final qr1 =
          kTemplateOptions.firstWhere((o) => o.key == 'quote_reminder1');
      expect(qr1.subjectKey, 'email_quote_subject_reminder1');
      expect(qr1.templateKey, 'email_quote_template_reminder1');
    });
  });

  group('TemplateOption.isReminder', () {
    test('flags only the five reminder kinds', () {
      final reminders =
          kTemplateOptions.where((o) => o.isReminder).map((o) => o.key).toSet();
      expect(reminders, {
        'reminder1',
        'reminder2',
        'reminder3',
        'reminder_endless',
        'quote_reminder1',
      });
    });

    test('invoice / quote / credit / payment etc. are NOT reminders', () {
      for (final key in [
        'invoice',
        'quote',
        'credit',
        'payment',
        'payment_partial',
        'payment_failed',
        'statement',
        'purchase_order',
        'custom1',
        'custom2',
        'custom3',
      ]) {
        final opt = kTemplateOptions.firstWhere((o) => o.key == key);
        expect(opt.isReminder, isFalse, reason: '$key should not be a reminder');
      }
    });
  });

  group('visibleTemplateOptions module gating', () {
    test('all modules enabled → all 16 templates visible', () {
      final mask = EnabledModule.invoices.bitmask |
          EnabledModule.quotes.bitmask |
          EnabledModule.credits.bitmask |
          EnabledModule.purchaseOrders.bitmask;
      expect(visibleTemplateOptions(mask).length, kTemplateOptions.length);
    });

    test('quotes module off → quote + quote_reminder1 hidden', () {
      final mask = EnabledModule.invoices.bitmask |
          EnabledModule.credits.bitmask |
          EnabledModule.purchaseOrders.bitmask;
      final keys = visibleTemplateOptions(mask).map((o) => o.key).toSet();
      expect(keys, isNot(contains('quote')));
      expect(keys, isNot(contains('quote_reminder1')));
      expect(keys, contains('credit'));
      expect(keys, contains('purchase_order'));
    });

    test('credits module off → only credit hidden', () {
      final mask = EnabledModule.invoices.bitmask |
          EnabledModule.quotes.bitmask |
          EnabledModule.purchaseOrders.bitmask;
      final keys = visibleTemplateOptions(mask).map((o) => o.key).toSet();
      expect(keys, isNot(contains('credit')));
      expect(keys, contains('quote'));
      expect(keys, contains('purchase_order'));
    });

    test('purchase orders module off → only purchase_order hidden', () {
      final mask = EnabledModule.quotes.bitmask | EnabledModule.credits.bitmask;
      final keys = visibleTemplateOptions(mask).map((o) => o.key).toSet();
      expect(keys, isNot(contains('purchase_order')));
      expect(keys, contains('quote'));
      expect(keys, contains('credit'));
    });

    test('mask = 0 → no module-gated templates visible, but invoice + '
        'payments + reminders still surface', () {
      final keys = visibleTemplateOptions(0).map((o) => o.key).toSet();
      expect(keys, isNot(contains('quote')));
      expect(keys, isNot(contains('quote_reminder1')));
      expect(keys, isNot(contains('credit')));
      expect(keys, isNot(contains('purchase_order')));
      // The invoice/payment/reminder/custom templates have no module gate,
      // so they remain regardless of the bitmask.
      expect(keys, contains('invoice'));
      expect(keys, contains('payment'));
      expect(keys, contains('payment_partial'));
      expect(keys, contains('payment_failed'));
      expect(keys, contains('statement'));
      expect(keys, contains('reminder1'));
      expect(keys, contains('reminder2'));
      expect(keys, contains('reminder3'));
      expect(keys, contains('reminder_endless'));
      expect(keys, contains('custom1'));
    });
  });

  group('kEndlessReminderFrequencies', () {
    test('has 12 entries with no "never" (0) sentinel', () {
      expect(kEndlessReminderFrequencies.length, 12);
      // The reset_counter dropdown on Generated Numbers prepends a '0' →
      // 'never' entry for the disabled state. Endless reminder has a
      // separate enable bool, so the frequency dropdown must not carry a
      // never sentinel — otherwise saving '0' would write a value the
      // server doesn't expect.
      expect(
        kEndlessReminderFrequencies.map((e) => e.$1).toSet(),
        isNot(contains('0')),
      );
      // First entry is daily, last is three years (matches v1's
      // kFrequencies map).
      expect(kEndlessReminderFrequencies.first.$1, '1');
      expect(kEndlessReminderFrequencies.first.$2, 'freq_daily');
      expect(kEndlessReminderFrequencies.last.$1, '12');
      expect(kEndlessReminderFrequencies.last.$2, 'freq_three_years');
    });
  });
}
