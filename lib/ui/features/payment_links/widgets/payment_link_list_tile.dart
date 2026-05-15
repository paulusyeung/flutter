import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';
import 'package:admin/ui/features/payment_links/widgets/payment_link_actions.dart';

/// One row in the Payment Links list. Wide-mode renders the configured
/// columns side-by-side; narrow mode collapses to the identity (name).
/// Same anatomy as [ExpenseCategoryListTile] so the column-slot math
/// stays consistent across settings entities.
class PaymentLinkListTile extends StatelessWidget {
  const PaymentLinkListTile({
    super.key,
    required this.paymentLink,
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

  final PaymentLink paymentLink;
  final List<ColumnDefinition<PaymentLink>> columns;
  final VoidCallback onTap;
  final bool wide;
  final ValueChanged<PaymentLinkAction>? onAction;
  final VoidCallback? onSelectTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: selecting ? onSelectTap : onTap,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? tokens.accentSoft : null,
          border: BorderDirectional(
            bottom: isLast ? BorderSide.none : BorderSide(color: tokens.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: wide ? _wide(context, tokens) : _narrow(context, tokens),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, InTheme tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: kColWMoreMenu,
          child: (onAction == null || selecting)
              ? const SizedBox.shrink()
              : EntityActionsPopupButton<PaymentLinkAction>(
                  icon: Icons.more_horiz,
                  items: PaymentLinkActions.itemsFor(
                    context,
                    paymentLink,
                    onAction!,
                  ),
                ),
        ),
        const SizedBox(width: kColCellGap),
        _leading(),
        const SizedBox(width: kColCellGap),
        for (final col in columns) ...[
          _CellSlot(
            column: col,
            paymentLink: paymentLink,
            child: col.cellBuilder(paymentLink, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        const SizedBox(width: kColWPillSlot),
      ],
    );
  }

  Widget _narrow(BuildContext context, InTheme tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            paymentLink.name.isEmpty ? '—' : paymentLink.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (onAction != null && !selecting) ...[
          const SizedBox(width: 4),
          EntityActionsPopupButton<PaymentLinkAction>(
            icon: Icons.more_horiz,
            items: PaymentLinkActions.itemsFor(
              context,
              paymentLink,
              onAction!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _leading() {
    return LeadingSelectSlot(
      selecting: selecting,
      selected: selected,
      onSelectTap: onSelectTap,
      defaultChild: const SizedBox.shrink(),
    );
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({
    required this.column,
    required this.paymentLink,
    required this.child,
  });
  final ColumnDefinition<PaymentLink> column;
  final PaymentLink paymentLink;
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
      value: column.valueBuilder?.call(paymentLink),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}
