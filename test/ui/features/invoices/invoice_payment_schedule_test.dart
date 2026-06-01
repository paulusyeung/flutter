import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/schedule_item_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/ui/features/invoices/widgets/detail/invoice_payment_schedule_tab.dart';

Invoice _inv(
  String statusId, {
  bool deleted = false,
  List<ScheduleItemApi>? schedule,
}) => Invoice.fromApi(
  InvoiceApi(
    id: 'inv1',
    statusId: statusId,
    isDeleted: deleted,
    schedule: schedule,
  ),
);

void main() {
  group('invoiceSupportsPaymentSchedule (React useTabs parity)', () {
    test('Draft / Sent → true regardless of permission', () {
      for (final s in ['1', '2']) {
        expect(
          invoiceSupportsPaymentSchedule(_inv(s), canViewOrEdit: false),
          isTrue,
        );
      }
    });

    test('Partial → only when canViewOrEdit', () {
      expect(
        invoiceSupportsPaymentSchedule(_inv('3'), canViewOrEdit: true),
        isTrue,
      );
      expect(
        invoiceSupportsPaymentSchedule(_inv('3'), canViewOrEdit: false),
        isFalse,
      );
    });

    test('Paid / Cancelled / Reversed / deleted → false', () {
      for (final s in ['4', '5', '6']) {
        expect(
          invoiceSupportsPaymentSchedule(_inv(s), canViewOrEdit: true),
          isFalse,
        );
      }
      expect(
        invoiceSupportsPaymentSchedule(
          _inv('1', deleted: true),
          canViewOrEdit: true,
        ),
        isFalse,
      );
    });
  });

  group('Invoice.schedule mapping', () {
    test('fromApi parses the embedded schedule[]; toApiJson omits it', () {
      final inv = _inv(
        '2',
        schedule: const [
          ScheduleItemApi(date: '2026-06-01', amount: '50.00', autoBill: true),
          ScheduleItemApi(date: '2026-07-01', amount: '50.00'),
        ],
      );
      expect(inv.schedule, hasLength(2));
      expect(inv.schedule.first.date, '2026-06-01');
      expect(inv.schedule.first.amount, '50.00');
      expect(inv.schedule.first.autoBill, isTrue);
      expect(inv.schedule[1].autoBill, isFalse);
      // Read-only: never sent on the outbound invoice wire.
      expect(inv.toApiJson().containsKey('schedule'), isFalse);
    });

    test('absent schedule key → empty list (not an error)', () {
      expect(_inv('1').schedule, isEmpty);
    });
  });
}
