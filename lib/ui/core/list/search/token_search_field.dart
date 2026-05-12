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
import 'package:admin/ui/core/list/search/token_search_controller.dart';

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

  /// Anchors the overlay to the field. We use `RenderBox.localToGlobal`
  /// on this key's render object to compute the menu's screen position
  /// at overlay-build time. `CompositedTransformFollower` would be the
  /// natural Flutter idiom here, but its paint-time layer transform
  /// doesn't propagate cleanly to `TapRegionSurface.globalToLocal`
  /// queries — the registry then sees menu clicks as "outside" the
  /// overlay's TapRegion, fires the field's `onTapOutside`, and the
  /// menu hides before the click completes. Explicit positioning
  /// keeps the menu's render box at the visible position, so the
  /// TapRegion's hit area matches.
  final GlobalKey _fieldKey = GlobalKey();

  // Overlay visibility is intentionally decoupled from focus. It opens
  // only on explicit user gestures (TextField.onTap, the leading `+
  // filter` IconButton) and closes only on explicit dismissal (Escape,
  // outside-tap via TapRegion, value pick, clear-filters). Tying it to
  // focus produced two bugs in tandem: focus loss raced clicks (the
  // overlay would hide before the row's onTap fired), and focus gain
  // re-opened the menu when the framework re-routed focus back to the
  // TextField after a programmatic `unfocus()` in the dismiss path.

  /// Shared `TapRegion.groupId` for the field and its overlay menu. Without
  /// this, the menu — mounted by `OverlayPortal` in the app-level Overlay —
  /// sits outside the field's TapRegion, so tapping a suggestion fires
  /// `onTapOutside` (which hides the overlay) before the row's InkWell can
  /// handle the tap. Sharing the group makes Flutter treat them as one
  /// logical region. Per-instance Object so two fields on the same screen
  /// don't cross-clobber.
  final Object _tapGroup = Object();

  late final TokenSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TokenSearchController(
      vm: widget.vm,
      filterKeys: widget.filterKeys,
      initialText: widget.vm.search,
    );
    _controller.text.addListener(_onTextChange);
    widget.vm.addListener(_onVmChange);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChange);
    _controller.text.removeListener(_onTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange() {
    // Rebuild the menu so its parse + value-mode dispatch follow the
    // current input. Doesn't show the overlay — that happens only on
    // explicit user gestures (TextField.onTap, leading `+` button).
    _controller.invalidateParse();
    setState(() {});
  }

  void _onVmChange() {
    // Sync the VM's persisted search text back into the controller when it
    // changes externally (e.g. `Clear filters` button on the empty state).
    if (_controller.text.text != widget.vm.search) {
      _controller.text.value = TextEditingValue(
        text: widget.vm.search,
        selection: TextSelection.collapsed(offset: widget.vm.search.length),
      );
    }
  }

  // ── Menu actions ─────────────────────────────────────────────────────

  Future<void> _onSelectValue(FilterKey key, FilterValueSuggestion value) {
    // Dismiss BEFORE the await. addValue/removeValue calls vm.setStates,
    // which fires notifyListeners synchronously and then awaits a page
    // refresh (a real network call). If we dismissed after the await,
    // the parent's ListenableBuilder would rebuild during the wait and
    // re-render the menu in its post-click state for the duration of
    // the network round-trip. Hiding first means the menu is already
    // gone when the await runs.
    //
    // We deliberately do NOT call `unfocus()` here. With the overlay no
    // longer tied to focus, an `unfocus()` would only cause Flutter's
    // FocusManager to re-route focus back to the TextField on the next
    // frame — which used to re-open the menu and produced the "popup
    // shown again" report.
    return _controller.selectValue(
      key,
      value,
      context,
      beforeAwait: () {
        _controller.text.clear();
        if (_overlay.isShowing) _overlay.hide();
      },
    );
  }

  // ── Keyboard handling ────────────────────────────────────────────────

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _overlay.hide();
      _controller.focus.unfocus();
      return KeyEventResult.handled;
    }
    final shared = _controller.handleArrowEnterBackspace(
      event,
      suggestionsActive: _overlay.isShowing,
      context: context,
    );
    if (shared == KeyEventResult.handled) return shared;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final input = _controller.text.text.trim();
      if (input.isEmpty) return KeyEventResult.ignored;
      final parse = _controller.parseInput();
      if (parse.matchedKey != null && parse.query.trim().isNotEmpty) {
        // `is:archived` typed verbatim → apply the value, then dismiss
        // the overlay (same dismiss order as `_onSelectValue` to avoid
        // the menu re-rendering during the addValue await).
        _controller.text.clear();
        if (_overlay.isShowing) _overlay.hide();
        parse.matchedKey!.addValue(widget.vm, parse.query.trim());
        return KeyEventResult.handled;
      }
      _controller.commitFreeText(input);
      _controller.focus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.wide ? _buildWide(context) : _buildNarrowSummary(context);
  }

  Widget _buildWide(BuildContext context) {
    final tokens = context.inTheme;
    final active = _controller.activeTokens(context);

    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (overlayContext) {
        // Anchor the menu just below the field. Position is computed
        // from the field's RenderBox at build time so the TapRegion's
        // hit area matches the visible menu (see `_fieldKey` doc for
        // why CompositedTransformFollower didn't work here).
        final fieldBox =
            _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        if (fieldBox == null || !fieldBox.attached || !fieldBox.hasSize) {
          return const SizedBox.shrink();
        }
        final topLeft = fieldBox.localToGlobal(Offset.zero);
        return Positioned(
          top: topLeft.dy + fieldBox.size.height + 4,
          left: topLeft.dx,
          child: TapRegion(
            groupId: _tapGroup,
            child: FilterSuggestionMenu(
              vm: widget.vm,
              keys: widget.filterKeys,
              parse: _controller.parseInput(),
              controller: _controller.suggestions,
              onSelectKey: _controller.selectKey,
              onSelectValue: _onSelectValue,
              onCommitFreeText: (v) {
                _controller.commitFreeText(v);
                _controller.focus.requestFocus();
              },
            ),
          ),
        );
      },
      child: TapRegion(
        groupId: _tapGroup,
        onTapOutside: (_) {
          if (_overlay.isShowing) _overlay.hide();
          _controller.focus.unfocus();
        },
        child: Container(
          key: _fieldKey,
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(InRadii.r1),
            border: Border.all(
              color: _controller.focus.hasFocus ? tokens.accent : tokens.border,
              width: _controller.focus.hasFocus ? 1.5 : 1,
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
                  _controller.focus.requestFocus();
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
                        onRemove: () => _controller.removeToken(t),
                      ),
                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: Focus(
                          onKeyEvent: _handleKey,
                          child: TextField(
                            controller: _controller.text,
                            focusNode: _controller.focus,
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
                                  final handled = await _controller
                                      .handlePaste();
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
              if (active.isNotEmpty || _controller.text.text.isNotEmpty)
                IconButton(
                  tooltip: context.tr('clear_filters'),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.text.clear();
                    widget.vm.clearAllFilters();
                    if (_overlay.isShowing) _overlay.hide();
                    _controller.focus.unfocus();
                  },
                  icon: Icon(Icons.close, color: tokens.ink3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowSummary(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final active = _controller.activeTokens(context);
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
                            FilterTokenChip.readOnly(token: t),
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
