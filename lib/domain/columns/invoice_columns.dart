import 'package:go_router/go_router.dart';

import 'package:admin/data/db/dao/invoice_dao.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_status_pill.dart';

typedef InvoiceColumn = ColumnDefinition<Invoice>;

/// Default visible columns for the Invoice list. Mirrors the React admin
/// client's default column registry: status, number, client, amount,
/// balance, date, due_date.
const List<String> kDefaultInvoiceColumns = <String>[
  InvoiceFieldIds.status,
  InvoiceFieldIds.number,
  InvoiceFieldIds.clientId,
  InvoiceFieldIds.amount,
  InvoiceFieldIds.balance,
  InvoiceFieldIds.date,
  InvoiceFieldIds.dueDate,
];

final List<InvoiceColumn> kAllInvoiceColumns = <InvoiceColumn>[
  // Display-only column. `calculatedStatusId` is a domain getter, not a
  // denormalized Drift column — adding it to the list screen's
  // `sortOptions` would make `InvoiceDao._sortExpression` throw.
  InvoiceColumn(
    id: InvoiceFieldIds.status,
    labelKey: 'status',
    width: 110,
    cellBuilder: (i, _) =>
        InvoiceStatusPill(statusId: i.calculatedStatusId),
    valueBuilder: (i) => i.calculatedStatusId,
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.number,
    labelKey: 'number',
    width: 130,
    cellBuilder: (i, ctx) => cellLink(
      ctx,
      i.number,
      bold: true,
      onTap: () => ctx.go('/invoices/${i.id}/edit'),
    ),
    valueBuilder: (i) => cellNonZeroString(i.number),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.clientId,
    labelKey: 'client',
    width: 200,
    cellBuilder: (i, _) =>
        i.clientId.isEmpty ? cellEmpty() : cellText(i.clientId),
    valueBuilder: (i) => cellNonZeroString(i.clientId),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.date,
    labelKey: 'invoice_date',
    width: 120,
    cellBuilder: (i, ctx) =>
        i.date == null ? cellEmpty() : cellDate(i.date!.toDateTime(), ctx),
    valueBuilder: (i) => i.date?.toIso(),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.dueDate,
    labelKey: 'due_date',
    width: 120,
    cellBuilder: (i, ctx) => i.dueDate == null
        ? cellEmpty()
        : cellDate(i.dueDate!.toDateTime(), ctx),
    valueBuilder: (i) => i.dueDate?.toIso(),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.amount,
    labelKey: 'amount',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (i, _) => cellMoney(i.amount),
    valueBuilder: (i) => cellMoneyValue(i.amount),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.balance,
    labelKey: 'balance',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (i, _) => cellMoney(i.balance),
    valueBuilder: (i) => cellMoneyValue(i.balance),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.paidToDate,
    labelKey: 'paid_to_date',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (i, _) => cellMoney(i.paidToDate),
    valueBuilder: (i) => cellMoneyValue(i.paidToDate),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.partial,
    labelKey: 'partial',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (i, _) => cellMoney(i.partial),
    valueBuilder: (i) => cellMoneyValue(i.partial),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.partialDueDate,
    labelKey: 'partial_due_date',
    width: 130,
    cellBuilder: (i, ctx) => i.partialDueDate == null
        ? cellEmpty()
        : cellDate(i.partialDueDate!.toDateTime(), ctx),
    valueBuilder: (i) => i.partialDueDate?.toIso(),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.poNumber,
    labelKey: 'po_number',
    width: 130,
    cellBuilder: (i, _) =>
        i.poNumber.isEmpty ? cellEmpty() : cellText(i.poNumber),
    valueBuilder: (i) => cellNonZeroString(i.poNumber),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.designId,
    labelKey: 'design',
    width: 130,
    cellBuilder: (i, _) =>
        i.designId.isEmpty ? cellEmpty() : cellText(i.designId),
    valueBuilder: (i) => cellNonZeroString(i.designId),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.projectId,
    labelKey: 'project',
    width: 160,
    cellBuilder: (i, _) =>
        i.projectId.isEmpty ? cellEmpty() : cellText(i.projectId),
    valueBuilder: (i) => cellNonZeroString(i.projectId),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.assignedUserId,
    labelKey: 'assigned_user',
    width: 160,
    cellBuilder: (i, _) =>
        i.assignedUserId.isEmpty ? cellEmpty() : cellText(i.assignedUserId),
    valueBuilder: (i) => cellNonZeroString(i.assignedUserId),
  ),
  // Display-only — `public_notes` lives only in the payload JSON; adding it
  // to the screen's `sortOptions` would make `InvoiceDao._sortExpression`
  // throw. Lift into `invoices_table.dart` first if sorting is needed.
  InvoiceColumn(
    id: InvoiceFieldIds.publicNotes,
    labelKey: 'public_notes',
    width: 240,
    cellBuilder: (i, _) =>
        i.publicNotes.isEmpty ? cellEmpty() : cellText(i.publicNotes),
    valueBuilder: (i) => cellNonZeroString(i.publicNotes),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.privateNotes,
    labelKey: 'private_notes',
    width: 240,
    cellBuilder: (i, _) =>
        i.privateNotes.isEmpty ? cellEmpty() : cellText(i.privateNotes),
    valueBuilder: (i) => cellNonZeroString(i.privateNotes),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (i, ctx) => cellDate(i.updatedAt, ctx),
    valueBuilder: (i) => i.updatedAt.toIso8601String(),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.customValue1,
    labelKey: 'custom_value1',
    width: 140,
    cellBuilder: (i, _) =>
        i.customValue1.isEmpty ? cellEmpty() : cellText(i.customValue1),
    valueBuilder: (i) => cellNonZeroString(i.customValue1),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.customValue2,
    labelKey: 'custom_value2',
    width: 140,
    cellBuilder: (i, _) =>
        i.customValue2.isEmpty ? cellEmpty() : cellText(i.customValue2),
    valueBuilder: (i) => cellNonZeroString(i.customValue2),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.customValue3,
    labelKey: 'custom_value3',
    width: 140,
    cellBuilder: (i, _) =>
        i.customValue3.isEmpty ? cellEmpty() : cellText(i.customValue3),
    valueBuilder: (i) => cellNonZeroString(i.customValue3),
  ),
  InvoiceColumn(
    id: InvoiceFieldIds.customValue4,
    labelKey: 'custom_value4',
    width: 140,
    cellBuilder: (i, _) =>
        i.customValue4.isEmpty ? cellEmpty() : cellText(i.customValue4),
    valueBuilder: (i) => cellNonZeroString(i.customValue4),
  ),
];

final Map<String, InvoiceColumn> invoiceColumnsById = {
  for (final c in kAllInvoiceColumns) c.id: c,
};
