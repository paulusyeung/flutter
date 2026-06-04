import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/recurring_invoice_api_model.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/data/models/domain/recurring_invoice_status.dart';

/// Builds a domain RecurringInvoice through the real `fromApi` parse path so
/// the `lastSentDate` datetime parsing is exercised (the status logic depends
/// on it — see `value/date.dart`).
RecurringInvoice ri({
  String statusId = '2', // active
  String lastSentDate = '',
  int remainingCycles = -1,
}) => RecurringInvoice.fromApi(
  RecurringInvoiceApi(
    statusId: statusId,
    lastSentDate: lastSentDate,
    remainingCycles: remainingCycles,
  ),
);

void main() {
  group('RecurringInvoice.isPending / calculatedStatusId', () {
    test('active + never sent => pending', () {
      final r = ri(statusId: '2', lastSentDate: '');
      expect(r.isPending, isTrue);
      expect(r.calculatedStatusId, RecurringInvoiceStatusComputed.pending);
    });

    test('active + already sent (datetime) => active, not pending', () {
      // Guards the Date.tryParse dependency: a datetime last_sent_date must
      // parse to a non-null Date so the record reads as active, not pending.
      final r = ri(statusId: '2', lastSentDate: '2026-05-04 04:00:17');
      expect(r.lastSentDate, isNotNull);
      expect(r.isPending, isFalse);
      expect(r.calculatedStatusId, RecurringInvoiceStatus.active.wireId);
    });

    test('non-draft + 0 remaining cycles => completed (takes precedence)', () {
      final r = ri(statusId: '2', lastSentDate: '', remainingCycles: 0);
      expect(r.calculatedStatusId, RecurringInvoiceStatus.completed.wireId);
    });

    test('draft + 0 cycles stays draft (completed rule needs non-draft)', () {
      final r = ri(statusId: '1', remainingCycles: 0);
      expect(r.calculatedStatusId, RecurringInvoiceStatus.draft.wireId);
      expect(r.isPending, isFalse);
    });

    test('paused => paused, not pending', () {
      final r = ri(statusId: '3');
      expect(r.isPending, isFalse);
      expect(r.calculatedStatusId, RecurringInvoiceStatus.paused.wireId);
    });
  });
}
