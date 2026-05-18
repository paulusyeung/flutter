import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/recurring_frequency.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/embedded_list_scope.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';
import 'package:admin/ui/core/widgets/vendor_name_label.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_status_pill.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_actions.dart';

/// One row in the recurring expenses list.
///
/// Per UX spec: the narrow secondary line surfaces
/// `Frequency · Next run May 21` so users can plan without opening detail.
class RecurringExpenseListTile extends StatefulWidget {
  const RecurringExpenseListTile({
    super.key,
    required this.recurringExpense,
    required this.columns,
    required this.onTap,
    this.wide = true,
    this.onAction,
    this.onSelectTap,
    this.onLongPress,
    this.selected = false,
    this.urlSelected = false,
    this.selecting = false,
    this.isLast = false,
  });

  final RecurringExpense recurringExpense;
  final List<ColumnDefinition<RecurringExpense>> columns;
  final VoidCallback onTap;
  final bool wide;
  final ValueChanged<RecurringExpenseAction>? onAction;
  final VoidCallback? onSelectTap;
  final VoidCallback? onLongPress;
  final bool selected;

  /// True when this row matches the URL's `:id` (active in master-detail
  /// split view). Distinct from [selected] (multi-select) so the tile
  /// can render an unmistakable accent stripe on the left edge for
  /// URL-active rows without conflating with the bulk-select chip.
  final bool urlSelected;
  final bool selecting;
  final bool isLast;

  @override
  State<RecurringExpenseListTile> createState() =>
      _RecurringExpenseListTileState();
}

class _RecurringExpenseListTileState extends State<RecurringExpenseListTile> {
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
            start: w.urlSelected
                ? BorderSide(color: tokens.accent, width: 3)
                : BorderSide.none,
            bottom: w.isLast
                ? BorderSide.none
                : BorderSide(color: tokens.border),
          ),
        ),
        child: Padding(
          padding: EmbeddedListScope.of(context)
              ? const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14)
              : const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
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
              : EntityActionsPopupButton<RecurringExpenseAction>(
                  icon: Icons.more_horiz,
                  items: RecurringExpenseActions.itemsFor(
                    context,
                    w.recurringExpense,
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
            recurringExpense: w.recurringExpense,
            child: col.cellBuilder(w.recurringExpense, context),
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
    final amountText = amountFmt.format(w.recurringExpense.amount.toDouble());
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
                color: tokens.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            RecurringExpenseStatusPill(
              statusId: w.recurringExpense.calculatedStatusId,
            ),
          ],
        ),
        if (w.onAction != null && !w.selecting) ...[
          const SizedBox(width: 4),
          EntityActionsPopupButton<RecurringExpenseAction>(
            icon: Icons.more_horiz,
            items: RecurringExpenseActions.itemsFor(
              context,
              w.recurringExpense,
              w.onAction!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _identity(BuildContext context, InTheme tokens) {
    final e = widget.recurringExpense;
    final freqKey = kRecurringFrequencyLabelKey[e.frequencyId];
    final freqLabel = freqKey == null ? e.frequencyId : context.tr(freqKey);
    final nextRunFmt = DateFormat.MMMd();
    final nextRunText = e.nextSendDate == null
        ? null
        : nextRunFmt.format(e.nextSendDate!.toDateTime());
    final secondary = nextRunText == null
        ? freqLabel
        : '$freqLabel · ${context.tr('next_run')} $nextRunText';
    final identStyle = const TextStyle(fontWeight: FontWeight.w600);
    final Widget identWidget;
    if (e.number.isNotEmpty) {
      identWidget = Text(
        '#${e.number}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: identStyle,
      );
    } else if (e.vendorId.isNotEmpty) {
      identWidget = VendorNameLabel(
        vendorId: e.vendorId,
        style: identStyle,
        link: true,
      );
    } else {
      identWidget = Text(
        '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: identStyle,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        identWidget,
        const SizedBox(height: 2),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: tokens.ink3, fontSize: 12),
        ),
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
    required this.recurringExpense,
    required this.child,
  });
  final ColumnDefinition<RecurringExpense> column;
  final RecurringExpense recurringExpense;
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
      value: column.valueBuilder?.call(recurringExpense),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}
