import 'package:admin/data/models/domain/billing/line_item.dart';

/// Output of [showLineItemPickerSheet]. `lineItems` is the converted batch the
/// caller should append; `projectIdHint` is the first non-empty `projectId`
/// across the picked tasks (empty when no task with a project was selected) —
/// the caller can adopt it when the draft has no project yet.
///
/// `clientIdHint` is the analogous "first non-empty `clientId` across picked
/// tasks/expenses" — used by the invoke helper to auto-set the draft's
/// client on a client-less doc when the user picks the first task/expense
/// (mirrors admin-portal's `invoice_edit_vm.dart:204-212` cascade).
///
/// `pickedTaskClientIds` / `pickedExpenseClientIds` carry the picked rows'
/// source clientIds (taskId/expenseId → clientId, non-blank only) so the
/// host VM can pre-cache them for the cross-client save validator instead
/// of re-fetching each task/expense from Drift.
class LineItemPickerResult {
  const LineItemPickerResult({
    required this.lineItems,
    this.projectIdHint = '',
    this.clientIdHint = '',
    this.pickedTaskClientIds = const {},
    this.pickedExpenseClientIds = const {},
  });

  final List<LineItem> lineItems;
  final String projectIdHint;
  final String clientIdHint;
  final Map<String, String> pickedTaskClientIds;
  final Map<String, String> pickedExpenseClientIds;
}
