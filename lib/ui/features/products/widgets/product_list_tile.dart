import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';

/// Actions a product row can fire from its trailing menu. View/Edit map
/// to navigation; Archive/Restore call repository mutations.
enum ProductRowAction { view, edit, archive, restore }

/// One row in the products list.
///
/// Wide-mode layout: leading `…` actions slot + (avatar/checkbox slot) +
/// column cells + reserved pill slot, all aligned with
/// [EntityListColumnHeaders] via the shared constants in
/// `entity_list_constants.dart`.
///
/// Narrow-mode layout: stacked card with selection checkbox + product key
/// (+ notes subtitle) + price + status pill + actions menu. No column cells
/// — the narrow tile picks the two highest-signal fields directly so it
/// renders cleanly on small screens.
class ProductListTile extends StatefulWidget {
  const ProductListTile({
    super.key,
    required this.product,
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

  final Product product;

  /// Columns to render in wide mode. Ignored when [wide] is false — narrow
  /// mode renders a fixed identity + price pair.
  final List<ColumnDefinition<Product>> columns;
  final VoidCallback onTap;

  /// True for the wide table-style row; false for the narrow stacked tile.
  final bool wide;

  /// Trailing action menu callback. When null no menu renders (e.g. while
  /// in multiselect mode).
  final ValueChanged<ProductRowAction>? onAction;

  /// Tap handler for the leading select target. When non-null the row
  /// participates in multi-select; the leading slot reveals a checkbox on
  /// hover and renders as a checkbox while [selecting] is true.
  final VoidCallback? onSelectTap;

  /// Long-press anywhere on the row enters / toggles multi-select. Touch
  /// entry point for tablets; desktop users go through [onSelectTap].
  final VoidCallback? onLongPress;

  /// True when this row is part of the active multi-selection.
  final bool selected;

  /// True when the screen is in selection mode (any rows selected). All
  /// rows render their leading slot as the selection checkbox during this
  /// state, regardless of [selected].
  final bool selecting;

  /// True for the last row in a list. Suppresses the bottom hairline so
  /// the list doesn't end with a stray divider above empty space — same
  /// contract as `ClientListTile.isLast`.
  final bool isLast;

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
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
        // Leading `…` actions slot. Hidden in selection mode.
        SizedBox(
          width: kColWMoreMenu,
          child: (w.onAction == null || w.selecting)
              ? const SizedBox.shrink()
              : _ProductActionMenu(product: w.product, onAction: w.onAction!),
        ),
        const SizedBox(width: kColCellGap),
        _leading(),
        const SizedBox(width: kColCellGap),
        for (final col in w.columns) ...[
          _CellSlot(
            column: col,
            product: w.product,
            child: col.cellBuilder(w.product, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        // Reserved pill slot so the row's right edge matches the header's.
        // Empty for now — future product status badge slots in here.
        const SizedBox(width: kColWPillSlot),
      ],
    );
  }

  Widget _narrow(BuildContext context, InTheme tokens) {
    final w = widget;
    final priceFmt = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(),
        const SizedBox(width: 12),
        Expanded(child: _identity(context, tokens)),
        const SizedBox(width: 12),
        Text(
          priceFmt.format(w.product.price.toDouble()),
          style: TextStyle(
            color: tokens.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (w.onAction != null && !w.selecting) ...[
          const SizedBox(width: 4),
          _ProductActionMenu(product: w.product, onAction: w.onAction!),
        ],
      ],
    );
  }

  Widget _identity(BuildContext context, InTheme tokens) {
    final p = widget.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          p.productKey.isEmpty ? '—' : p.productKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (p.notes.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            p.notes,
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
    required this.product,
    required this.child,
  });
  final ColumnDefinition<Product> column;
  final Product product;
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
      value: column.valueBuilder?.call(product),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}

class _ProductActionMenu extends StatelessWidget {
  const _ProductActionMenu({required this.product, required this.onAction});

  final Product product;
  final ValueChanged<ProductRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    final canArchive = product.archivedAt == null && !product.isDeleted;
    final canRestore = product.archivedAt != null || product.isDeleted;
    return PopupMenuButton<ProductRowAction>(
      tooltip: context.tr('more_actions'),
      icon: const Icon(Icons.more_horiz, size: 18),
      padding: EdgeInsets.zero,
      onSelected: onAction,
      itemBuilder: (context) => <PopupMenuEntry<ProductRowAction>>[
        PopupMenuItem(
          value: ProductRowAction.view,
          child: Text(context.tr('view')),
        ),
        PopupMenuItem(
          value: ProductRowAction.edit,
          child: Text(context.tr('edit')),
        ),
        if (canArchive)
          PopupMenuItem(
            value: ProductRowAction.archive,
            child: Text(context.tr('archive')),
          ),
        if (canRestore)
          PopupMenuItem(
            value: ProductRowAction.restore,
            child: Text(context.tr('restore')),
          ),
      ],
    );
  }
}
