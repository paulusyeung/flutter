import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_column_config.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_edit_dialog.dart';

/// Desktop-mode line-item table. Each row renders the identity + key
/// fields in a compact table layout; tap opens the shared
/// [showLineItemEditDialog] for the full field set (same UX as mobile).
///
/// M3 first cut intentionally keeps editing in the dialog rather than
/// inline. M3.5 / M4 will add inline-editable cells (product autocomplete
/// in the first column, debounced text fields elsewhere) — the dialog
/// remains the fallback for the long-tail fields. Drag-handle reorder is
/// supported via [ReorderableListView].
class LineItemTableDesktop extends StatelessWidget {
  const LineItemTableDesktop({
    super.key,
    required this.items,
    required this.onChanged,
    required this.newItemFactory,
    required this.config,
  });

  final List<LineItem> items;
  final ValueChanged<List<LineItem>> onChanged;
  final LineItem Function() newItemFactory;
  final LineItemColumnConfig config;

  Future<void> _openEditor(BuildContext context, int index) async {
    final result = await showLineItemEditDialog(
      context,
      initial: items[index],
      config: config,
    );
    if (result == null) return;
    final next = List<LineItem>.from(items)..[index] = result;
    onChanged(next);
  }

  void _remove(int index) {
    final next = List<LineItem>.from(items)..removeAt(index);
    onChanged(next);
  }

  void _add() {
    final next = List<LineItem>.from(items)..add(newItemFactory());
    onChanged(next);
  }

  void _onReorder(int oldIndex, int newIndex) {
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final next = List<LineItem>.from(items);
    final row = next.removeAt(oldIndex);
    next.insert(adjusted, row);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(config: config),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(InRadii.r2),
            color: tokens.surface,
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              return _Row(
                key: ValueKey('line_item_$index'),
                item: items[index],
                index: index,
                isLast: index == items.length - 1,
                config: config,
                onTap: () => _openEditor(context, index),
                onRemove: () => _remove(index),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: InSpacing.md(context)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              icon: const Icon(Icons.add),
              label: Text(context.tr('add_item')),
              onPressed: _add,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config});
  final LineItemColumnConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: tokens.ink3,
      letterSpacing: 0.4,
    );
    Widget cell(String label, {int flex = 1, ColumnAlign align = ColumnAlign.start}) =>
        Expanded(
          flex: flex,
          child: Align(
            alignment: align == ColumnAlign.end
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(label.toUpperCase(), style: style),
          ),
        );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          const SizedBox(width: 24), // drag handle column
          cell(context.tr('item'), flex: 3),
          cell(context.tr('unit_cost'), align: ColumnAlign.end),
          cell(context.tr('quantity'), align: ColumnAlign.end),
          if (config.showDiscount)
            cell(context.tr('discount'), align: ColumnAlign.end),
          if (config.taxColumnCount >= 1)
            cell(context.tr('tax'), align: ColumnAlign.end),
          cell(context.tr('line_total'), align: ColumnAlign.end),
          const SizedBox(width: 40), // remove button column
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
    required this.config,
    required this.onTap,
    required this.onRemove,
  });

  final LineItem item;
  final int index;
  final bool isLast;
  final LineItemColumnConfig config;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final fmt = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final gross = item.gross;
    final identity = item.productKey.isEmpty
        ? (item.notes.isEmpty ? context.tr('untitled') : item.notes.split('\n').first)
        : item.productKey;
    final txt = TextStyle(color: tokens.ink, fontSize: 13);
    final mono = GoogleFonts.jetBrainsMono(
      color: tokens.ink,
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget endCell(String text, {int flex = 1}) => Expanded(
          flex: flex,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(text, style: mono),
          ),
        );
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.lg(context),
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator,
                color: tokens.ink3,
                size: 20,
              ),
            ),
            const SizedBox(width: 0),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    identity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: txt.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (item.productKey.isNotEmpty && item.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.ink3, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            endCell(fmt.format(item.cost.toDouble())),
            endCell(item.quantity.toString()),
            if (config.showDiscount)
              endCell(item.discount == Decimal.zero
                  ? '—'
                  : item.discount.toString()),
            if (config.taxColumnCount >= 1)
              endCell(item.taxName1.isEmpty
                  ? '—'
                  : '${item.taxName1} ${item.taxRate1}%'),
            endCell(fmt.format(gross.toDouble())),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: tokens.ink3,
                onPressed: onRemove,
                tooltip: context.tr('remove'),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ColumnAlign { start, end }
