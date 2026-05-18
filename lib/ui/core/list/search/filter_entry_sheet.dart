import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_chip_data.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';
import 'package:admin/ui/core/list/search/segment_menu.dart';
import 'package:admin/ui/core/list/search/token_search_controller.dart';

/// Narrow-mode editor for the token search field. Pushed as a full-screen
/// modal page from [TokenSearchField] on phone widths. Chips + input occupy
/// the top of the page; the suggestion list fills the rest. Done button +
/// system back close the page.
class FilterEntrySheet extends StatefulWidget {
  const FilterEntrySheet({
    required this.vm,
    required this.filterKeys,
    required this.hintKey,
    super.key,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> filterKeys;
  final String hintKey;

  @override
  State<FilterEntrySheet> createState() => _FilterEntrySheetState();
}

class _FilterEntrySheetState extends State<FilterEntrySheet> {
  late final TokenSearchController _controller;
  String _committedSearch = '';

  @override
  void initState() {
    super.initState();
    _controller = TokenSearchController(
      vm: widget.vm,
      filterKeys: widget.filterKeys,
      initialText: widget.vm.search,
    );
    _controller.text.addListener(_onChange);
    widget.vm.addListener(_onChange);
    // Pin changes touch neither text nor vm — rebuild so the always-built
    // menu switches to value mode for a pinned checkbox key.
    _controller.pinRevision.addListener(_onChange);
    // Autofocus the input so the keyboard appears the moment the user
    // arrives — they tapped the summary specifically to edit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FilterEntrySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirror of `TokenSearchField.didUpdateWidget` — see that file for
    // the full rationale. The sheet can outlive a `customFields` change
    // in Settings; without this sync the controller would keep the
    // empty-label `CustomFieldFilterKey`s and the pill wouldn't render
    // after a custom value was picked.
    if (!identical(oldWidget.filterKeys, widget.filterKeys)) {
      _controller.filterKeys = widget.filterKeys;
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onChange);
    _controller.text.removeListener(_onChange);
    _controller.pinRevision.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    _controller.invalidateParse();
    // Typing exits a pinned chip-edit — text owns the menu mode again.
    if (_controller.text.text.isNotEmpty) {
      _controller.clearPinnedValueKey();
    }
    if (_controller.text.text != widget.vm.search &&
        !_controller.focus.hasFocus &&
        widget.vm.search != _committedSearch) {
      // External clear-all reset the search — reflect that visually.
      _controller.text.text = widget.vm.search;
    }
    setState(() {});
  }

  Future<void> _onSelectValue(FilterKey key, FilterValueSuggestion value) {
    // The narrow-mode sheet is a dedicated batch-edit experience
    // (full-screen modal), so we STAY in value mode after a pick — the
    // user picks multiple values, then taps back to close. Unlike wide
    // mode, there's no overlay to dismiss; dismissal happens via the
    // AppBar's back button.
    return _controller.selectValue(
      key,
      value,
      context,
      beforeAwait: () => _controller.focus.requestFocus(),
    );
  }

  /// Checkbox half of the split action — toggle and stay in the sheet
  /// (the sheet is already a batch-edit surface; same as `_onSelectValue`
  /// but routed through the sticky toggle for symmetry with wide mode).
  Future<void> _onToggleValue(FilterKey key, FilterValueSuggestion value) {
    _controller.focus.requestFocus();
    return _controller.toggleValueSticky(key, value, context);
  }

  /// Row-label half — pick only this value, then close the sheet
  /// (pick-one-and-done, consistent with wide mode closing its overlay).
  Future<void> _onPickExclusive(
    FilterKey key,
    FilterValueSuggestion value,
  ) async {
    await _controller.selectValueExclusive(key, value, context);
    if (mounted) unawaited(Navigator.of(context).maybePop());
  }

  void _onCommitFreeText(String value) {
    _controller.commitFreeText(value);
    _committedSearch = value;
    _controller.focus.requestFocus();
  }

  /// Mirror of wide-mode `_onSelectKey`. Checkbox keys (State / Status)
  /// open their value picker via the pin — no `<key>:` prefix written into
  /// the sheet's input. Other keys keep the typed prefix.
  void _onSelectKey(FilterKey key) {
    if (key.checkboxMultiSelect) {
      _controller.pinValueKey(key);
      return;
    }
    _controller.selectKey(key);
  }

  /// Mirror of wide-mode `_onChipTap` — see [TokenSearchField]. Drops
  /// into value mode for the chip's key so the user can change it.
  void _onChipTap(ActiveFilterChip chip) {
    final key = chip.key;
    if (key.checkboxMultiSelect) {
      // Checkbox keys manage their set in the (always-open) sheet picker;
      // never pre-remove — an aggregate chip has no single clicked value.
      // Pin the key instead of writing `<key>:` into the input (no stray
      // prefix in the sheet's field).
      _controller.pinValueKey(key);
      return;
    }
    if (!key.singleValue) {
      unawaited(key.removeValue(widget.vm, chip.rawValues.single));
    }
    _controller.selectKey(key);
  }

  /// Comparator / value segment tap → the dedicated [SegmentMenu] in a
  /// bottom sheet. Commits straight through the key; never touches the
  /// search text controller.
  void _openSegmentSheet(ActiveFilterChip chip, SegmentKind kind) {
    final key = chip.key;
    if (key is! ComparableFilterKey) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SegmentMenu(
          vm: widget.vm,
          filterKey: key,
          kind: kind,
          currentWire: chip.rawValues.single,
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  /// Pick-op-first flow — see the wide-mode `_onPickOp` for the rationale.
  /// Writes `<key>:<symbol>` to the input and keeps focus so the user
  /// types the value next.
  void _onPickOp(FilterKey key, FilterOp op) {
    final symbol = filterOpSymbol(op);
    final next = '${key.id}:$symbol';
    _controller.text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _controller.focus.requestFocus();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    // The suggestion list is always visible inside the sheet, so
    // arrow keys + Enter always navigate it.
    return _controller.handleArrowEnterBackspace(
      event,
      suggestionsActive: true,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final active = _controller.activeChips(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.tr('close'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(context.tr('filters')),
        actions: [
          if (widget.vm.hasActiveFilters)
            TextButton(
              onPressed: () {
                widget.vm.clearAllFilters();
                _controller.text.clear();
              },
              child: Text(context.tr('clear_all')),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: tokens.surface,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(InRadii.r1),
                border: Border.all(color: tokens.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in active)
                    FilterTokenChip(
                      token: c.token,
                      onRemove: () => _controller.removeChip(c, context),
                      onTap: () => _onChipTap(c),
                      // Comparator / value segments open the same
                      // dedicated SegmentMenu as wide mode, hosted in a
                      // bottom sheet (no anchor math). Commits via
                      // changeOp / addValue — never writes search text.
                      onComparatorTap: c.key.supportedOps.isNotEmpty
                          ? (_) => _openSegmentSheet(c, SegmentKind.comparator)
                          : null,
                      onValueTap: c.key.supportedOps.isNotEmpty
                          ? (_) => _openSegmentSheet(c, SegmentKind.value)
                          : null,
                    ),
                  IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80),
                      child: Focus(
                        onKeyEvent: _handleKey,
                        child: TextField(
                          controller: _controller.text,
                          focusNode: _controller.focus,
                          decoration: InputDecoration(
                            hintText: active.isEmpty
                                ? context.tr(widget.hintKey)
                                : null,
                            // See `token_search_field.dart` for why every
                            // state-specific border has to be overridden —
                            // the global `InputDecorationTheme` paints a
                            // rounded outline on the empty input otherwise.
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            isCollapsed: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FilterSuggestionMenu(
              vm: widget.vm,
              keys: widget.filterKeys,
              parse: _controller.parseInput(),
              controller: _controller.suggestions,
              onSelectKey: _onSelectKey,
              onSelectValue: _onSelectValue,
              onToggleValue: _onToggleValue,
              onPickExclusive: _onPickExclusive,
              onPickOp: _onPickOp,
              onCommitFreeText: _onCommitFreeText,
              maxHeight: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
