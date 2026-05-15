import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/models/domain/tax_rate.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/line_item_column_config.dart';
import 'package:admin/utils/formatting.dart';

/// Controller for [LineItemTableDesktop]. Hosted by the per-entity edit
/// layout so it can register [flushPending] as a `beforeSave` hook on
/// the VM — guarantees in-flight debounced cell edits land on the
/// draft before the save round-trips.
class LineItemTableDesktopController {
  void Function()? _flushHandler;

  // ignore: use_setters_to_change_properties
  void _attach(void Function() handler) {
    _flushHandler = handler;
  }

  void _detach(void Function() handler) {
    if (identical(_flushHandler, handler)) _flushHandler = null;
  }

  /// Flush every pending debounced cell edit synchronously. Safe to call
  /// when the table isn't mounted (becomes a no-op).
  void flushPending() => _flushHandler?.call();
}

/// Inline-editable desktop line-item table. Each cell is its own editor
/// (product autocomplete, debounced text fields, tax dropdown). Drag
/// handles + per-row overflow menu cover reorder / clone / insert /
/// remove. A synthetic trailing blank row is always rendered so the
/// user can start typing without first clicking Add.
class LineItemTableDesktop extends StatefulWidget {
  const LineItemTableDesktop({
    super.key,
    required this.companyId,
    required this.items,
    required this.onChanged,
    required this.newItemFactory,
    required this.config,
    this.controller,
  });

  final String companyId;
  final List<LineItem> items;
  final ValueChanged<List<LineItem>> onChanged;
  final LineItem Function() newItemFactory;
  final LineItemColumnConfig config;
  final LineItemTableDesktopController? controller;

  @override
  State<LineItemTableDesktop> createState() => _LineItemTableDesktopState();
}

class _LineItemTableDesktopState extends State<LineItemTableDesktop> {
  final List<_RowState> _rows = [];
  bool _suppressSync = false;
  Formatter? _formatter;

  bool get _useComma => _formatter?.settings.useCommaAsDecimalPlace ?? false;

