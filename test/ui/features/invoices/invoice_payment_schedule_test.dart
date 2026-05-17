import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/schedule_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/schedule.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/ui/features/invoices/widgets/detail/invoice_payment_schedule_tab.dart';

Invoice _inv(String statusId, {bool deleted = false}) => Invoice.fromApi(
  InvoiceApi(id: 'inv1', statusId: statusId, isDeleted: deleted),
);

Schedule _sched({
  String id = 's1',
  String template = kScheduleTemplatePaymentSchedule,
  String invoiceId = 'inv1',
  bool deleted = false,
}) =>
    Schedule.fromApi(
      ScheduleApi(
        id: id,
        template: template,
        isDeleted: deleted,
        parameters: {'invoice_id': invoiceId, 'auto_bill': true},
      ),
    );

void main() {
  group('invoiceSupportsPaymentSchedule', () {
    test('Draft / Sent / Partial → true', () {
      expect(invoiceSupportsPaymentSchedule(_inv('1')), isTrue); // draft
      expect(invoiceSupportsPaymentSchedule(_inv('2')), isTrue); // sent
      expect(invoiceSupportsPaymentSchedule(_inv('3')), isTrue); // partial
    });

    test('Paid / Cancelled / Reversed / deleted → false', () {
      expect(invoiceSupportsPaymentSchedule(_inv('4')), isFalse); // paid
      expect(invoiceSupportsPaymentSchedule(_inv('5')), isFalse); // cancelled
      expect(invoiceSupportsPaymentSchedule(_inv('6')), isFalse); // reversed
      expect(
        invoiceSupportsPaymentSchedule(_inv('1', deleted: true)),
        isFalse,
      );
    });
  });

  group('paymentScheduleForInvoice', () {
    test('finds the payment_schedule bound to the invoice', () {
      final s = _sched();
      expect(paymentScheduleForInvoice([s], 'inv1'), same(s));
    });

    test('ignores wrong template, wrong invoice, and deleted', () {
      expect(
        paymentScheduleForInvoice(
          [_sched(template: kScheduleTemplateEmailStatement)],
          'inv1',
        ),
        isNull,
      );
      expect(
        paymentScheduleForInvoice([_sched(invoiceId: 'other')], 'inv1'),
        isNull,
      );
      expect(
        paymentScheduleForInvoice([_sched(deleted: true)], 'inv1'),
        isNull,
      );
      expect(paymentScheduleForInvoice(const [], 'inv1'), isNull);
    });

    test('picks the matching one among several schedules', () {
      final match = _sched(id: 'ps');
      final all = [
        _sched(id: 'x', template: kScheduleTemplateEmailStatement),
        _sched(id: 'y', invoiceId: 'other'),
        match,
      ];
      expect(paymentScheduleForInvoice(all, 'inv1'), same(match));
    });
  });
}
