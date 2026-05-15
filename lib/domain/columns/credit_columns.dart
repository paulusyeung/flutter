import 'package:admin/data/db/dao/credit_dao.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/models/domain/credit_status.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef CreditColumn = ColumnDefinition<Credit>;

const List<String> kDefaultCreditColumns = <String>[
  CreditFieldIds.status,
  CreditFieldIds.number,
  CreditFieldIds.clientId,
  CreditFieldIds.amount,
  CreditFieldIds.balance,
  CreditFieldIds.date,
];

final List<CreditColumn> kAllCreditColumns = <CreditColumn>[
  CreditColumn(
    id: CreditFieldIds.status,
    labelKey: 'status',
    width: 110,
    cellBuilder: (c, _) => cellText(creditStatusLabelKey(c.calculatedStatusId)),
    valueBuilder: (c) => c.calculatedStatusId,
  ),
  CreditColumn(
    id: CreditFieldIds.number,
    labelKey: 'credit_number',
    width: 130,
    cellBuilder: (c, _) => cellText(c.number, bold: true),
    valueBuilder: (c) => cellNonZeroString(c.number),
  ),
  CreditColumn(
    id: CreditFieldIds.clientId,
    labelKey: 'client',
    width: 200,
    cellBuilder: (c, _) =>
        c.clientId.isEmpty ? cellEmpty() : cellText(c.clientId),
    valueBuilder: (c) => cellNonZeroString(c.clientId),
  ),
  CreditColumn(
    id: CreditFieldIds.date,
    labelKey: 'credit_date',
    width: 120,
    cellBuilder: (c, ctx) => c.date == null
        ? cellEmpty()
        : cellDate(c.date!.toDateTime(), ctx),
    valueBuilder: (c) => c.date?.toIso(),
  ),
  CreditColumn(
    id: CreditFieldIds.amount,
    labelKey: 'amount',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (c, _) => cellMoney(c.amount),
    valueBuilder: (c) => cellMoneyValue(c.amount),
  ),
  CreditColumn(
    id: CreditFieldIds.balance,
    labelKey: 'balance',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (c, _) => cellMoney(c.balance),
    valueBuilder: (c) => cellMoneyValue(c.balance),
  ),
  CreditColumn(
    id: CreditFieldIds.paidToDate,
    labelKey: 'applied',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (c, _) => cellMoney(c.paidToDate),
    valueBuilder: (c) => cellMoneyValue(c.paidToDate),
  ),
  CreditColumn(
    id: CreditFieldIds.poNumber,
    labelKey: 'po_number',
    width: 130,
    cellBuilder: (c, _) =>
        c.poNumber.isEmpty ? cellEmpty() : cellText(c.poNumber),
    valueBuilder: (c) => cellNonZeroString(c.poNumber),
  ),
  CreditColumn(
    id: CreditFieldIds.designId,
    labelKey: 'design',
    width: 130,
    cellBuilder: (c, _) =>
        c.designId.isEmpty ? cellEmpty() : cellText(c.designId),
    valueBuilder: (c) => cellNonZeroString(c.designId),
  ),
  CreditColumn(
    id: CreditFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (c, ctx) => cellDate(c.updatedAt, ctx),
    valueBuilder: (c) => c.updatedAt.toIso8601String(),
  ),
  for (var i = 1; i <= 4; i++)
    CreditColumn(
      id: 'custom_value$i',
      labelKey: 'custom_value$i',
      width: 140,
      cellBuilder: (c, _) {
        final v = switch (i) {
          1 => c.customValue1,
          2 => c.customValue2,
          3 => c.customValue3,
          _ => c.customValue4,
        };
        return v.isEmpty ? cellEmpty() : cellText(v);
      },
      valueBuilder: (c) {
        final v = switch (i) {
          1 => c.customValue1,
          2 => c.customValue2,
          3 => c.customValue3,
          _ => c.customValue4,
        };
        return cellNonZeroString(v);
      },
    ),
];

final Map<String, CreditColumn> creditColumnsById = {
  for (final c in kAllCreditColumns) c.id: c,
};