  @override
  void initState() {
    super.initState();
    _syncRows();
    final c = widget.controller;
    if (c != null) c._attach(_flushAll);
    // Prefer the sync cache so first-keystroke parsing already honors
    // the company's `useCommaAsDecimalPlace` setting. Fall back to the
    // async fetch if the cache hasn't been warmed yet (the post-frame
    // path also kicks the cache for next time).
    final services = context.read<Services>();
    _formatter = services.formatterIfReady(widget.companyId);
    if (_formatter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          final fmt = await services.formatterFor(widget.companyId);
          if (!mounted) return;
          if (fmt != _formatter) setState(() => _formatter = fmt);
        } catch (_) {
          // Formatter read failed (statics not loaded yet) — keep default.
        }
      });
    }
  }

  @override
  void didUpdateWidget(LineItemTableDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_flushAll);
      widget.controller?._attach(_flushAll);
    }
    if (!_suppressSync) _syncRows();
  }

  @override
  void dispose() {
    widget.controller?._detach(_flushAll);
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();
    super.dispose();
  }

  /// Reconcile the local `_RowState` list to match `widget.items.length + 1`
  /// (the trailing slot is the synthetic ghost row). Called on every
  /// rebuild to keep controllers / focus nodes in sync with parent state.
  void _syncRows() {
    final desired = widget.items.length + 1;
    while (_rows.length < desired) {
      _rows.add(_RowState());
    }
    while (_rows.length > desired) {
      _rows.removeLast().dispose();
    }
    for (var i = 0; i < widget.items.length; i++) {
      _rows[i].syncFrom(widget.items[i]);
    }
    // Trailing ghost row tracks a fresh empty item so its controllers
    // start blank.
    _rows.last.syncFrom(emptyLineItem());
  }

  void _flushAll() {
    for (final row in _rows) {
      row.flush();
    }
    _commitPending();
  }

  /// Push every row's pending typed text onto the parent items list. The
  /// trailing ghost row is materialized only if it carries any
  /// user-meaningful content.
  void _commitPending() {
    final next = <LineItem>[];
    for (var i = 0; i < widget.items.length; i++) {
      next.add(_rows[i].buildItem(widget.items[i], useComma: _useComma));
    }
    final ghost = _rows.last.buildItem(emptyLineItem(), useComma: _useComma);
    if (!ghost.isBlank) next.add(ghost);
    if (_listsEqual(next, widget.items)) return;
    _suppressSync = true;
    widget.onChanged(next);
    _suppressSync = false;
  }

  bool _listsEqual(List<LineItem> a, List<LineItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Apply a single-row mutation immediately (no debounce). Used by the
  /// product autocomplete (full-row replace), tax cell, overflow menu,
  /// drag reorder.
  void _applyRow(int index, LineItem next) {
    if (index < widget.items.length) {
      final updated = List<LineItem>.from(widget.items);
      updated[index] = next;
      _emit(updated);
    } else {
      // Promoting the ghost row.
      final updated = List<LineItem>.from(widget.items)..add(next);
      _emit(updated);
    }
  }

  void _emit(List<LineItem> next) {
    _suppressSync = true;
    widget.onChanged(next);
    _suppressSync = false;
    // Force a sync so the just-promoted ghost row gets a fresh trailing
    // ghost without waiting for the parent to rebuild.
    setState(_syncRows);
  }

  void _addBlankRow() {
    _flushAll();
    final next = List<LineItem>.from(widget.items)..add(widget.newItemFactory());
    _emit(next);
    // Focus the new row's product cell after the frame settles.
    final newIndex = next.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (newIndex < _rows.length) _rows[newIndex].focusProduct();
    });
  }

  void _remove(int index) {
    if (index >= widget.items.length) return;
    final next = List<LineItem>.from(widget.items)..removeAt(index);
    _emit(next);
  }

  void _clone(int index) {
    if (index >= widget.items.length) return;
    final next = List<LineItem>.from(widget.items)
      ..insert(index + 1, widget.items[index]);
    _emit(next);
  }

  void _insertBelow(int index) {
    final next = List<LineItem>.from(widget.items)
      ..insert(index + 1, widget.newItemFactory());
    _emit(next);
  }

  void _move(int from, int to) {
    if (from >= widget.items.length) return;
    if (to < 0 || to >= widget.items.length) return;
    if (from == to) return;
    final next = List<LineItem>.from(widget.items);
    final row = next.removeAt(from);
    next.insert(to, row);
    _emit(next);
  }

  void _onReorder(int oldIndex, int newIndex) {
    // Skip reorders dragging the synthetic trailing row itself.
    if (oldIndex >= widget.items.length) return;
    var adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    // Drops past the last real row land on the last real position
    // rather than no-op'ing — the visible animation otherwise snaps
    // back, which feels broken.
    if (adjusted >= widget.items.length) {
      adjusted = widget.items.length - 1;
    }
    _move(oldIndex, adjusted);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(widget.companyId),
      builder: (context, snapshot) {
        final company = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeader(onAdd: _addBlankRow),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(InRadii.r2),
                color: tokens.surface,
              ),
              child: Column(
                children: [
                  _ColumnHeader(config: widget.config),
                  Divider(height: 1, color: tokens.border),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _rows.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final isGhost = index >= widget.items.length;
                      final row = _rows[index];
                      final current = isGhost
                          ? widget.newItemFactory()
                          : widget.items[index];
                      return _Row(
                        key: ValueKey(row.id),
                        index: index,
                        isLast: index == _rows.length - 1,
                        isGhost: isGhost,
                        config: widget.config,
                        companyId: widget.companyId,
                        company: company,
                        useComma: _useComma,
                        formatter: _formatter,
                        row: row,
                        currentItem: current,
                        services: services,
                        onCellCommit: (next) {
                          if (isGhost && next.isBlank) return;
                          _applyRow(index, next);
                        },
                        onProductSelected: (product) {
                          final base = isGhost
                              ? widget.newItemFactory()
                              : widget.items[index];
                          final merged = (company?.fillProducts ?? false)
                              ? _mergeProductInto(base, product)
                              : base.copyWith(productKey: product.productKey);
                          _applyRow(index, merged);
                        },
                        onCreateProduct: (query) async {
                          try {
                            final created = await services.products.create(
                              companyId: widget.companyId,
                              draft: emptyProductWith(productKey: query),
                            );
                            if (!context.mounted) return;
                            final base = isGhost
                                ? widget.newItemFactory()
                                : widget.items[index];
                            _applyRow(
                              index,
                              (company?.fillProducts ?? false)
                                  ? _mergeProductInto(base, created)
                                  : base.copyWith(
                                      productKey: created.productKey,
                                    ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Notify.error(
                              context,
                              context.tr('could_not_save'),
                              error: e,
                            );
                          }
                        },
                        onMenuAction: (action) {
                          switch (action) {
                            case _RowAction.clone:
                              _clone(index);
                            case _RowAction.insertBelow:
                              _insertBelow(index);
                            case _RowAction.moveUp:
                              _move(index, index - 1);
                            case _RowAction.moveDown:
                              _move(index, index + 1);
                            case _RowAction.moveTop:
                              _move(index, 0);
                            case _RowAction.moveBottom:
                              _move(index, widget.items.length - 1);
                            case _RowAction.remove:
                              _remove(index);
                          }
                        },
                        onTabFromLastCell: () {
                          if (isGhost) {
                            _addBlankRow();
                          } else if (index == widget.items.length - 1 &&
                              widget.items.last.isBlank == false) {
                            // Falling through into the ghost row — its
                            // first cell receives focus naturally. No-op.
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

LineItem _mergeProductInto(LineItem base, Product product) => base.copyWith(
  productKey: product.productKey,
  notes: product.notes,
  cost: product.cost,
  productCost: product.cost,
  customValue1: product.customValue1,
  customValue2: product.customValue2,
  customValue3: product.customValue3,
  customValue4: product.customValue4,
  taxName1: product.taxName1,
  taxRate1: product.taxRate1,
  taxName2: product.taxName2,
  taxRate2: product.taxRate2,
  taxName3: product.taxName3,
  taxRate3: product.taxRate3,
  taxCategoryId: product.taxId,
);

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: InSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('items'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.ink2,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('add_item'),
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.config});
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
    Widget cell(
      String label, {
      int flex = 1,
      AlignmentGeometry align = Alignment.centerLeft,
    }) =>
        Expanded(
          flex: flex,
          child: Align(
            alignment: align,
            child: Text(label.toUpperCase(), style: style),
          ),
        );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: 10,
      ),
      child: Row(
        children: [
          const SizedBox(width: 24), // drag handle column
          cell(context.tr('item'), flex: 3),
          cell(context.tr('description'), flex: 3),
          cell(context.tr('unit_cost'), align: Alignment.centerRight),
          cell(context.tr('quantity'), align: Alignment.centerRight),
          if (config.showDiscount)
            cell(context.tr('discount'), align: Alignment.centerRight),
          if (config.taxColumnCount >= 1)
            cell(context.tr('tax'), align: Alignment.centerRight),
          cell(context.tr('line_total'), align: Alignment.centerRight),
          const SizedBox(width: 40), // overflow menu column
        ],
      ),
    );
  }
}

/// Per-row mutable state. Survives parent rebuilds so cursor position
/// stays put while typing.
class _RowState {
  _RowState();

  final String id = UniqueKey().toString();
  final TextEditingController product = TextEditingController();
  final TextEditingController notes = TextEditingController();
  final TextEditingController cost = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController discount = TextEditingController();

  final FocusNode productFocus = FocusNode();
  final FocusNode notesFocus = FocusNode();
  final FocusNode costFocus = FocusNode();
  final FocusNode quantityFocus = FocusNode();
  final FocusNode discountFocus = FocusNode();

  Timer? _debounce;
  void Function()? _pendingFlush;

  // Track the values we last wrote *into* the controllers so external
  // syncs (e.g. autocomplete autofill) only rewrite when the parent value
  // genuinely changed — avoids stomping the user's cursor mid-type.
  String _seedProduct = '';
  String _seedNotes = '';
  String _seedCost = '';
  String _seedQty = '';
  String _seedDiscount = '';

  /// Re-seed controllers when the parent's LineItem content changes
  /// (e.g. the user picked a product and we filled cost / notes).
  void syncFrom(LineItem item) {
    final product = item.productKey;
    if (product != _seedProduct && !productFocus.hasFocus) {
      this.product.text = product;
      _seedProduct = product;
    }
    final notes = item.notes;
    if (notes != _seedNotes && !notesFocus.hasFocus) {
      this.notes.text = notes;
      _seedNotes = notes;
    }
    final costText = _seedFor(item.cost);
    if (costText != _seedCost && !costFocus.hasFocus) {
      cost.text = costText;
      _seedCost = costText;
    }
    final qtyText = _seedFor(item.quantity);
    if (qtyText != _seedQty && !quantityFocus.hasFocus) {
      quantity.text = qtyText;
      _seedQty = qtyText;
    }
    final discText = _seedFor(item.discount);
    if (discText != _seedDiscount && !discountFocus.hasFocus) {
      discount.text = discText;
      _seedDiscount = discText;
    }
  }

  String _seedFor(Decimal d) => d == Decimal.zero ? '' : d.toString();

  /// Build a LineItem reflecting the current controller text. Used to
  /// commit the row on save / focus-out / explicit flush. The
  /// [useComma] flag honours the company's `use_comma_as_decimal_place`
  /// setting so EU users typing `1,50` produce 1.5 rather than 0.
  LineItem buildItem(LineItem base, {bool useComma = false}) {
    return base.copyWith(
      productKey: product.text.trim(),
      notes: notes.text,
      cost: parseDecimal(cost.text, useCommaAsDecimalPlace: useComma) ??
          Decimal.zero,
      quantity:
          parseDecimal(quantity.text, useCommaAsDecimalPlace: useComma) ??
              Decimal.one,
      discount:
          parseDecimal(discount.text, useCommaAsDecimalPlace: useComma) ??
              Decimal.zero,
    );
  }

  void scheduleCommit(VoidCallback commit) {
    _pendingFlush = commit;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _pendingFlush?.call();
      _pendingFlush = null;
    });
  }

  void flush() {
    _debounce?.cancel();
    final pending = _pendingFlush;
    _pendingFlush = null;
    pending?.call();
  }

  void focusProduct() {
    productFocus.requestFocus();
    product.selection = TextSelection(
      baseOffset: 0,
      extentOffset: product.text.length,
    );
  }

  void dispose() {
    _debounce?.cancel();
    product.dispose();
    notes.dispose();
    cost.dispose();
    quantity.dispose();
    discount.dispose();
    productFocus.dispose();
    notesFocus.dispose();
    costFocus.dispose();
    quantityFocus.dispose();
    discountFocus.dispose();
  }
}

enum _RowAction {
  clone,
  insertBelow,
  moveUp,
  moveDown,
  moveTop,
  moveBottom,
  remove,
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.index,
    required this.isLast,
    required this.isGhost,
    required this.config,
    required this.companyId,
    required this.company,
    required this.useComma,
    required this.formatter,
    required this.row,
    required this.currentItem,
    required this.services,
    required this.onCellCommit,
    required this.onProductSelected,
    required this.onCreateProduct,
    required this.onMenuAction,
    required this.onTabFromLastCell,
  });

  final int index;
  final bool isLast;
  final bool isGhost;
  final LineItemColumnConfig config;
  final String companyId;
  final Company? company;
  final bool useComma;
  final Formatter? formatter;
  final _RowState row;
  final LineItem currentItem;
  final Services services;
  final ValueChanged<LineItem> onCellCommit;
  final ValueChanged<Product> onProductSelected;
  final ValueChanged<String> onCreateProduct;
  final ValueChanged<_RowAction> onMenuAction;
  final VoidCallback onTabFromLastCell;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;

    void commitNow() {
      onCellCommit(row.buildItem(currentItem, useComma: useComma));
    }

    void scheduleCommit() {
      row.scheduleCommit(commitNow);
    }

    Widget endTotalCell() {
      final cost =
          parseDecimal(row.cost.text, useCommaAsDecimalPlace: useComma) ??
              Decimal.zero;
      final qty =
          parseDecimal(row.quantity.text, useCommaAsDecimalPlace: useComma) ??
              Decimal.one;
      final gross = cost * qty;
      // Display via the company Formatter when available so the line
      // total honors currency, thousands separator, and decimal place
      // count (per CLAUDE.md). Falls back to a raw `Decimal.toString`
      // before the formatter resolves.
      final display = gross == Decimal.zero
          ? '—'
          : (formatter?.money(gross, zeroIsNull: true) ?? gross.toString());
      return Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            display,
            style: GoogleFonts.jetBrainsMono(
              color: tokens.ink,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    return FocusTraversalGroup(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.lg(context),
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isGhost
                ? const SizedBox(width: 24)
                : ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      color: tokens.ink3,
                      size: 20,
                    ),
                  ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ProductCell(
                  companyId: companyId,
                  controller: row.product,
                  focusNode: row.productFocus,
                  onSelected: onProductSelected,
                  onCreateRequested: onCreateProduct,
                  onCommitText: scheduleCommit,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TextCell(
                  controller: row.notes,
                  focusNode: row.notesFocus,
                  onChanged: scheduleCommit,
                  hintKey: 'description',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _NumericCell(
                  controller: row.cost,
                  focusNode: row.costFocus,
                  onChanged: scheduleCommit,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _NumericCell(
                  controller: row.quantity,
                  focusNode: row.quantityFocus,
                  onChanged: scheduleCommit,
                  // Quantity is the last typing cell when discount is
                  // hidden — tab forward then promotes the ghost.
                  onTabForward: !config.showDiscount && isGhost
                      ? onTabFromLastCell
                      : null,
                ),
              ),
            ),
            if (config.showDiscount)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _NumericCell(
                    controller: row.discount,
                    focusNode: row.discountFocus,
                    onChanged: scheduleCommit,
                    // Discount is the last typing cell when shown.
                    onTabForward: isGhost ? onTabFromLastCell : null,
                  ),
                ),
              ),
            if (config.taxColumnCount >= 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TaxCell(
                    companyId: companyId,
                    services: services,
                    useComma: useComma,
                    initialName: currentItem.taxName1,
                    initialRate: currentItem.taxRate1,
                    onSelected: (taxRate) {
                      onCellCommit(
                        row
                            .buildItem(currentItem, useComma: useComma)
                            .copyWith(
                              taxName1: taxRate?.name ?? '',
                              taxRate1: taxRate == null
                                  ? Decimal.zero
                                  : Decimal.parse(taxRate.rate.toString()),
                            ),
                      );
                    },
                  ),
                ),
              ),
            endTotalCell(),
            SizedBox(
              width: 40,
              child: isGhost
                  ? const SizedBox.shrink()
                  : PopupMenuButton<_RowAction>(
                      tooltip: context.tr('more'),
                      icon: Icon(Icons.more_vert, size: 18, color: tokens.ink3),
                      onSelected: onMenuAction,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _RowAction.clone,
                          child: Text(context.tr('clone')),
                        ),
                        PopupMenuItem(
                          value: _RowAction.insertBelow,
                          child: Text(context.tr('insert_below')),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _RowAction.moveUp,
                          child: Text(context.tr('move_up')),
                        ),
                        PopupMenuItem(
                          value: _RowAction.moveDown,
                          child: Text(context.tr('move_down')),
                        ),
                        PopupMenuItem(
                          value: _RowAction.moveTop,
                          child: Text(context.tr('move_top')),
                        ),
                        PopupMenuItem(
                          value: _RowAction.moveBottom,
                          child: Text(context.tr('move_bottom')),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _RowAction.remove,
                          child: Text(context.tr('remove')),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Inline cell: small bordered text field with no label, dense padding.
class _TextCell extends StatelessWidget {
  const _TextCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hintKey,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final String? hintKey;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintKey == null ? null : context.tr(hintKey!),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        border: const UnderlineInputBorder(),
      ),
    );
  }
}

