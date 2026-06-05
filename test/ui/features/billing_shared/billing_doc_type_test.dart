import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';

/// Guards the per-type capability flags the shared billing widgets branch on.
void main() {
  group('BillingDocType.supportsScheduledSend', () {
    test('recurring invoices cannot be scheduled (server task_scheduler '
        'rejects them) — so the email composer hides its Schedule action', () {
      expect(BillingDocType.recurringInvoice.supportsScheduledSend, isFalse);
    });

    test('every other billing doc supports a scheduled send', () {
      for (final t in BillingDocType.values) {
        if (t == BillingDocType.recurringInvoice) continue;
        expect(
          t.supportsScheduledSend,
          isTrue,
          reason: '$t should support scheduled send',
        );
      }
    });
  });

  group('BillingDocType.supportsDeliveryNote', () {
    test('invoice-only', () {
      for (final t in BillingDocType.values) {
        expect(t.supportsDeliveryNote, t == BillingDocType.invoice);
      }
    });
  });
}
