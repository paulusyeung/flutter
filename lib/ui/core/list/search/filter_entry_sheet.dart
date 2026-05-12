import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';
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
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    _controller.invalidateParse();
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

  void _onCommitFreeText(String value) {
    _controller.commitFreeText(value);
    _committedSearch = value;
    _controller.focus.requestFocus();
  }

  /// Mirror of wide-mode `_onChipTap` — see [TokenSearchField]. Drops
  /// into value mode for the chip's key so the user can change it.
  void _onChipTap(FilterToken token) {
    final key = _controller.keyById(token.keyId);
    if (key == null) return;
    if (!key.singleValue) {
      unawaited(key.removeValue(widget.vm, token.rawValue));
    }
    _controller.selectKey(key);
  }

  /// Pick-op-first flow — see the wide-mode `_onPickOp` for the rationale.
  /// Writes `<key>:<symbol>` to the input and keeps focus so the user
  /// types the value next.
  void _onPickOp(FilterKey key, FilterOp op) {
    final symbol = op == FilterOp.gt ? '>' : '<';
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
    final active = _controller.activeTokens(context);

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
                  for (final t in active)
                    FilterTokenChip(
                      token: t,
                      onRemove: () => _controller.removeToken(t),
                      onTap: () => _onChipTap(t),
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
              onSelectKey: _controller.selectKey,
              onSelectValue: _onSelectValue,
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