class _NumericCell extends StatelessWidget {
  const _NumericCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onTabForward,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback? onTabForward;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: GoogleFonts.jetBrainsMono(
        color: tokens.ink,
        fontSize: 13,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: UnderlineInputBorder(),
      ),
    );
    if (onTabForward == null) return field;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.tab) {
          return KeyEventResult.ignored;
        }
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored;
        }
        // Last cell tab-forward — tell the host to add a new row.
        onTabForward?.call();
        return KeyEventResult.ignored;
      },
      child: field,
    );
  }
}

/// Inline product picker. Server-side searched via
/// `services.products.watchPage(search:)`, debounced 200 ms. Includes a
/// "Create '`<query>`'" tile when the typed key matches no product.
class _ProductCell extends StatefulWidget {
  const _ProductCell({
    required this.companyId,
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    required this.onCreateRequested,
    required this.onCommitText,
  });

  final String companyId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<Product> onSelected;
  final ValueChanged<String> onCreateRequested;
  final VoidCallback onCommitText;

  @override
  State<_ProductCell> createState() => _ProductCellState();
}

class _ProductCellState extends State<_ProductCell> {
  Timer? _searchDebounce;
  String _query = '';
  List<Product> _results = const [];
  StreamSubscription<List<Product>>? _sub;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _runSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () async {
      await _sub?.cancel();
      if (!mounted) return;
      final services = context.read<Services>();
      _sub = services.products
          .watchPage(
            companyId: widget.companyId,
            search: query.isEmpty ? null : query,
            loadedPages: 1,
          )
          .listen((rows) {
        if (!mounted) return;
        setState(() {
          _query = query;
          _results = rows;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_ProductOption>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode,
      displayStringForOption: (opt) =>
          opt is _ProductExisting ? opt.product.productKey : opt.label,
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (query != _query) _runSearch(query);
        final list = <_ProductOption>[
          for (final p in _results.take(20)) _ProductExisting(p),
        ];
        if (query.isNotEmpty &&
            !_results.any((p) =>
                p.productKey.toLowerCase() == query.toLowerCase())) {
          list.add(_ProductCreate(query));
        }
        return list;
      },
      onSelected: (opt) {
        if (opt is _ProductExisting) {
          widget.onSelected(opt.product);
        } else if (opt is _ProductCreate) {
          widget.onCreateRequested(opt.label);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => widget.onCommitText(),
          onSubmitted: (_) => onFieldSubmitted(),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: context.tr('product'),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: const UnderlineInputBorder(),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: context.inTheme.ink3,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final tokens = context.inTheme;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(InRadii.r2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final opt = options.elementAt(i);
                  if (opt is _ProductCreate) {
                    return InkWell(
                      onTap: () => onSelected(opt),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: InSpacing.md(context),
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: tokens.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.tr('create')} "${opt.label}"',
                                style: TextStyle(
                                  color: tokens.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final product = (opt as _ProductExisting).product;
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: InSpacing.md(context),
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.productKey,
                            style: TextStyle(
                              color: tokens.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (product.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                product.notes.split('\n').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tokens.ink3,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

sealed class _ProductOption {
  String get label;
}

class _ProductExisting implements _ProductOption {
  _ProductExisting(this.product);
  final Product product;
  @override
  String get label => product.productKey;
}

class _ProductCreate implements _ProductOption {
  _ProductCreate(this.label);
  @override
  final String label;
}

/// Inline tax dropdown — small list (rarely > 30 rates), so we materialize
/// the watch and feed an `Autocomplete<TaxRate>` for filterable picking.
class _TaxCell extends StatefulWidget {
  const _TaxCell({
    required this.companyId,
    required this.services,
    required this.useComma,
    required this.initialName,
    required this.initialRate,
    required this.onSelected,
  });

  final String companyId;
  final Services services;
  final bool useComma;
  final String initialName;
  final Decimal initialRate;
  final ValueChanged<TaxRate?> onSelected;

  @override
  State<_TaxCell> createState() => _TaxCellState();
}

class _TaxCellState extends State<_TaxCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _displayFor(widget.initialName, widget.initialRate, widget.useComma),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_TaxCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (widget.initialName != oldWidget.initialName ||
            widget.initialRate != oldWidget.initialRate ||
            widget.useComma != oldWidget.useComma)) {
      _controller.text =
          _displayFor(widget.initialName, widget.initialRate, widget.useComma);
    }
  }

  static String _displayFor(String name, Decimal rate, bool useComma) {
    if (name.isEmpty) return '';
    final raw = rate.toString();
    final localized = useComma ? raw.replaceAll('.', ',') : raw;
    return '$name $localized%';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return StreamBuilder<List<TaxRate>>(
      stream: widget.services.taxRates.watchAll(companyId: widget.companyId),
      builder: (context, snapshot) {
        final rates = snapshot.data ?? const <TaxRate>[];
        return RawAutocomplete<_TaxOption>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (opt) => opt.display,
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? rates
                : rates.where((r) => r.name.toLowerCase().contains(q));
            return [
              const _TaxOption.none(),
              for (final r in filtered) _TaxOption.rate(r),
            ];
          },
          onSelected: (opt) {
            widget.onSelected(opt.rate);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onFieldSubmitted(),
              textAlign: TextAlign.right,
              readOnly: rates.isEmpty,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: context.tr('tax'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: const UnderlineInputBorder(),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: tokens.ink3,
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(InRadii.r2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 280,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final opt = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(opt),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: InSpacing.md(context),
                          vertical: 10,
                        ),
                        child: Text(
                          opt.displayLocalized(widget.useComma).isEmpty
                              ? context.tr('none')
                              : opt.displayLocalized(widget.useComma),
                          style: TextStyle(
                            color: tokens.ink,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaxOption {
  const _TaxOption.none() : rate = null;
  const _TaxOption.rate(TaxRate this.rate);
  final TaxRate? rate;
  String get display => rate == null ? '' : '${rate!.name} ${rate!.rate}%';

  /// Display formatted with the company's decimal separator. EU users
  /// see `19,0%` instead of `19.0%`.
  String displayLocalized(bool useComma) {
    if (rate == null) return '';
    final raw = rate!.rate.toString();
    final localized = useComma ? raw.replaceAll('.', ',') : raw;
    return '${rate!.name} $localized%';
  }
}

/// Convenience to mint a fresh Product carrying just a productKey — used
/// by the autocomplete's "Create '`<query>`'" tile. Pulls every other
/// field from the Product domain defaults.
Product emptyProductWith({required String productKey}) {
  final now = DateTime.now().toUtc();
  return Product(
    id: '',
    productKey: productKey,
    notes: '',
    cost: Decimal.zero,
    price: Decimal.zero,
    quantity: Decimal.zero,
    maxQuantity: Decimal.zero,
    productImage: '',
    inStockQuantity: Decimal.zero,
    stockNotification: false,
    stockNotificationThreshold: Decimal.zero,
    taxName1: '',
    taxRate1: Decimal.zero,
    taxName2: '',
    taxRate2: Decimal.zero,
    taxName3: '',
    taxRate3: Decimal.zero,
    taxId: '',
    customValue1: '',
    customValue2: '',
    customValue3: '',
    customValue4: '',
    updatedAt: now,
    createdAt: now,
    archivedAt: null,
    isDeleted: false,
  );
}
