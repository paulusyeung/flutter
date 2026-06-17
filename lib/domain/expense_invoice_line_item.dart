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
/// By-amount taxes (`calculate_tax_by_amount`) carry no line rate, so the rate
/// is reconstructed from the stored `tax_amount*` relative to the net base
/// (`tax_amount / net * 100`) and attached with the tax name — mirroring React's
/// `calculatedTaxRate`. Applied against the net base this reproduces the same
/// per-tier tax under both exclusive and (single-tier) inclusive invoices, so
/// the invoice keeps its per-tax-name breakdown / tax reporting instead of
/// folding the tax silently into `cost`. The line total is unchanged either way.
LineItem expenseInvoiceLineItem(
  Expense expense, {
  required bool invoiceInclusive,
}) {
  final hasConversion =
      expense.invoiceCurrencyId.isNotEmpty &&
      expense.foreignAmount > Decimal.zero;
  final fx = hasConversion ? expense.effectiveExchangeRate : Decimal.one;
  final base = invoiceInclusive ? expense.grossAmount : expense.netAmount;
  final item = emptyLineItem().copyWith(
    expenseId: expense.id,
    notes: expense.publicNotes,
    quantity: Decimal.one,
    cost: base * fx,
  );

  // In rate mode the stored rate is authoritative; in by-amount mode derive a
  // rate from the stored tax amount against the net base.
  final net = expense.netAmount;
  Decimal rateFor(Decimal storedRate, Decimal storedAmount) {
    if (!expense.calculateTaxByAmount) return storedRate;
    if (net <= Decimal.zero || storedAmount == Decimal.zero) {
      return Decimal.zero;
    }
    return (storedAmount * Decimal.fromInt(100) / net).toDecimal(
      scaleOnInfinitePrecision: 10,
    );
  }

  return item.copyWith(
    taxName1: expense.taxName1,
    taxRate1: rateFor(expense.taxRate1, expense.taxAmount1),
    taxName2: expense.taxName2,
    taxRate2: rateFor(expense.taxRate2, expense.taxAmount2),
    taxName3: expense.taxName3,
    taxRate3: rateFor(expense.taxRate3, expense.taxAmount3),
  );
}
