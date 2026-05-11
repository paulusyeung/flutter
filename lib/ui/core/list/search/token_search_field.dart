import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_entry_sheet.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';

/// Sentry-style token search field. Tokens (e.g. `is:active`,
/// `country:United States`) render as inline chips ahead of a `TextField`
/// for free-text search. Focus opens an autocomplete menu listing every
/// available [FilterKey]; typing `keyId:` enters value mode and the menu
/// flips to value suggestions.
///
/// `wide=false` collapses the widget to a tap-to-open summary that pushes
/// [FilterEntrySheet] as a full-screen route — the inline layout is
/// unusable on a 360-px phone screen with the keyboard up.
class TokenSearchField extends StatefulWidget {
  const TokenSearchField({
    required this.vm,
    required this.filterKeys,
    required this.wide,
    this.hintKey = 'search_clients_or_filter_hint',
    super.key,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> filterKeys;
  final bool wide;
  final String hintKey;

  @override
  State<TokenSearchField> createState() => _TokenSearchFieldState();
}

class _TokenSearchFieldState extends State<TokenSearchField> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller;

  /// Shared `TapRegion.groupId` for the field and its overlay menu. Without
  /// this, the menu — mounted by `OverlayPortal` in the app-level Overlay —
  /// sits outside the field's TapRegion, so tapping a suggestion fires
  /// `onTapOutside` (which hides the overlay) before the row's InkWell can
  /// handle the tap. Sharing the group makes Flutter treat them as one
  /// logical region. Per-instance Object so two fields on the same screen
  /// don't cross-clobber.
  final Object _tapGroup = Object();

  /// True after the user types or focuses the field; controls whether the
  /// suggestion menu shows. Closing on `Escape` / outside-tap resets this.
  bool _menuRequested = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.vm.search);
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
    widget.vm.addListener(_onVmChange);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChange);
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller
      ..removeListener(_onTextChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _menuRequested = true;
      if (!_overlay.isShowing) _overlay.show();
    } else {
      _menuRequested = false;
      if (_overlay.isShowing) _overlay.hide();
    }
  }

  void _onTextChange() {
    if (!_menuRequested) return;
    if (!_overlay.isShowing) _overlay.show();
    setState(() {}); // rebuild the overlay's parse + suggestion menu
  }

  void _onVmChange() {
    // Sync the VM's persisted search text back into the controller when it
    // changes externally (e.g. `Clear filters` button on the empty state).
    if (_controller.text != widget.vm.search) {
      _controller.value = TextEditingValue(
        text: widget.vm.search,
        selection: TextSelection.collapsed(offset: widget.vm.search.length),
      );
    }
  }

  // ── Menu actions ─────────────────────────────────────────────────────

  void _selectKey(FilterKey key) {
    final next = '${key.id}:';
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _selectValue(FilterKey key, FilterValueSuggestion value) async {
    await key.addValue(widget.vm, value.rawValue);
    _clearInput();
  }

  void _commitFreeText(String value) {
    widget.vm.setSearch(value);
    _clearInput();
  }

  void _clearInput() {
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
    // No cycle — open the menu pre-populated with this key so the user can
    // pick a different value or add another.
    _selectKey(key);
    _focusNode.requestFocus();
  }

  FilterKey? _keyById(String keyId) {
    for (final k in widget.filterKeys) {
      if (k.id == keyId) return k;
    }
    return null;
  }

  // ── Keyboard handling ────────────────────────────────────────────────

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _overlay.hide();
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty) {
      // Backspace with empty input → remove the trailing token, Sentry parity.
      final tokens = _activeTokens(context);
      if (tokens.isNotEmpty) {
        _removeToken(tokens.last);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final text = _controller.text.trim();
      if (text.isEmpty) return KeyEventResult.ignored;
      final parse = FilterInputParse.of(text, widget.filterKeys);
      if (parse.matchedKey != null && parse.query.trim().isNotEmpty) {
        // `is:archived` typed verbatim — apply the value if it matches a
        // suggestion's raw, otherwise drop to the menu.
        parse.matchedKey!.addValue(widget.vm, parse.query.trim());
        _clearInput();
        return KeyEventResult.handled;
      }
      _commitFreeText(text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Paste handling ───────────────────────────────────────────────────

  /// Lex a pasted string into a tokens-and-free-text payload. Recognises
  /// each known key's id and aliases as `<key>:<value>` substrings; the
  /// rest joins as the search text. Whitespace inside quoted values is
  /// allowed: `country:"United States"`.
  ({List<({String keyId, String rawValue})> tokens, String freeText}) _lex(
    String input,
  ) {
    final tokens = <({String keyId, String rawValue})>[];
    final freeBuf = StringBuffer();

    final pieces = input.split(RegExp(r'\s+'));
    final knownIds = <String, String>{};
    for (final k in widget.filterKeys) {
      knownIds[k.id] = k.id;
      for (final a in k.aliases) {
        knownIds[a] = k.id;
      }
    }

    for (final piece in pieces) {
      final colon = piece.indexOf(':');
      if (colon == -1) {
        if (piece.isNotEmpty) freeBuf.write('$piece ');
        continue;
      }
      final prefix = piece.substring(0, colon).toLowerCase();
      final id = knownIds[prefix];
      if (id == null) {
        if (piece.isNotEmpty) freeBuf.write('$piece ');
        continue;
      }
      var value = piece.substring(colon + 1);
      if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
      if (value.isEmpty) continue;
      // `is:active,archived` — split commas to add multiple tokens.
      for (final v in value.split(',')) {
        final trimmed = v.trim();
        if (trimmed.isNotEmpty) {
          tokens.add((keyId: id, rawValue: trimmed));
        }
      }
    }
    return (tokens: tokens, freeText: freeBuf.toString().trim());
  }

  Future<bool> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !text.contains(':')) return false;
    final lex = _lex(text);
    if (lex.tokens.isEmpty) return false;
    for (final t in lex.tokens) {
      final key = _keyById(t.keyId);
      if (key != null) {
        await key.addValue(widget.vm, t.rawValue);
      }
    }
    if (lex.freeText.isNotEmpty) widget.vm.setSearch(lex.freeText);
    _clearInput();
    return true;
  }

  // ── Token resolution from VM ────────────────────────────────────────

  List<FilterToken> _activeTokens(BuildContext context) {
    final out = <FilterToken>[];
    for (final k in widget.filterKeys) {
      out.addAll(k.tokensFrom(widget.vm, context));
    }
    return out;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.wide ? _buildWide(context) : _buildNarrowSummary(context);
  }

  Widget _buildWide(BuildContext context) {
    final tokens = context.inTheme;
    final active = _activeTokens(context);

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (overlayContext) {
          // Anchor the menu just below the field. `Positioned` is a
          // ParentDataWidget and must be a direct child of the overlay's
          // stack — so `TapRegion` (which shares `_tapGroup` with the field
          // to keep clicks from dismissing the overlay; see `_tapGroup` doc)
          // sits INSIDE Positioned, wrapping the follower + menu.
          return Positioned(
            child: TapRegion(
              groupId: _tapGroup,
              child: CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                offset: const Offset(0, 4),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: FilterSuggestionMenu(
                    vm: widget.vm,
                    keys: widget.filterKeys,
                    parse: FilterInputParse.of(
                      _controller.text,
                      widget.filterKeys,
                    ),
                    onSelectKey: _selectKey,
                    onSelectValue: _selectValue,
                    onCommitFreeText: _commitFreeText,
                  ),
                ),
              ),
            ),
          );
        },
        child: TapRegion(
          groupId: _tapGroup,
          onTapOutside: (_) {
            if (_overlay.isShowing) _overlay.hide();
            _focusNode.unfocus();
          },
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(InRadii.r1),
              border: Border.all(
                color: _focusNode.hasFocus ? tokens.accent : tokens.border,
                width: _focusNode.hasFocus ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: context.tr('add_filter'),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _focusNode.requestFocus();
                    if (!_overlay.isShowing) _overlay.show();
                  },
                  icon: Icon(Icons.tune, color: tokens.ink3),
                ),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
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
                              onTap: () {
                                _menuRequested = true;
                                if (!_overlay.isShowing) _overlay.show();
                              },
                              contextMenuBuilder: (context, editableState) {
                                return AdaptiveTextSelectionToolbar.editable(
                                  clipboardStatus: ClipboardStatus.pasteable,
                                  onCopy: () => editableState.copySelection(
                                    SelectionChangedCause.toolbar,
                                  ),
                                  onCut: () => editableState.cutSelection(
                                    SelectionChangedCause.toolbar,
                                  ),
                                  onPaste: () async {
                                    final handled = await _handlePaste();
                                    if (!handled && context.mounted) {
                                      // Native paste fallback when the
                                      // clipboard doesn't look like a
                                      // `key:value` query — pasteText is
                                      // fire-and-forget, the controller's
                                      // change listener will sync state.
                                      unawaited(
                                        editableState.pasteText(
                                          SelectionChangedCause.toolbar,
                                        ),
                                      );
                                    }
                                  },
                                  onSelectAll: () => editableState.selectAll(
                                    SelectionChangedCause.toolbar,
                                  ),
                                  anchors: editableState.contextMenuAnchors,
                                  onLookUp: null,
                                  onSearchWeb: null,
                                  onShare: null,
                                  onLiveTextInput: null,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (active.isNotEmpty || _controller.text.isNotEmpty)
                  IconButton(
                    tooltip: context.tr('clear_filters'),
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _controller.clear();
                      widget.vm.clearAllFilters();
                      _focusNode.unfocus();
                    },
                    icon: Icon(Icons.close, color: tokens.ink3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowSummary(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final active = _activeTokens(context);
    final summary = StringBuffer();
    if (widget.vm.search.isNotEmpty) summary.write(widget.vm.search);
    if (active.isEmpty && summary.isEmpty) {
      summary.write(context.tr(widget.hintKey));
    }

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(InRadii.r1),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(InRadii.r1),
          border: Border.all(color: tokens.border),
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: tokens.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: active.isEmpty
                  ? Text(
                      summary.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.vm.search.isEmpty
                            ? tokens.ink3
                            : tokens.ink,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final t in active) ...[
                            _ReadOnlyChip(token: t),
                            const SizedBox(width: 6),
                          ],
                          if (widget.vm.search.isNotEmpty)
                            Text(
                              widget.vm.search,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.ink,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.tune, size: 18, color: tokens.ink3),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FilterEntrySheet(
          vm: widget.vm,
          filterKeys: widget.filterKeys,
          hintKey: widget.hintKey,
        ),
      ),
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.token});

  final FilterToken token;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${token.displayKey.toLowerCase()} ',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
          Text(
            token.displayValue,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
