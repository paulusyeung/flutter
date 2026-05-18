import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/billing/line_item_type.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/task.dart';

/// Pure task/expense → [LineItem] conversion for the "Add unbilled items"
/// sheet. Kept free of widgets so it's unit-testable; mirrors admin-portal's
/// `convertTaskToInvoiceItem` / `convertExpenseToInvoiceItem` semantics.

/// Billable time-log hours, 3-decimal `Decimal`. Falls back to `1` when the
/// task has no logged time so the appended row is a sane editable default
/// rather than a zero-quantity ghost.
Decimal taskBillableHours(Task task, {DateTime? now}) {
  final seconds = task.totalDuration(now).inSeconds;
  if (seconds <= 0) return Decimal.one;
  return Decimal.parse((seconds / 3600).toStringAsFixed(3));
}

LineItem taskToLineItem(Task task, {DateTime? now}) {
  final notes = task.description.trim().isNotEmpty
      ? task.description.trim()
      : (task.number.isNotEmpty ? '#${task.number}' : '');
  return emptyLineItem().copyWith(
    notes: notes,
    cost: task.rate,
    quantity: taskBillableHours(task, now: now),
    typeId: LineItemType.task,
    taskId: task.id,
  );
}

LineItem expenseToLineItem(Expense expense) {
  final notes = expense.publicNotes.trim().isNotEmpty
      ? expense.publicNotes.trim()
      : (expense.number.isNotEmpty ? '#${expense.number}' : '');
  return emptyLineItem().copyWith(
    notes: notes,
    cost: expense.amount,
    quantity: Decimal.one,
    taxName1: expense.taxName1,
    taxRate1: expense.taxRate1,
    taxName2: expense.taxName2,
    taxRate2: expense.taxRate2,
    taxName3: expense.taxName3,
    taxRate3: expense.taxRate3,
    expenseId: expense.id,
  );
}
