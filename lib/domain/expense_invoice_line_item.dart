import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/expense.dart';

/// Builds the invoice line item for the "Invoice expense" / "Add to invoice"
/// expense actions. A pure mapping (no `BuildContext`) so the billing math is
/// unit-testable in isolation.
///
/// Invoice line tax is governed by the **invoice-level** `usesInclusiveTaxes`
/// flag (there is no per-line flag — see `totals_calculator`), so the seeded
/// `cost` tracks [invoiceInclusive], not the expense's own tax mode:
///   * inclusive invoice → bill the **gross** (the calculator extracts the tax
///     from it),
///   * exclusive invoice → bill the **net** (the calculator adds the tax on
///     top).
/// Either way the resulting line total lands on the expense's (converted)
/// gross, with the correct tax split.
///
/// Amounts are converted into the invoice currency when the expense carries a
/// conversion (`invoice_currency_id` + a non-zero `foreign_amount`), mirroring
/// React's `foreign_amount > 0 ? foreign_amount : amount` and admin-portal's
/// `convertedAmount` / `convertedNetAmount`. Without a conversion the rate is 1
/// (a no-op), so same-currency expenses are unaffected.
///
/// By-amount taxes (`calculate_tax_by_amount`) can't map to a line rate, so
/// they're dropped and the full (converted) gross is billed as the cost.
LineItem expenseInvoiceLineItem(
  Expense expense, {
  required bool invoiceInclusive,
}) {
  final hasConversion =
      expense.invoiceCurrencyId.isNotEmpty &&
      expense.foreignAmount > Decimal.zero;
  final fx = hasConversion ? expense.effectiveExchangeRate : Decimal.one;
  final carryTax = !expense.calculateTaxByAmount;
  final base = carryTax
      ? (invoiceInclusive ? expense.grossAmount : expense.netAmount)
      : expense.grossAmount;
  final item = emptyLineItem().copyWith(
    expenseId: expense.id,
    notes: expense.publicNotes,
    quantity: Decimal.one,
    cost: base * fx,
  );
  if (!carryTax) return item;
  return item.copyWith(
    taxName1: expense.taxName1,
    taxRate1: expense.taxRate1,
    taxName2: expense.taxName2,
    taxRate2: expense.taxRate2,
    taxName3: expense.taxName3,
    taxRate3: expense.taxRate3,
  );
}
