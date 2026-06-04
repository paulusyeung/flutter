import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/domain/billing/line_item_type.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/ui/features/billing_shared/add_unbilled/unbilled_line_items.dart';

Task _task({
  String id = 't1',
  String description = '',
  String number = '',
  String rate = '0',
  String timeLog = '',
  String invoiceId = '',
}) => Task.fromApi(
  TaskApi(
    id: id,
    description: description,
    number: number,
    rate: rate,
    timeLog: timeLog,
    invoiceId: invoiceId,
  ),
);

Expense _expense({
  String id = 'e1',
  String publicNotes = '',
  String number = '',
  String amount = '0',
  String taxName1 = '',
  Object taxRate1 = '0',
  String invoiceId = '',
  bool shouldBeInvoiced = false,
}) => Expense.fromApi(
  ExpenseApi(
    id: id,
    publicNotes: publicNotes,
    number: number,
    amount: amount,
    taxName1: taxName1,
    taxRate1: taxRate1,
    invoiceId: invoiceId,
    shouldBeInvoiced: shouldBeInvoiced,
  ),
);

// A stopped, billable, 1-hour entry.
const _stopped1h = '[[1700000000,1700003600,"",true]]';
// A still-running entry (no stop) — billable.
const _running = '[[1700000000,0,"",true]]';

void main() {
  group('taskToLineItem', () {
    test('maps rate→cost, billable hours→quantity, type=task, taskId set', () {
      // 5400s = 1.5h billable.
      final li = taskToLineItem(
        _task(
          description: 'Design work',
          rate: '150',
          timeLog: '[[1700000000,1700005400,"",true]]',
        ),
      );
      expect(li.cost, Decimal.parse('150'));
      expect(li.quantity, Decimal.parse('1.5'));
      expect(li.notes, 'Design work');
      expect(li.typeId, LineItemType.task);
      expect(li.taskId, 't1');
      expect(li.expenseId, isNull);
    });

    test('no logged time falls back to quantity 1 (editable default)', () {
      final li = taskToLineItem(_task(rate: '90'));
      expect(li.quantity, Decimal.one);
    });

    test('non-billable entries are excluded from hours', () {
      final li = taskToLineItem(
        _task(timeLog: '[[1700000000,1700003600,"",false]]'),
      );
      expect(li.quantity, Decimal.one); // 0 billable → fallback 1
    });

    test('description falls back to #number then empty', () {
      expect(taskToLineItem(_task(number: '7')).notes, '#7');
      expect(taskToLineItem(_task()).notes, '');
    });
  });

  group('expenseToLineItem', () {
    test('maps amount→cost, qty 1, tax pass-through, expenseId set', () {
      final li = expenseToLineItem(
        _expense(
          publicNotes: 'Flights',
          amount: '420.50',
          taxName1: 'VAT',
          taxRate1: '20',
        ),
      );
      expect(li.cost, Decimal.parse('420.50'));
      expect(li.quantity, Decimal.one);
      expect(li.notes, 'Flights');
      expect(li.taxName1, 'VAT');
      expect(li.taxRate1, Decimal.parse('20'));
      expect(li.expenseId, 'e1');
      expect(li.taskId, isNull);
      expect(li.typeId, LineItemType.standard);
    });

    test('notes fall back to #number then empty', () {
      expect(expenseToLineItem(_expense(number: '99')).notes, '#99');
      expect(expenseToLineItem(_expense()).notes, '');
    });
  });

  group('taskBillableHours', () {
    test('rounds to 3 decimals', () {
      // 3661s ≈ 1.0169h → 1.017
      final h = taskBillableHours(
        _task(timeLog: '[[1700000000,1700003661,"",true]]'),
      );
      expect(h, Decimal.parse('1.017'));
    });
  });

  group('projectInvoiceLineItems', () {
    test('includes pending expenses first, then stopped+uninvoiced tasks', () {
      final items = projectInvoiceLineItems(
        tasks: [
          _task(id: 't_ok', rate: '100', timeLog: _stopped1h), // ✓ include
          _task(
            id: 't_inv',
            rate: '100',
            timeLog: _stopped1h,
            invoiceId: 'i1',
          ), // invoiced
          _task(id: 't_run', rate: '100', timeLog: _running), // running
          _task(id: 't_zero', rate: '100'), // no logged time
          _task(id: 'tmp_t', rate: '100', timeLog: _stopped1h), // unsynced
        ],
        expenses: [
          _expense(
            id: 'e_ok',
            amount: '50',
            shouldBeInvoiced: true,
          ), // ✓ include
          _expense(
            id: 'e_inv',
            amount: '50',
            shouldBeInvoiced: true,
            invoiceId: 'i2',
          ), // invoiced
          _expense(id: 'e_nb', amount: '50'), // not should_be_invoiced
          _expense(
            id: 'tmp_e',
            amount: '50',
            shouldBeInvoiced: true,
          ), // unsynced
        ],
      );

      expect(items.length, 2);
      // Expenses come first (mirrors admin-portal ordering), then tasks.
      expect(items[0].expenseId, 'e_ok');
      expect(items[1].taskId, 't_ok');
    });

    test('returns empty when nothing is billable', () {
      final items = projectInvoiceLineItems(
        tasks: [
          _task(id: 't_run', timeLog: _running),
          _task(id: 't_zero'),
        ],
        expenses: [_expense(id: 'e_nb')],
      );
      expect(items, isEmpty);
    });
  });
}
