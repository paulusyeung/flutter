import 'package:admin/data/db/dao/payment_link_dao.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef PaymentLinkColumn = ColumnDefinition<PaymentLink>;

const List<String> kDefaultPaymentLinkColumns = <String>[
  PaymentLinkFieldIds.name,
  PaymentLinkFieldIds.price,
  _PaymentLinkExtraColumns.purchasePage,
];

class _PaymentLinkExtraColumns {
  static const String purchasePage = 'purchase_page';
}

final List<PaymentLinkColumn> kAllPaymentLinkColumns = <PaymentLinkColumn>[
  PaymentLinkColumn(
    id: PaymentLinkFieldIds.name,
    labelKey: 'name',
    cellBuilder: (s, _) => cellText(s.name, bold: true),
    valueBuilder: (s) => cellNonZeroString(s.name),
  ),
  PaymentLinkColumn(
    id: PaymentLinkFieldIds.price,
    labelKey: 'price',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (s, _) => cellMoney(s.price),
    valueBuilder: (s) => cellMoneyValue(s.price),
  ),
  PaymentLinkColumn(
    id: _PaymentLinkExtraColumns.purchasePage,
    labelKey: 'purchase_page',
    cellBuilder: (s, _) => cellText(s.purchasePage),
    valueBuilder: (s) => cellNonZeroString(s.purchasePage),
  ),
  PaymentLinkColumn(
    id: PaymentLinkFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 110,
    cellBuilder: (s, ctx) => cellDate(s.updatedAt, ctx),
    valueBuilder: (s) => s.updatedAt.toIso8601String(),
  ),
];

final Map<String, PaymentLinkColumn> paymentLinkColumnsById = {
  for (final c in kAllPaymentLinkColumns) c.id: c,
};
