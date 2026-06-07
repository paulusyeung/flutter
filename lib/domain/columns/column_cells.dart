import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/formatter_scope.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Shared rendering helpers for `ColumnDefinition<T>.cellBuilder`.
///
/// Every entity's list table renders one of: a text cell, a money cell, a
/// date cell, or an em-dash for empty. The widget anatomy is identical
/// across entities — only the field accessor differs — so the cell
/// renderers live here and each entity's columns file passes its domain
/// field through.
///
/// NOTE: although this lives under `lib/domain/`, it is a **UI-layer
/// helper** — it imports `package:flutter/material.dart`, returns
/// `Widget`s, and is only ever invoked from the list render path. The
/// `lib/domain/columns/` location is pre-existing misfiling; importing
/// `lib/ui/...` from here is therefore not a new layering regression.
///
/// [cellMoney] formats through the active-company [Formatter] (per-client
/// → company currency cascade + Euro override) when a [FormatterScope] is
/// in the tree — which the list scaffold provides for money-bearing
/// entities. Without a scope (non-financial screens, or the formatter
/// still resolving on a cold start) it falls back to the cached
/// locale-only `NumberFormat`. Entities whose row carries its own
/// currency (`client`/`payment`/`vendor`/`expense`/`recurring_expense`/
/// `bank_transaction`) pass it through the matching cascade slot; billing
/// docs (`invoice`/`quote`/`credit`/…) carry no row currency and so
/// format with the company default — correct symbol/precision, just not
/// per-client.

/// Empty / placeholder cell. Renders an em-dash in muted ink.
Widget cellEmpty() => const CellText(value: '—', muted: true);

/// Plain text cell. Empty strings render as [cellEmpty]. Set [bold] for the
/// identity / name column.
Widget cellText(String value, {bool bold = false}) {
  if (value.isEmpty) return cellEmpty();
  return CellText(value: value, bold: bold);
}

/// Linked text cell. Renders the value with the same typographic weight as
/// [cellText] but reveals an underline + pointer cursor on hover and fires
/// [onTap] when clicked. Used on the Number cell to open the row's
/// full-width **view** page (editing is reached from the view's Edit
/// button). [LinkText] absorbs the tap with an opaque hit-test so the
/// surrounding row [InkWell] does not also fire its slide-over preview.
/// Wrapped in a [Tooltip] so the two distinct click targets in one row
/// (link = full view page, row = preview pane) are discoverable.
Widget cellLink(
  BuildContext context,
  String value, {
  required VoidCallback onTap,
  bool bold = false,
}) {
  if (value.isEmpty) return cellEmpty();
  final tokens = context.inTheme;
  return Tooltip(
    message: context.tr('view'),
    waitDuration: const Duration(milliseconds: 500),
    child: LinkText(
      label: value,
      onTap: onTap,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: tokens.ink,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// Cached `NumberFormat` instances for [cellMoney]. `NumberFormat` is an
/// expensive `intl` object (it parses locale pattern tables on
/// construction) but is safe to reuse across calls — formatting is
/// stateless. Only two shapes exist (2-digit vs whole-unit), so two lazy
/// singletons replace the per-cell allocation that previously cost
/// ~6-8 instances per row × 50 visible rows per scroll frame.
final NumberFormat _moneyCentsFormat = NumberFormat.decimalPattern()
  ..minimumFractionDigits = 2
  ..maximumFractionDigits = 2;
final NumberFormat _moneyWholeFormat = NumberFormat.decimalPattern()
  ..minimumFractionDigits = 0
  ..maximumFractionDigits = 0;

/// Cached medium-date `DateFormat` per locale string. Keyed by locale
/// because the pattern is locale-dependent; in practice the app runs one
/// active locale so this map holds a single entry. Same reuse rationale
/// as the money formatters above.
final Map<String, DateFormat> _dateFormatCache = {};

/// Decimal money cell. Zero renders as an em-dash so the column reads as
/// "no activity" rather than a wall of zeros (cell convention — kept even
/// though `Formatter.money` would emit `''`).
///
/// When a [FormatterScope] is present the value is formatted through the
/// company [Formatter] (currency symbol/code + the currency's own
/// precision + the per-client→company cascade). Callers pass the row's
/// currency through the cascade slot that matches the entity, exactly as
/// the mobile tiles do: [clientCurrencyId] for client-owned rows,
/// [vendorCurrencyId] for vendor-owned, [currencyId] for rows that carry
/// an explicit currency (payment/expense/bank-transaction); billing docs
/// pass none and format with the company default.
///
/// Without a scope it falls back to the cached locale-only `NumberFormat`
/// — [cents] then controls fraction digits (true = always 2;
/// false = whole-unit, dropping trailing zeros to match the legacy
/// admin-portal). With a scope the currency's precision governs and
/// [cents] is moot.
Widget cellMoney(
  Decimal value,
  BuildContext context, {
  bool cents = true,
  String? clientCurrencyId,
  String? vendorCurrencyId,
  String? currencyId,
}) {
  if (value == Decimal.zero) {
    return const MoneyCellText(text: '—', isZero: true);
  }
  final formatter = FormatterScope.maybeOf(context);
  final text = formatter?.money(
    value,
    clientCurrencyId: clientCurrencyId,
    vendorCurrencyId: vendorCurrencyId,
    currencyId: currencyId,
  );
  return MoneyCellText(
    text: (text != null && text.isNotEmpty)
        ? text
        : (cents ? _moneyCentsFormat : _moneyWholeFormat).format(
            value.toDouble(),
          ),
    isZero: false,
  );
}

/// Date cell, formatted with the active locale's medium date pattern
/// (`Jan 5, 2026`). Caller decides whether to render the result of
/// `cellEmpty()` for a null/missing date.
Widget cellDate(DateTime value, BuildContext context) {
  final localeKey = Localizations.localeOf(context).toString();
  final formatter = _dateFormatCache[localeKey] ??= DateFormat.yMMMd(localeKey);
  return CellText(value: formatter.format(value.toLocal()));
}

/// Canonical string for a money cell, used by `valueBuilder` to drive the
/// hover-copy affordance. Zero collapses to null so copy is suppressed.
String? cellMoneyValue(Decimal v) => v == Decimal.zero ? null : v.toString();

/// Canonical string for a plain-text cell, used by `valueBuilder` to drive
/// the hover-copy affordance. Empty strings collapse to null.
String? cellNonZeroString(String s) => s.isEmpty ? null : s;

/// Plain text widget tuned for table cells: 13px / 1.2 line-height /
/// elided, with muted-ink support for the em-dash placeholder.
class CellText extends StatelessWidget {
  const CellText({
    required this.value,
    this.bold = false,
    this.muted = false,
    super.key,
  });

  final String value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: muted ? tokens.ink4 : tokens.ink,
      ),
    );
  }
}

/// Money widget tuned for table cells: monospaced + tabular figures so
/// digits align vertically across rows.
class MoneyCellText extends StatelessWidget {
  const MoneyCellText({required this.text, required this.isZero, super.key});

  final String text;
  final bool isZero;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: kMonoFontFamily,
        fontSize: 13,
        height: 1.2,
        color: isZero ? tokens.ink3 : tokens.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
