import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_status_pill.dart';

/// One row in the invoices list. Wide-mode mirrors `ExpenseListTile`'s
/// anatomy. Narrow-mode shows the invoice number + client as identity, with
/// the balance + status pill on the trailing side.
class InvoiceListTile extends StatefulWidget {
  const InvoiceListTile({
    super.key,
    required this.invoice,
    required this.columns,
    required this.onTap,
    this.wide = true,
    this.onAction,
    this.onSelectTap,
    this.onLongPress,
    this.selected = false,
    this.selecting = false,
    this.isLast = false,
  });

  final Invoice invoice;
  final List<ColumnDefinition<Invoice>> columns;
  final VoidCallback onTap;
  final bool wide;
  final ValueChanged<InvoiceAction>? onAction;
  final VoidCallback? onSelectTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;
  final bool isLast;

  @override
  State<InvoiceListTile> createState() => _InvoiceListTileState();
}

class _InvoiceListTileState extends State<InvoiceListTile> {
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final tokens = context.inTheme;
    return InkWell(
      onTap: w.selecting ? w.onSelectTap : w.onTap,
      onLongPress: w.onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: w.selected ? tokens.accentSoft : null,
          border: BorderDirectional(
            bottom: w.isLast
                ? BorderSide.none
                : BorderSide(color: tokens.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: w.wide ? _wide(context, tokens) : _narrow(context, tokens),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, InTheme tokens) {
    final w = widget;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: kColWMoreMenu,
          child: (w.onAction == null || w.selecting)
              ? const SizedBox.shrink()
              : EntityActionsPopupButton<InvoiceAction>(
                  icon: Icons.more_horiz,
                  items: InvoiceActions.itemsFor(
                    context,
                    w.invoice,
                    w.onAction!,
                  ),
                ),
        ),
        const SizedBox(width: kColCellGap),
        _leading(),
        const SizedBox(width: kColCellGap),
        for (final col in w.columns) ...[
          _CellSlot(
            column: col,
            invoice: w.invoice,
            child: col.cellBuilder(w.invoice, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        const SizedBox(width: kColWPillSlot),
      ],
    );
  }

  Widget _narrow(BuildContext context, InTheme tokens) {
    final w = widget;
    final amountFmt = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final amountText = amountFmt.format(w.invoice.balanceOrAmount.toDouble());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(),
        const SizedBox(width: 12),
        Expanded(child: _identity(context, tokens)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountText,
              style: TextStyle(
                color: w.invoice.isPastDue ? tokens.overdue : tokens.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            InvoiceStatusPill(statusId: w.invoice.calculatedStatusId),
          ],
        ),
        if (w.onAction != null && !w.selecting) ...[
          const SizedBox(width: 4),
          EntityActionsPopupButton<InvoiceAction>(
            icon: Icons.more_horiz,
            items: InvoiceActions.itemsFor(context, w.invoice, w.onAction!),
          ),
        ],
      ],
    );
  }

  Widget _identity(BuildContext context, InTheme tokens) {
    final i = widget.invoice;
    final ident = i.number.isEmpty ? '—' : '#${i.number}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ident,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (i.clientId.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            i.clientId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.ink3, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _leading() {
    final w = widget;
    return LeadingSelectSlot(
      selecting: w.selecting,
      selected: w.selected,
      onSelectTap: w.onSelectTap,
      defaultChild: const SizedBox.shrink(),
    );
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({
    required this.column,
    required this.invoice,
    required this.child,
  });
  final ColumnDefinition<Invoice> column;
  final Invoice invoice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aligned = Align(
      alignment: column.align == ColumnAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
    final cell = CellCopyHover(
      value: column.valueBuilder?.call(invoice),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}
