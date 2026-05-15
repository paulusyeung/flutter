import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Shared rendering helpers for `ColumnDefinition<T>.cellBuilder`.
///
/// Every entity's list table renders one of: a text cell, a money cell, a
/// date cell, or an em-dash for empty. The widget anatomy is identical
/// across entities — only the field accessor differs — so the cell
/// renderers live here and each entity's columns file passes its domain
/// field through.
///
/// Money is locale-formatted via `NumberFormat.decimalPattern()` today;
/// `cellBuilder` does not yet receive a currency `Formatter` (its
/// signature is `(entity, context)` — see `column_definition.dart`). When
/// that widens, [cellMoney] should be extended to honor a passed-in
/// `Formatter` for per-client → company currency cascades. Until then,
/// money columns in the wide table use the same locale-blind rendering
/// they always have.

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
/// [onTap] when clicked. Used on the Number cell to provide a one-click
/// shortcut to the row's edit screen (same target as the actions popup's
/// "Edit" item). [LinkText] absorbs the tap with an opaque hit-test so the
/// surrounding row [InkWell] does not also fire its "open detail" handler.
Widget cellLink(
  BuildContext context,
  String value, {
  required VoidCallback onTap,
  bool bold = false,
}) {
  if (value.isEmpty) return cellEmpty();
  final tokens = context.inTheme;
  return LinkText(
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
  );
}

/// Decimal money cell. [cents] controls fraction-digit count — true for
/// always-2-digit currencies (USD-style), false for whole-unit subtotals
/// (paid-to-date, credit-balance — match the legacy admin-portal which
/// drops trailing zeros). Zero values render as an em-dash so the column
/// reads as "no activity" rather than a wall of zeros.
Widget cellMoney(Decimal value, {bool cents = true}) {
  final isZero = value == Decimal.zero;
  final formatter = NumberFormat.decimalPattern()
    ..minimumFractionDigits = cents ? 2 : 0
    ..maximumFractionDigits = cents ? 2 : 0;
  return MoneyCellText(
    text: isZero ? '—' : formatter.format(value.toDouble()),
    isZero: isZero,
  );
}

/// Date cell, formatted with the active locale's medium date pattern
/// (`Jan 5, 2026`). Caller decides whether to render the result of
/// `cellEmpty()` for a null/missing date.
Widget cellDate(DateTime value, BuildContext context) {
  final formatter = DateFormat.yMMMd(
    Localizations.localeOf(context).toString(),
  );
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
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.2,
        color: isZero ? tokens.ink3 : tokens.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
