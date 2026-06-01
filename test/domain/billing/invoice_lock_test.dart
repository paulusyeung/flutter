import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/billing/invoice_lock.dart';

// status_id wire ids: 1 draft, 2 sent, 3 partial, 4 paid.
Invoice _inv(
  String statusId, {
  bool locked = false,
  String date = '2026-05-10',
}) => Invoice.fromApi(
  InvoiceApi(id: 'i1', statusId: statusId, date: date, isLocked: locked),
);

InvoiceLockReason _reason(
  Invoice i, {
  String? setting,
  bool veriFactu = false,
  Date? today,
}) => invoiceLockReason(
  invoice: i,
  lockInvoicesSetting: setting,
  veriFactuActive: veriFactu,
  today: today,
);

void main() {
  final today = Date(2026, 5, 18);

  group('off / null', () {
    test('never locks regardless of status', () {
      for (final s in ['1', '2', '3', '4']) {
        expect(_reason(_inv(s), setting: 'off'), InvoiceLockReason.none);
        expect(_reason(_inv(s), setting: null), InvoiceLockReason.none);
        expect(_reason(_inv(s), setting: ''), InvoiceLockReason.none);
      }
    });
  });

  group('when_sent', () {
    test('draft → none, sent/partial/paid → sent', () {
      expect(_reason(_inv('1'), setting: 'when_sent'), InvoiceLockReason.none);
      expect(_reason(_inv('2'), setting: 'when_sent'), InvoiceLockReason.sent);
      expect(_reason(_inv('3'), setting: 'when_sent'), InvoiceLockReason.sent);
      expect(_reason(_inv('4'), setting: 'when_sent'), InvoiceLockReason.sent);
    });
  });

  group('when_paid', () {
    test('only paid / partial lock', () {
      expect(_reason(_inv('1'), setting: 'when_paid'), InvoiceLockReason.none);
      expect(_reason(_inv('2'), setting: 'when_paid'), InvoiceLockReason.none);
      expect(_reason(_inv('3'), setting: 'when_paid'), InvoiceLockReason.paid);
      expect(_reason(_inv('4'), setting: 'when_paid'), InvoiceLockReason.paid);
    });
  });

  group('end_of_month', () {
    test('same month → none', () {
      expect(
        _reason(
          _inv('2', date: '2026-05-01'),
          setting: 'end_of_month',
          today: today,
        ),
        InvoiceLockReason.none,
      );
    });

    test('prior month / prior year → endOfMonth', () {
      expect(
        _reason(
          _inv('2', date: '2026-04-30'),
          setting: 'end_of_month',
          today: today,
        ),
        InvoiceLockReason.endOfMonth,
      );
      expect(
        _reason(
          _inv('2', date: '2025-05-30'),
          setting: 'end_of_month',
          today: today,
        ),
        InvoiceLockReason.endOfMonth,
      );
    });

    test('null/empty date → none', () {
      expect(
        _reason(
          _inv('2', date: ''),
          setting: 'end_of_month',
          today: today,
        ),
        InvoiceLockReason.none,
      );
    });
  });

  group('server flag wins', () {
    test('isLocked=true → server, even with setting off', () {
      expect(
        _reason(_inv('1', locked: true), setting: 'off'),
        InvoiceLockReason.server,
      );
    });
  });

  group('VeriFactu force', () {
    test('null/off setting + veriFactu → behaves as when_sent', () {
      expect(
        _reason(_inv('2'), setting: null, veriFactu: true),
        InvoiceLockReason.sent,
      );
      expect(
        _reason(_inv('1'), setting: 'off', veriFactu: true),
        InvoiceLockReason.none, // draft still editable
      );
    });

    test('explicit when_paid is not overridden by veriFactu', () {
      expect(
        _reason(_inv('2'), setting: 'when_paid', veriFactu: true),
        InvoiceLockReason.none,
      );
    });
  });

  group('isInvoiceLockedBy + message keys', () {
    test('boolean mirrors reason', () {
      expect(
        isInvoiceLockedBy(
          invoice: _inv('2'),
          lockInvoicesSetting: 'when_sent',
          veriFactuActive: false,
        ),
        isTrue,
      );
      expect(
        isInvoiceLockedBy(
          invoice: _inv('1'),
          lockInvoicesSetting: 'when_sent',
          veriFactuActive: false,
        ),
        isFalse,
      );
    });

    test('reason → localization key', () {
      expect(
        invoiceLockMessageKey(InvoiceLockReason.sent),
        'sent_invoices_are_locked',
      );
      expect(
        invoiceLockMessageKey(InvoiceLockReason.paid),
        'paid_invoices_are_locked',
      );
      expect(
        invoiceLockMessageKey(InvoiceLockReason.endOfMonth),
        'invoices_locked_end_of_month',
      );
      expect(invoiceLockMessageKey(InvoiceLockReason.server), 'invoice_locked');
      expect(invoiceLockMessageKey(InvoiceLockReason.none), 'invoice_locked');
    });
  });
}
