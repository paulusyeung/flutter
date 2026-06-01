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
}) => Task.fromApi(
  TaskApi(
    id: id,
    description: description,
    number: number,
    rate: rate,
    timeLog: timeLog,
  ),
);

Expense _expense({
  String id = 'e1',
  String publicNotes = '',
  String number = '',
  String amount = '0',
  String taxName1 = '',
  Object taxRate1 = '0',
}) => Expense.fromApi(
  ExpenseApi(
    id: id,
    publicNotes: publicNotes,
    number: number,
    amount: amount,
    taxName1: taxName1,
    taxRate1: taxRate1,
  ),
);

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
}
