import 'package:go_router/go_router.dart';

import 'package:admin/data/db/dao/purchase_order_dao.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/core/widgets/vendor_name_label.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_status_pill.dart';

typedef PurchaseOrderColumn = ColumnDefinition<PurchaseOrder>;

const List<String> kDefaultPurchaseOrderColumns = <String>[
  PurchaseOrderFieldIds.status,
  PurchaseOrderFieldIds.number,
  PurchaseOrderFieldIds.vendorId,
  PurchaseOrderFieldIds.amount,
  PurchaseOrderFieldIds.date,
];

final List<PurchaseOrderColumn> kAllPurchaseOrderColumns =
    <PurchaseOrderColumn>[
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.status,
    labelKey: 'status',
    width: 110,
    cellBuilder: (p, _) =>
        PurchaseOrderStatusPill(statusId: p.calculatedStatusId),
    valueBuilder: (p) => p.calculatedStatusId,
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.number,
    labelKey: 'number',
    width: 130,
    cellBuilder: (p, ctx) => cellLink(
      ctx,
      p.number,
      bold: true,
      onTap: () => ctx.go('/purchase_orders/${p.id}/edit'),
    ),
    valueBuilder: (p) => cellNonZeroString(p.number),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.vendorId,
    labelKey: 'vendor',
    width: 200,
    cellBuilder: (p, _) =>
        p.vendorId.isEmpty ? cellEmpty() : VendorNameLabel(vendorId: p.vendorId),
    valueBuilder: (p) => cellNonZeroString(p.vendorId),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.date,
    labelKey: 'date',
    width: 120,
    cellBuilder: (p, ctx) =>
        p.date == null ? cellEmpty() : cellDate(p.date!.toDateTime(), ctx),
    valueBuilder: (p) => p.date?.toIso(),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.dueDate,
    labelKey: 'due_date',
    width: 120,
    cellBuilder: (p, ctx) => p.dueDate == null
        ? cellEmpty()
        : cellDate(p.dueDate!.toDateTime(), ctx),
    valueBuilder: (p) => p.dueDate?.toIso(),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.amount,
    labelKey: 'amount',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (p, _) => cellMoney(p.amount),
    valueBuilder: (p) => cellMoneyValue(p.amount),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.balance,
    labelKey: 'balance',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (p, _) => cellMoney(p.balance),
    valueBuilder: (p) => cellMoneyValue(p.balance),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.poNumber,
    labelKey: 'po_number',
    width: 130,
    cellBuilder: (p, _) =>
        p.poNumber.isEmpty ? cellEmpty() : cellText(p.poNumber),
    valueBuilder: (p) => cellNonZeroString(p.poNumber),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.designId,
    labelKey: 'design',
    width: 130,
    cellBuilder: (p, _) =>
        p.designId.isEmpty ? cellEmpty() : cellText(p.designId),
    valueBuilder: (p) => cellNonZeroString(p.designId),
  ),
  PurchaseOrderColumn(
    id: PurchaseOrderFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (p, ctx) => cellDate(p.updatedAt, ctx),
    valueBuilder: (p) => p.updatedAt.toIso8601String(),
  ),
  for (var i = 1; i <= 4; i++)
    PurchaseOrderColumn(
      id: 'custom_value$i',
      labelKey: 'custom_value$i',
      width: 140,
      cellBuilder: (p, _) {
        final v = switch (i) {
          1 => p.customValue1,
          2 => p.customValue2,
          3 => p.customValue3,
          _ => p.customValue4,
        };
        return v.isEmpty ? cellEmpty() : cellText(v);
      },
      valueBuilder: (p) {
        final v = switch (i) {
          1 => p.customValue1,
          2 => p.customValue2,
          3 => p.customValue3,
          _ => p.customValue4,
        };
        return cellNonZeroString(v);
      },
    ),
];

final Map<String, PurchaseOrderColumn> purchaseOrderColumnsById = {
  for (final c in kAllPurchaseOrderColumns) c.id: c,
};
