import 'package:decimal/decimal.dart';

import 'package:admin/data/db/dao/bank_transaction_dao.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef BankTransactionColumn = ColumnDefinition<BankTransaction>;

/// Column id constants. Most map 1:1 to `BankTransactionFieldIds`; the
/// `deposit` / `withdrawal` ids are display-only splits of `amount` driven
/// by `baseType`. They aren't sortable on their own — sort by `amount` to
/// order both columns numerically.
class BankTransactionColumnIds {
  static const String status = BankTransactionFieldIds.statusId;
  static const String deposit = 'deposit';
  static const String withdrawal = 'withdrawal';
  static const String date = BankTransactionFieldIds.date;
  static const String participantName =
      BankTransactionFieldIds.participantName;
  static const String description = BankTransactionFieldIds.description;
  static const String bankAccountId = 'bank_account_id';
  static const String invoices = 'invoices';
  static const String expenses = 'expenses';
  static const String currencyId = 'currency_id';
  static const String amount = BankTransactionFieldIds.amount;
  static const String updatedAt = BankTransactionFieldIds.updatedAt;
}

/// Default visible columns. Status pill leads, deposit + withdrawal split by
/// `baseType` so the two amount columns line up for an at-a-glance ledger
/// view, then date / description / linked-entity chips.
const List<String> kDefaultBankTransactionColumns = <String>[
  BankTransactionColumnIds.status,
  BankTransactionColumnIds.deposit,
  BankTransactionColumnIds.withdrawal,
  BankTransactionColumnIds.date,
  BankTransactionColumnIds.description,
  BankTransactionColumnIds.invoices,
  BankTransactionColumnIds.expenses,
];

final List<BankTransactionColumn> kAllBankTransactionColumns =
    <BankTransactionColumn>[
  // Display-only: `status_id` is a denormalized Drift column; the wire
  // value is "1"/"2"/"3", but we render the localized label via the row
  // tile so this cell just exposes the raw string for clipboard copy +
  // server-side sort.
  BankTransactionColumn(
    id: BankTransactionColumnIds.status,
    labelKey: 'status',
    width: 110,
    cellBuilder: (t, _) => cellText(_statusLabelKey(t.statusId)),
    valueBuilder: (t) => t.statusId,
  ),
  // Deposits column — only populated for CREDIT rows (per the React UX).
  // Sort by `amount`, not `deposit` (the column id is display-only).
  BankTransactionColumn(
    id: BankTransactionColumnIds.deposit,
    labelKey: 'deposit',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (t, _) =>
        t.isDeposit ? cellMoney(t.amount) : cellEmpty(),
    valueBuilder: (t) =>
        t.isDeposit ? cellMoneyValue(t.amount) : null,
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.withdrawal,
    labelKey: 'withdrawal',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (t, _) =>
        t.isWithdrawal ? cellMoney(t.amount) : cellEmpty(),
    valueBuilder: (t) =>
        t.isWithdrawal ? cellMoneyValue(t.amount) : null,
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.amount,
    labelKey: 'amount',
    width: 130,
    align: ColumnAlign.end,
    cellBuilder: (t, _) => cellMoney(t.amount),
    valueBuilder: (t) => cellMoneyValue(t.amount),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.date,
    labelKey: 'date',
    width: 120,
    cellBuilder: (t, ctx) => t.date == null
        ? cellEmpty()
        : cellDate(t.date!.toDateTime(), ctx),
    valueBuilder: (t) => t.date?.toIso(),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.participantName,
    labelKey: 'participant_name',
    width: 200,
    cellBuilder: (t, _) =>
        t.participantName.isEmpty ? cellEmpty() : cellText(t.participantName),
    valueBuilder: (t) => cellNonZeroString(t.participantName),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.description,
    labelKey: 'description',
    width: 240,
    cellBuilder: (t, _) =>
        t.description.isEmpty ? cellEmpty() : cellText(t.description),
    valueBuilder: (t) => cellNonZeroString(t.description),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.bankAccountId,
    labelKey: 'bank_account',
    width: 180,
    cellBuilder: (t, _) =>
        t.bankAccountId.isEmpty ? cellEmpty() : cellText(t.bankAccountId),
    valueBuilder: (t) => cellNonZeroString(t.bankAccountId),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.invoices,
    labelKey: 'invoices',
    width: 160,
    cellBuilder: (t, _) {
      final ids = t.linkedInvoiceIds;
      return ids.isEmpty ? cellEmpty() : cellText(ids.join(', '));
    },
    valueBuilder: (t) => cellNonZeroString(t.invoiceIds),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.expenses,
    labelKey: 'expense',
    width: 160,
    cellBuilder: (t, _) {
      final ids = t.linkedExpenseIds;
      return ids.isEmpty ? cellEmpty() : cellText(ids.join(', '));
    },
    valueBuilder: (t) => cellNonZeroString(t.expenseId),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.currencyId,
    labelKey: 'currency',
    width: 100,
    cellBuilder: (t, _) =>
        t.currencyId.isEmpty ? cellEmpty() : cellText(t.currencyId),
    valueBuilder: (t) => cellNonZeroString(t.currencyId),
  ),
  BankTransactionColumn(
    id: BankTransactionColumnIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (t, ctx) => cellDate(t.updatedAt, ctx),
    valueBuilder: (t) => t.updatedAt.toIso8601String(),
  ),
];

final Map<String, BankTransactionColumn> bankTransactionColumnsById = {
  for (final c in kAllBankTransactionColumns) c.id: c,
};

/// Localization key for a `status_id` wire value. Renders blank for unknown
/// values rather than the raw "4"/"5" so a future server-side status flip
/// degrades gracefully.
String _statusLabelKey(String statusId) {
  switch (statusId) {
    case kTransactionStatusUnmatched:
      return 'unmatched';
    case kTransactionStatusMatched:
      return 'matched';
    case kTransactionStatusConverted:
      return 'converted';
    default:
      return '';
  }
}

/// Sum of [amount] across [items] — used by the match panel's "calculate
/// total" affordance and by the multi-pick sheet's running summary.
Decimal sumTransactionAmounts(Iterable<BankTransaction> items) {
  var total = Decimal.zero;
  for (final t in items) {
    total += t.amount;
  }
  return total;
}
