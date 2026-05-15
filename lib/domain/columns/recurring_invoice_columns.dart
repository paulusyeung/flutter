import 'package:admin/data/db/dao/recurring_invoice_dao.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/data/models/domain/recurring_invoice_status.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef RecurringInvoiceColumn = ColumnDefinition<RecurringInvoice>;

const List<String> kDefaultRecurringInvoiceColumns = <String>[
  RecurringInvoiceFieldIds.status,
  RecurringInvoiceFieldIds.number,
  RecurringInvoiceFieldIds.clientId,
  RecurringInvoiceFieldIds.amount,
  RecurringInvoiceFieldIds.nextSendDate,
];

final List<RecurringInvoiceColumn> kAllRecurringInvoiceColumns =
    <RecurringInvoiceColumn>[
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.status,
    labelKey: 'status',
    width: 110,
    cellBuilder: (r, _) =>
        cellText(recurringInvoiceStatusLabelKey(r.calculatedStatusId)),
    valueBuilder: (r) => r.calculatedStatusId,
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.number,
    labelKey: 'recurring_invoice_number',
    width: 130,
    cellBuilder: (r, _) => cellText(r.number, bold: true),
    valueBuilder: (r) => cellNonZeroString(r.number),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.clientId,
    labelKey: 'client',
    width: 200,
    cellBuilder: (r, _) =>
        r.clientId.isEmpty ? cellEmpty() : cellText(r.clientId),
    valueBuilder: (r) => cellNonZeroString(r.clientId),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.amount,
    labelKey: 'amount',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (r, _) => cellMoney(r.amount),
    valueBuilder: (r) => cellMoneyValue(r.amount),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.balance,
    labelKey: 'balance',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (r, _) => cellMoney(r.balance),
    valueBuilder: (r) => cellMoneyValue(r.balance),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.nextSendDate,
    labelKey: 'next_send_date',
    width: 130,
    cellBuilder: (r, ctx) => r.nextSendDate == null
        ? cellEmpty()
        : cellDate(r.nextSendDate!.toDateTime(), ctx),
    valueBuilder: (r) => r.nextSendDate?.toIso(),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.frequencyId,
    labelKey: 'frequency',
    width: 110,
    cellBuilder: (r, _) =>
        r.frequencyId.isEmpty ? cellEmpty() : cellText(r.frequencyId),
    valueBuilder: (r) => cellNonZeroString(r.frequencyId),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.remainingCycles,
    labelKey: 'remaining_cycles',
    width: 110,
    align: ColumnAlign.end,
    cellBuilder: (r, _) => cellText('${r.remainingCycles}'),
    valueBuilder: (r) => '${r.remainingCycles}',
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.poNumber,
    labelKey: 'po_number',
    width: 130,
    cellBuilder: (r, _) =>
        r.poNumber.isEmpty ? cellEmpty() : cellText(r.poNumber),
    valueBuilder: (r) => cellNonZeroString(r.poNumber),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.designId,
    labelKey: 'design',
    width: 130,
    cellBuilder: (r, _) =>
        r.designId.isEmpty ? cellEmpty() : cellText(r.designId),
    valueBuilder: (r) => cellNonZeroString(r.designId),
  ),
  RecurringInvoiceColumn(
    id: RecurringInvoiceFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (r, ctx) => cellDate(r.updatedAt, ctx),
    valueBuilder: (r) => r.updatedAt.toIso8601String(),
  ),
  for (var i = 1; i <= 4; i++)
    RecurringInvoiceColumn(
      id: 'custom_value$i',
      labelKey: 'custom_value$i',
      width: 140,
      cellBuilder: (r, _) {
        final v = switch (i) {
          1 => r.customValue1,
          2 => r.customValue2,
          3 => r.customValue3,
          _ => r.customValue4,
        };
        return v.isEmpty ? cellEmpty() : cellText(v);
      },
      valueBuilder: (r) {
        final v = switch (i) {
          1 => r.customValue1,
          2 => r.customValue2,
          3 => r.customValue3,
          _ => r.customValue4,
        };
        return cellNonZeroString(v);
      },
    ),
];

final Map<String, RecurringInvoiceColumn> recurringInvoiceColumnsById = {
  for (final c in kAllRecurringInvoiceColumns) c.id: c,
};
