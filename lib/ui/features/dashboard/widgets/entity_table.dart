import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Tabular row layout used by the dashboard list cards, matching the v2
/// `InvoiceTable` (`docs/design/v2/screens.jsx:357-390`):
///
/// ```
///   INVOICE    CLIENT             STATUS    DUE     AMOUNT   ⋮
///   INV-2041   Bauhaus Atelier   [Overdue]  May 30  $4,200   ⋮
/// ```
///
/// The widget is intentionally column-agnostic — each card supplies its own
/// header labels, column widths, and row cells. Compact mode (the default,
/// used inside dashboard cards) gives `10×16` cell padding; the full variant
/// uses `14×16`, matching the spec's `compact` flag.
class DashboardEntityTable extends StatelessWidget {
  const DashboardEntityTable({
    super.key,
    required this.headers,
    required this.columnWidths,
    required this.rows,
    this.compact = true,
    this.cellAlignments = const {},
  });

  /// One label per column; pass `''` for the trailing menu column. Length
  /// must equal the number of columns in [columnWidths] and in each row's
  /// `cells`.
  final List<String> headers;

  /// Per-column width specification, keyed by column index. Standard recipe
  /// for the invoice-style layout is `{0: IntrinsicColumnWidth(), 1:
  /// FlexColumnWidth(2), 2..4: IntrinsicColumnWidth(), 5: FixedColumnWidth(32)}`.
  final Map<int, TableColumnWidth> columnWidths;

  /// Per-column cell alignment override. Defaults to `Alignment.centerLeft`
  /// when not set. The amount column typically wants `Alignment.centerRight`.
  final Map<int, Alignment> cellAlignments;

  final List<DashboardEntityTableRow> rows;

  /// Compact rows (10×16 padding) for dashboard cards; non-compact (14×16)
  /// matches the full invoice-list page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final rowPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _headerRow(tokens),
        for (var i = 0; i < rows.length; i++)
          _dataRow(context, tokens, rows[i], rowPadding, isLast: i == rows.length - 1),
      ],
    );
  }

  TableRow _headerRow(InTheme tokens) {
    return TableRow(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      children: [
        for (var i = 0; i < headers.length; i++)
          _HeaderCell(
            label: headers[i],
            alignment: cellAlignments[i] ?? Alignment.centerLeft,
            tokens: tokens,
          ),
      ],
    );
  }

  TableRow _dataRow(
    BuildContext context,
    InTheme tokens,
    DashboardEntityTableRow row,
    EdgeInsets padding, {
    required bool isLast,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tokens.border)),
      ),
      children: [
        for (var i = 0; i < row.cells.length; i++)
          _bodyCell(
            child: row.cells[i],
            padding: padding,
            alignment: cellAlignments[i] ?? Alignment.centerLeft,
            onTap: i < (row.cellTaps?.length ?? 0) ? row.cellTaps![i] : null,
          ),
      ],
    );
  }

  Widget _bodyCell({
    required Widget child,
    required EdgeInsets padding,
    required Alignment alignment,
    VoidCallback? onTap,
  }) {
    final inner = Padding(
      padding: padding,
      child: Align(alignment: alignment, child: child),
    );
    if (onTap == null) {
      return TableCell(child: inner);
    }
    return TableCell(
      child: TableRowInkWell(onTap: onTap, child: inner),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.alignment,
    required this.tokens,
  });

  final String label;
  final Alignment alignment;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(
          alignment: alignment,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: tokens.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardEntityTableRow {
  const DashboardEntityTableRow({required this.cells, this.cellTaps});

  /// One widget per column. Length must equal `headers.length` in the
  /// surrounding table.
  final List<Widget> cells;

  /// Per-cell tap targets, aligned 1:1 with [cells]. A `null` entry (or a
  /// short list) leaves that cell as a plain non-interactive `TableCell`.
  /// Cells with a non-null callback are wrapped in `TableRowInkWell`, which
  /// shows hover/press feedback scoped to just that cell — the cue that
  /// different columns route to different destinations (invoice number →
  /// invoice, client name → client, etc.).
  final List<VoidCallback?>? cellTaps;
}
