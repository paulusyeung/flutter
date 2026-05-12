import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_entry_sheet.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart'
    show FilterSuggestionMenu, kMenuRowInsetLeft;
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
    required this.hintKey,
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

  /// Fallback anchor for the wide-mode dropdown's LEFT edge when the
  /// `RenderEditable` walk in `_findRenderEditable` comes up empty (first
  /// frame, detached). The primary anchor is the caret's global x-position
  /// — see the positioning block in `overlayChildBuilder`. Mounted on the
  /// `IntrinsicWidth` wrapping the TextField further down.
  final GlobalKey _inputKey = GlobalKey();

  // Overlay visibility is intentionally decoupled from focus. It opens
  // only on explicit user gestures (TextField.onTap, the leading `+
  // filter` IconButton, OR the user typing into a focused field with
  // non-empty text) and closes only on explicit dismissal (Escape,
  // outside-tap via TapRegion, value pick, clear-filters). Tying it to
  // focus directly produced two bugs in tandem: focus loss raced clicks
  // (the overlay would hide before the row's onTap fired), and focus
  // gain re-opened the menu when the framework re-routed focus back to
  // the TextField after a programmatic `unfocus()` in the dismiss path.
  // The "typing opens" gesture is safe against that: it's keyed on text
  // change, not focus, so a focus restoration without typing won't trip
  // it.

  /// Shared `TapRegion.groupId` for the field and its overlay menu. Without
  /// this, the menu — mounted by `OverlayPortal` in the app-level Overlay —
  /// sits outside the field's TapRegion, so tapping a suggestion fires
  /// `onTapOutside` (which hides the overlay) before the row's InkWell can
  /// handle the tap. Sharing the group makes Flutter treat them as one
  /// logical region. Per-instance Object so two fields on the same screen
  /// don't cross-clobber.
  final Object _tapGroup = Object();

  /// Anchor `(left, top)` for the overlay menu, cached on the most recent
  /// hidden→shown transition. While the overlay is visible, every
  /// `overlayChildBuilder` rebuild reuses these values so the menu doesn't
  /// chase the caret as the user types — the position freezes at the
  /// cursor where the dropdown first opened. Reset to null in
  /// `_showOverlay` / `_hideOverlay` so the next open re-anchors to the
  /// new caret position (e.g. after a chip was added and the cursor moved).
  double? _frozenMenuLeft;
  double? _frozenLocalTop;

  late final TokenSearchController _controller;

  /// Last `vm.search` value the field already reflects. Used by
  /// `_onVmChange` on the UNFOCUSED path to skip no-op re-syncs of a
  /// value we already wrote. On the FOCUSED path the controller wins
  /// unconditionally (see `_onVmChange` doc); this field still trails
  /// `vm.search` there so the next focus-loss starts from the right
  /// baseline.
  late String _lastSyncedSearch;

  @override
  void initState() {
    super.initState();
    _controller = TokenSearchController(
      vm: widget.vm,
      filterKeys: widget.filterKeys,
      initialText: widget.vm.search,
    );
    _lastSyncedSearch = widget.vm.search;
    _controller.text.addListener(_onTextChange);
    widget.vm.addListener(_onVmChange);
  }

  @override
  void didUpdateWidget(covariant TokenSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the controller when the host hands us a fresh filter-key list.
    // For clients, `ClientTokenSearchField` wraps this in a
    // `StreamBuilder<Company?>` — the first build's keys carry empty
    // `configuredLabel`s for the custom columns; the second build (once
    // the Company stream emits) replaces them with the configured labels.
    // Without this sync, `_controller.activeTokens` consults the stale
    // empty-label key and `CustomFieldFilterKey.tokensFrom` short-circuits
    // on `configuredLabel.isEmpty` — so the pill never renders even
    // though the filter applies. List-identity is the right comparison:
    // `buildClientFilterKeys` constructs a fresh `List<FilterKey>` per
    // build, so identity mismatch == upstream gave us a new list.
    if (!identical(oldWidget.filterKeys, widget.filterKeys)) {
      _controller.filterKeys = widget.filterKeys;
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChange);
    _controller.text.removeListener(_onTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange() {
    // Invalidate the parse cache so the next overlay rebuild re-tokenises.
    // No `setState` — the `ListenableBuilder` wrapping the build subtree
    // listens to `_controller.text` directly and rebuilds.
    _controller.invalidateParse();

    final text = _controller.text.text;

    // Re-open the overlay when the user starts typing into a focused
    // field. Without this, a chip removal (or any path that leaves focus
    // on the field with the overlay hidden) traps the user typing into a
    // focused input with no dropdown.
    if (_controller.focus.hasFocus && text.isNotEmpty && !_overlay.isShowing) {
      _showOverlay();
    }

    // Pivot from free-text → filter-building: drop the stale `vm.search`
    // the moment a colon appears in the input. Without this, picking
    // "Name" after a live-search of `mar` would leave `mar` filtering
    // the list alongside the chip the user is about to add, and the
    // user has no idea the free-text is still active.
    if (_controller.focus.hasFocus &&
        text.contains(':') &&
        widget.vm.search.isNotEmpty) {
      widget.vm.setSearch('');
      return;
    }

    // Search-as-you-type. Live-commit to `vm.search` only when ALL of:
    //
    //   * `focus.hasFocus` — programmatic text writes (clear-all,
    //     value-commit, paste handler) don't push as a side effect.
    //   * `text.isNotEmpty` — `text.clear()` cascades from chip-commit
    //     paths don't push an empty string and wipe `vm.search`.
    //   * `!text.contains(':')` — when the user is composing a `<key>:`
    //     filter, the partial value isn't a search query.
    //   * `!_isKeyPrefix(text)` — bare text matching a known key id or
    //     alias (`name`, `status`, `country`, …) is the user mid-typing
    //     a prefix, not a free-text query. Without this, backspacing
    //     `name:` → `name` would search the list for clients literally
    //     named "name".
    //   * `vm.search != text` — short-circuit on no-op.
    if (_controller.focus.hasFocus &&
        text.isNotEmpty &&
        !text.contains(':') &&
        !_isKeyPrefix(text) &&
        widget.vm.search != text) {
      widget.vm.setSearch(text);
    }
  }

  /// True when [text] matches a known filter key's id or alias verbatim
  /// (case-insensitive). Used to suppress the live free-text commit when
  /// the user is mid-typing a key prefix.
  bool _isKeyPrefix(String text) {
    final lower = text.toLowerCase();
    for (final k in widget.filterKeys) {
      if (k.id == lower) return true;
      for (final a in k.aliases) {
        if (a == lower) return true;
      }
    }
    return false;
  }

  void _onVmChange() {
    // While the field has focus, the controller is the source of truth.
    // `vm.search` legitimately trails the controller during `setSearch`'s
    // 250 ms debounce — if a notify lands in that window with the STALE
    // `vm.search` value (e.g. a network reply for `john` arrives after
    // the user has backspaced to `joh`), syncing would resurrect a
    // character the user just deleted. External resets (Clear filters,
    // session restore, paste, chip commit) never happen on a focused
    // field, so it's safe to skip the sync here. Keep `_lastSyncedSearch`
    // aligned so the next focus-loss starts from the right baseline.
    if (_controller.focus.hasFocus) {
      _lastSyncedSearch = widget.vm.search;
      return;
    }
    // Unfocused path. Gate on `vm.search` *transitioning* — `_onVmChange`
    // fires on every notify including page loads / item refreshes, which
    // don't touch `vm.search`. Without this guard we'd write the same
    // value into the controller repeatedly and possibly trash the
    // selection.
    final current = widget.vm.search;
    if (current == _lastSyncedSearch) return;
    _lastSyncedSearch = current;
    if (_controller.text.text != current) {
      _controller.text.value = TextEditingValue(
        text: current,
        selection: TextSelection.collapsed(offset: current.length),
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
        _hideOverlay();
      },
    );
  }

  /// User tapped a chip body — drop into value mode for that key so they
  /// can change the value. Multi-value keys remove the clicked chip
  /// first so the new pick *replaces* (rather than adds). Single-value
  /// keys leave the chip in place — the new pick will replace it via
  /// the key's own `singleValue` semantics.
  void _onChipTap(FilterToken token) {
    final key = _controller.keyById(token.keyId);
    if (key == null) return;
    if (!key.singleValue) {
      unawaited(key.removeValue(widget.vm, token.rawValue));
    }
    _controller.selectKey(key);
    _showOverlay();
  }

  /// Operator picked before a value was typed. Write `<key>:<symbol>` to
  /// the input so the user can keep typing the value; the chip is
  /// committed on Enter (or when the user re-clicks an op row with the
  /// value present). The symbol form (`>`/`<`) is what
  /// `BalanceFilterKey._parseValueWithOp` normalises back to the wire
  /// format `value:op`.
  void _onPickOp(FilterKey key, FilterOp op) {
    final symbol = op == FilterOp.gt ? '>' : '<';
    final next = '${key.id}:$symbol';
    _controller.text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _controller.focus.requestFocus();
    // See TokenSearchController.selectKey for the macOS-echo rationale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.focus.hasFocus) return;
      if (_controller.text.text != next) return;
      final sel = _controller.text.selection;
      if (sel.isCollapsed && sel.extentOffset == next.length) return;
      _controller.text.selection = TextSelection.collapsed(offset: next.length);
    });
  }

  // ── Overlay show/hide ────────────────────────────────────────────────

  /// Show the dropdown after wiping the cached anchor so the next overlay
  /// build re-anchors to the current caret. Replaces direct
  /// `_overlay.show()` calls so every entry point shares this behavior
  /// — the menu only re-positions when the user is about to add the next
  /// filter, not on every keystroke in between.
  void _showOverlay() {
    _frozenMenuLeft = null;
    _frozenLocalTop = null;
    if (!_overlay.isShowing) _overlay.show();
  }

  /// Hide the dropdown and drop the cached anchor so the next show
  /// recomputes from a fresh layout.
  void _hideOverlay() {
    if (_overlay.isShowing) _overlay.hide();
    _frozenMenuLeft = null;
    _frozenLocalTop = null;
  }

  // ── Caret position lookup ────────────────────────────────────────────

  /// Walks the render tree below the focus node's context to find the
  /// `RenderEditable` of the TextField. TextField doesn't expose its
  /// internal EditableText via a key, and `CompositedTransformFollower`
  /// produced TapRegion-hit-test bugs (see `_fieldKey` doc), so a direct
  /// render-tree walk is the cleanest way to read the caret's pixel
  /// position. Returns null on the first frame before the editable is
  /// attached, in which case the overlay falls back to `_inputKey`.
  RenderEditable? _findRenderEditable() {
    final start = _controller.focus.context?.findRenderObject();
    if (start == null) return null;
    RenderEditable? found;
    void visit(RenderObject obj) {
      if (found != null) return;
      if (obj is RenderEditable) {
        found = obj;
        return;
      }
      obj.visitChildren(visit);
    }

    visit(start);
    return found;
  }

  // ── Keyboard handling ────────────────────────────────────────────────

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideOverlay();
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
        final key = parse.matchedKey!;
        final value = parse.query.trim();
        // Pre-flight validation — keys can reject inputs that would
        // silently produce no chip (e.g. `balance:>` with no number).
        // Reject = keep the input + overlay open so the user sees their
        // partial input and can finish it.
        if (!key.isValidValue(value)) {
          return KeyEventResult.handled;
        }
        // `is:archived` typed verbatim → apply the value, then dismiss
        // the overlay (same dismiss order as `_onSelectValue` to avoid
        // the menu re-rendering during the addValue await).
        _controller.text.clear();
        _hideOverlay();
        key.addValue(widget.vm, value);
        return KeyEventResult.handled;
      }
      // Free-text branch. `_onTextChange` already keeps `vm.search` in
      // sync as the user types, so Enter just dismisses the overlay
      // (the user signalled "I'm done picking; show me the results").
      // We must NOT clear the input here: clearing would fire
      // `_onTextChange` with empty text and wipe `vm.search` along with
      // the field — turning Enter into a destructive "clear filter".
      _hideOverlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Rebuilds are driven by the listenable merge here rather than ad-hoc
    // `setState` calls in the change handlers. The text listener only
    // invalidates the parse cache; the VM listener only syncs the text
    // controller. Both notify the merge, which then rebuilds the subtree.
    return ListenableBuilder(
      listenable: Listenable.merge([widget.vm, _controller.text]),
      builder: (context, _) =>
          widget.wide ? _buildWide(context) : _buildNarrowSummary(context),
    );
  }

  Widget _buildWide(BuildContext context) {
    final tokens = context.inTheme;
    final active = _controller.activeTokens(context);

    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (overlayContext) {
        // Anchor the menu just below the field. The first build after a
        // hidden→shown transition computes the position from the caret
        // (see freeze logic below) and caches it; subsequent rebuilds
        // while the overlay stays open reuse the cached values so the
        // menu doesn't chase the caret as the user types. `_showOverlay`
        // wipes the cache so the next open re-anchors. See `_fieldKey`
        // doc for why CompositedTransformFollower didn't work here.
        final double localLeft;
        final double localTop;
        if (_frozenMenuLeft != null && _frozenLocalTop != null) {
          localLeft = _frozenMenuLeft!;
          localTop = _frozenLocalTop!;
        } else {
          final fieldBox =
              _fieldKey.currentContext?.findRenderObject() as RenderBox?;
          if (fieldBox == null || !fieldBox.attached || !fieldBox.hasSize) {
            return const SizedBox.shrink();
          }
          final topLeft = fieldBox.localToGlobal(Offset.zero);
          // The popup's LEFT edge tracks the CARET's global x at the
          // moment the dropdown opens. Subtracts `kMenuRowInsetLeft` so
          // the row TEXT CONTENT (which is padded inside the menu) lines
          // up with the caret column, not the painted menu edge. Falls
          // back to the `_inputKey` IntrinsicWidth box when the
          // RenderEditable walk fails (first frame, detached), and to
          // the field's own left as a last resort.
          double menuLeft = topLeft.dx;
          final editable = _findRenderEditable();
          if (editable != null && editable.attached && editable.hasSize) {
            final sel = _controller.text.selection;
            final offset = sel.isValid ? sel.extentOffset : 0;
            final caretLocal = editable
                .getLocalRectForCaret(TextPosition(offset: offset))
                .topLeft;
            menuLeft =
                editable.localToGlobal(caretLocal).dx - kMenuRowInsetLeft;
          } else {
            final inputRender = _inputKey.currentContext?.findRenderObject();
            if (inputRender is RenderBox &&
                inputRender.attached &&
                inputRender.hasSize) {
              menuLeft =
                  inputRender.localToGlobal(Offset.zero).dx - kMenuRowInsetLeft;
            }
          }
          // Convert from GLOBAL screen coords to the hosting Overlay's
          // LOCAL coords. `OverlayPortal` mounts the menu in the closest
          // ancestor Overlay — here the branch Navigator's Overlay inside
          // `StatefulShellRoute`, NOT the root Overlay. The branch
          // Overlay's local (0,0) is global (sidebar_width, 0) on wide
          // layouts (`scaffold_with_nav.dart` renders the shell as
          // `Row(InSidebar, Expanded(navigationShell))`), so feeding
          // `Positioned` the raw global x lands the menu ~sidebar_width
          // px too far right. Both axes are converted up-front so a
          // future shell layout with a top bar wouldn't reintroduce the
          // same bug for the vertical anchor.
          final overlayBox =
              Overlay.of(overlayContext).context.findRenderObject()
                  as RenderBox?;
          final overlayOrigin =
              overlayBox?.localToGlobal(Offset.zero) ?? Offset.zero;
          double computedLeft = menuLeft - overlayOrigin.dx;
          // Clamped to 8 px so the menu can't escape the Overlay's left
          // edge on narrow windows.
          if (computedLeft < 8) computedLeft = 8;
          localLeft = computedLeft;
          localTop = topLeft.dy + fieldBox.size.height + 4 - overlayOrigin.dy;
          // Cache for subsequent rebuilds in this show cycle. Assigning
          // to fields during build is safe — we never call `setState`
          // from here, and the next build will simply take the early
          // return above.
          _frozenMenuLeft = localLeft;
          _frozenLocalTop = localTop;
        }
        return Positioned(
          top: localTop,
          left: localLeft,
          child: TapRegion(
            groupId: _tapGroup,
            child: FilterSuggestionMenu(
              vm: widget.vm,
              keys: widget.filterKeys,
              parse: _controller.parseInput(),
              controller: _controller.suggestions,
              onSelectKey: _controller.selectKey,
              onSelectValue: _onSelectValue,
              onPickOp: _onPickOp,
              onCommitFreeText: (v) {
                _controller.commitFreeText(v);
                // Enter on the "Search for X" row signals "I'm done
                // picking; show me the results" — dismiss the dropdown
                // but keep focus + the typed text so the user can keep
                // editing the query.
                _hideOverlay();
                _controller.focus.requestFocus();
              },
            ),
          ),
        );
      },
      child: TapRegion(
        groupId: _tapGroup,
        onTapOutside: (_) {
          _hideOverlay();
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
                  // Toggle: a second click dismisses the open menu rather
                  // than no-opping (the `OverlayPortal.show()` is guarded
                  // against double-shows). Standard dropdown affordance.
                  _controller.focus.requestFocus();
                  if (_overlay.isShowing) {
                    _hideOverlay();
                  } else {
                    _showOverlay();
                  }
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
                        onTap: () => _onChipTap(t),
                      ),
                    IntrinsicWidth(
                      key: _inputKey,
                      child: ConstrainedBox(
                        // Sized so the input is visible-but-discoverable when
                        // no chips are present. `IntrinsicWidth` keeps the
                        // input from greedy-grabbing the row when chips are
                        // wide enough to fill the available width on the
                        // current run of the Wrap.
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
                              // All four state-specific borders must be
                              // explicit; the global `InputDecorationTheme`
                              // sets each to `OutlineInputBorder`, and
                              // `border: InputBorder.none` alone leaves them
                              // active — the user then sees a phantom
                              // rounded box sitting where the empty input is.
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
                            onTap: () {
                              _showOverlay();
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
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.text.clear();
                    widget.vm.clearAllFilters();
                    _hideOverlay();
                    _controller.focus.unfocus();
                  },
                  // Distinct from the per-chip `Icons.close` so "clear all
                  // filters" doesn't look like "remove one chip".
                  icon: Icon(Icons.filter_alt_off_outlined, color: tokens.ink3),
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
