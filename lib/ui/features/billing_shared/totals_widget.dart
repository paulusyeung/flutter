import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';

/// Read-only totals breakdown card. Drives the sticky-bottom footer on
/// every billing-doc edit screen (Invoice / Quote / Credit / PO /
/// RecurringInvoice) and the totals card on the detail screen.
///
/// Inputs are pure value types — no entity coupling. The host computes a
/// [BillingTotalsResult] via [computeTotals] and feeds it here alongside
/// the four custom-surcharge labels + values (which aren't in the totals
/// struct because they're invoice-level inputs, not derived). Money
/// rendering uses a basic [NumberFormat] today; when the formatter
/// pipeline reaches the shared layer the widget will switch to
/// `Formatter.money(...)` per CLAUDE.md.
class TotalsWidget extends StatelessWidget {
  TotalsWidget({
    super.key,
    required this.totals,
    Decimal? discount,
    this.discountIsAmount = false,
    this.surcharges = const <TotalsSurcharge>[],
    Decimal? partial,
    this.balance,
    this.paidToDate,
    this.dense = false,
    this.slim = false,
    this.bordered = true,
    this.formatter,
    this.currencyId,
  }) : discount = discount ?? Decimal.zero,
       partial = partial ?? Decimal.zero;

  /// The computed result from `computeTotals(...)`.
  final BillingTotalsResult totals;

  /// Invoice-level discount value as the user entered it (raw — % or
  /// amount, the widget renders both flavors).
  final Decimal discount;
  final bool discountIsAmount;

  /// Up to four invoice-level surcharges with display labels. Pass the
  /// company's custom surcharge labels (e.g. `[(label: 'Shipping',
  /// amount: 12.00), …]`). Zero-amount entries are hidden.
  final List<TotalsSurcharge> surcharges;

  /// Partial-payment amount (if the invoice supports staged payment).
  /// Zero hides the row.
  final Decimal partial;

  /// Balance after paid-to-date. When null the widget shows just the
  /// computed total (useful for new-invoice drafts where balance =
  /// total by definition).
  final Decimal? balance;
  final Decimal? paidToDate;

  /// Compact mode: smaller padding + 13 px text. Used in the edit-screen
  /// sticky-bottom footer. Default false renders the larger detail-screen
  /// variant.
  final bool dense;

  /// Slim mode: render only the grand-total row (plus balance when it
  /// differs from total). Used by the always-visible bottom bar on the
  /// desktop edit screen, where the full breakdown lives in a separate
  /// card. Implies a flat dense strip; ignored unless [dense] is true.
  final bool slim;

  /// When false (non-dense only), render the rows as a plain padded
  /// list with no border / shadow / radius — matches the React + old
  /// Flutter references where the totals are a borderless row list.
  /// Default true keeps the bordered detail-screen card.
  final bool bordered;

  /// When provided, money rows render via `Formatter.money` (currency symbol,
  /// company precision + separators) instead of the bare [NumberFormat]
  /// fallback. [currencyId] feeds the client-currency cascade.
  final Formatter? formatter;
  final String? currencyId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (dense && slim) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.lg(context),
          vertical: InSpacing.sm,
        ),
        color: tokens.surfaceAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(
              context,
              label: context.tr('total'),
              amount: totals.total,
              strong: true,
            ),
            if (balance != null && balance != totals.total)
              _row(
                context,
                label: context.tr('balance'),
                amount: balance!,
                strong: true,
              ),
          ],
        ),
      );
    }
    final rows = <Widget>[
      _row(context, label: context.tr('subtotal'), amount: totals.subtotal),
      if (discount != Decimal.zero)
        _row(
          context,
          label: context.tr('discount'),
          amount: discountIsAmount ? discount : null,
          rawText: discountIsAmount
              ? null
              : (formatter?.percent(discount.toDouble()) ??
                    '${discount.toString()}%'),
          subtractive: true,
        ),
      for (final s in surcharges)
        if (s.amount != Decimal.zero)
          _row(context, label: s.label, amount: s.amount),
      for (final entry in totals.taxBreakdown.entries)
        if (entry.value != Decimal.zero)
          _row(
            context,
            label: entry.key.isEmpty ? context.tr('tax') : entry.key,
            amount: entry.value,
          ),
      if (partial != Decimal.zero)
        _row(context, label: context.tr('partial'), amount: partial),
      Divider(height: InSpacing.lg(context), color: tokens.border),
      _row(
        context,
        label: context.tr('total'),
        amount: totals.total,
        strong: true,
      ),
      if (paidToDate != null && paidToDate! != Decimal.zero)
        _row(
          context,
          label: context.tr('paid_to_date'),
          amount: paidToDate!,
          subtractive: true,
        ),
      if (balance != null && balance != totals.total)
        _row(
          context,
          label: context.tr('balance'),
          amount: balance!,
          strong: true,
        ),
    ];
    // In dense mode the totals widget is the sticky strip pinned to the
    // bottom of the edit screen — render flat (no border / radius) on
    // the alt surface so it reads as a footer rather than a card-inside-
    // a-strip. Non-dense mode (used in the detail screen) keeps the
    // bordered card chrome.
    if (dense) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.lg(context),
          vertical: InSpacing.sm,
        ),
        color: tokens.surfaceAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      );
    }
    if (!bordered) {
      // Borderless row list — matches the React / old-Flutter
      // references where the totals sit as plain rows, no card.
      return Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    Decimal? amount,
    String? rawText,
    bool strong = false,
    bool subtractive = false,
  }) {
    final tokens = context.inTheme;
    final amountText = rawText ?? _formatAmount(amount, subtractive);
    final color = subtractive ? tokens.ink3 : tokens.ink;
    final size = dense ? 13.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 2 : InSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              color: color,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            amountText,
            style: moneyTextStyle(
              fontSize: size,
              color: color,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Money rendering: `Formatter.money` when a [formatter] was supplied, else
  /// the legacy bare [NumberFormat] (no symbol). Subtractive rows keep the
  /// leading `-`.
  String _formatAmount(Decimal? amount, bool subtractive) {
    if (amount == null) return '—';
    final sign = subtractive && amount > Decimal.zero ? '-' : '';
    final f = formatter;
    if (f != null) {
      // [currencyId] is the already-resolved party currency (client *or*
      // vendor) — pass it through the explicit slot so it's unambiguous for
      // vendor docs (purchase orders) too, not just clients.
      return '$sign${f.money(amount, currencyId: currencyId)}';
    }
    final numberFormat = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return '$sign${numberFormat.format(amount.toDouble())}';
  }
}

/// Helper struct: display-label + Decimal amount. Used by [TotalsWidget]
/// for the four invoice-level custom surcharges (whose labels come from
/// `company.customFields['surcharge1'..'surcharge4']`).
class TotalsSurcharge {
  const TotalsSurcharge({required this.label, required this.amount});
  final String label;
  final Decimal amount;
}
