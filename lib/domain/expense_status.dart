/// Expense status discriminator constants. Mirrors admin-portal
/// `constants.dart:1002-1006`. Status string ids are persisted server-side
/// on a small `expense_statuses` static lookup; mostly we derive the active
/// status on the client via [Expense.calculatedStatusId] from the
/// invoice/payment state.
const String kExpenseStatusLogged = '1';
const String kExpenseStatusPending = '2';
const String kExpenseStatusInvoiced = '3';
const String kExpenseStatusUnpaid = '4';
const String kExpenseStatusPaid = '5';

/// Localization keys for each status — `<wireName>` style so tile + detail
/// pill resolve via `context.tr(kExpenseStatusLabels[id]!)`.
const Map<String, String> kExpenseStatusLabels = {
  kExpenseStatusLogged: 'logged',
  kExpenseStatusPending: 'pending',
  kExpenseStatusInvoiced: 'invoiced',
  kExpenseStatusUnpaid: 'unpaid',
  kExpenseStatusPaid: 'paid',
};
