import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';

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
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.vm.search);
    _controller.addListener(_onChange);
    widget.vm.addListener(_onChange);
    // Autofocus the input so the keyboard appears the moment the user
    // arrives — they tapped the summary specifically to edit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onChange);
    _controller
      ..removeListener(_onChange)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() {
    if (_controller.text != widget.vm.search &&
        !_focusNode.hasFocus &&
        widget.vm.search != _committedSearch) {
      // External clear-all reset the search — reflect that visually.
      _controller.text = widget.vm.search;
    }
    setState(() {});
  }

  String _committedSearch = '';

  void _selectKey(FilterKey key) {
    final next = '${key.id}:';
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _selectValue(FilterKey key, FilterValueSuggestion value) async {
    await key.addValue(widget.vm, value.rawValue);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _commitFreeText(String value) {
    widget.vm.setSearch(value);
    _committedSearch = value;
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _removeToken(FilterToken token) async {
    final key = _keyById(token.keyId);
    if (key == null) return;
    await key.removeValue(widget.vm, token.rawValue);
  }

  Future<void> _onChipTap(FilterToken token) async {
    final key = _keyById(token.keyId);
    if (key == null) return;
    final cycler = key.cycleValue(widget.vm);
    if (cycler != null) {
      await cycler();
      return;
    }
    _selectKey(key);
    _focusNode.requestFocus();
  }

  FilterKey? _keyById(String keyId) {
    for (final k in widget.filterKeys) {
      if (k.id == keyId) return k;
    }
    return null;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty) {
      final tokens = _activeTokens(context);
      if (tokens.isNotEmpty) {
        _removeToken(tokens.last);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  List<FilterToken> _activeTokens(BuildContext context) {
    final out = <FilterToken>[];
    for (final k in widget.filterKeys) {
      out.addAll(k.tokensFrom(widget.vm, context));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final active = _activeTokens(context);
    final parse = FilterInputParse.of(_controller.text, widget.filterKeys);

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
                _controller.clear();
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
                      canCycle:
                          _keyById(t.keyId)?.cycleValue(widget.vm) != null,
                      onTap: () => _onChipTap(t),
                      onRemove: () => _removeToken(t),
                    ),
                  IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Focus(
                        onKeyEvent: _handleKey,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: active.isEmpty
                                ? context.tr(widget.hintKey)
                                : null,
                            border: InputBorder.none,
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
              parse: parse,
              onSelectKey: _selectKey,
              onSelectValue: _selectValue,
              onCommitFreeText: _commitFreeText,
              maxHeight: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
