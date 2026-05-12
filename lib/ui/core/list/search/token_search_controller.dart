import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_lexer.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_controller.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Coordinates the shared state between the wide-mode [TokenSearchField] and
/// the narrow-mode [FilterEntrySheet]: text controller, focus, suggestion
/// selection. Owns the disposable objects; both widgets create one of these
/// in `initState` and forward `dispose` here.
///
/// Mode-specific behaviour (overlay management, modal navigation) stays in
/// the widgets — the controller only knows about VM state, the filter-key
/// list, and the inputs the user is typing.
class TokenSearchController {
  TokenSearchController({
    required this.vm,
    required this.filterKeys,
    required String initialText,
  }) {
    text = TextEditingController(text: initialText);
  }

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> filterKeys;

  late final TextEditingController text;
  final FocusNode focus = FocusNode();
  final FilterSuggestionController suggestions = FilterSuggestionController();

  /// Cached parse of [text.value]. Recomputed lazily so each rebuild reuses
  /// the same `FilterInputParse` instead of re-tokenising on every
  /// dependent (`onKey`, `overlayChildBuilder`, etc.).
  String _parseText = '';
  FilterInputParse? _parse;
  FilterInputParse parseInput() {
    if (_parse == null || _parseText != text.text) {
      _parseText = text.text;
      _parse = FilterInputParse.of(_parseText, filterKeys);
    }
    return _parse!;
  }

  /// Invalidate the cached parse. Call from text listeners when the input
  /// changes; the next [parseInput] re-tokenises.
  void invalidateParse() {
    _parse = null;
  }

  void dispose() {
    text.dispose();
    focus.dispose();
    suggestions.dispose();
  }

  // ── Selection helpers ─────────────────────────────────────────────────

  /// User picked a key from the menu — switch the input into value mode.
  /// Requests focus so the user can immediately type the value without an
  /// extra click; the menu row's GestureDetector tap doesn't preserve the
  /// TextField's focus on its own.
  void selectKey(FilterKey key) {
    final next = '${key.id}:';
    text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    focus.requestFocus();
  }

  /// Apply or unapply a value for [key]. Toggles based on whether the
  /// raw value is already in the live applied set. The optional
  /// [beforeAwait] callback fires synchronously before the addValue/
  /// removeValue future — wide mode uses it to clear the input and hide
  /// the overlay so the menu doesn't flicker through its post-click state
  /// during the network roundtrip.
  Future<void> selectValue(
    FilterKey key,
    FilterValueSuggestion value,
    BuildContext context, {
    VoidCallback? beforeAwait,
  }) async {
    final isApplied = key
        .tokensFrom(vm, context)
        .any((t) => t.rawValue == value.rawValue);
    beforeAwait?.call();
    if (isApplied) {
      await key.removeValue(vm, value.rawValue);
    } else {
      await key.addValue(vm, value.rawValue);
    }
  }

  /// Commit the input as a free-text search query and clear the input.
  void commitFreeText(String value) {
    vm.setSearch(value);
    text.clear();
  }

  /// Remove [token] from the VM's applied filters.
  Future<void> removeToken(FilterToken token) async {
    final key = keyById(token.keyId);
    if (key == null) return;
    await key.removeValue(vm, token.rawValue);
  }

  /// Look up a [FilterKey] by id. Returns null when the id isn't known —
  /// the caller is expected to no-op rather than throw, since stale
  /// VM-state could carry a key that has since been removed.
  FilterKey? keyById(String keyId) {
    for (final k in filterKeys) {
      if (k.id == keyId) return k;
    }
    return null;
  }

  /// Currently-applied tokens across every filter key, in [filterKeys]
  /// order. Recomputed on every read — cheap, since each key already
  /// memoises its own slice.
  List<FilterToken> activeTokens(BuildContext context) {
    final out = <FilterToken>[];
    for (final k in filterKeys) {
      out.addAll(k.tokensFrom(vm, context));
    }
    return out;
  }

  // ── Keyboard handling ─────────────────────────────────────────────────

  /// Shared arrow / Enter / backspace handling. Returns
  /// [KeyEventResult.handled] when the event was consumed, ignored
  /// otherwise. Mode-specific keys (Escape in wide mode, free-text commit
  /// fall-through) are layered on top by the widget.
  ///
  /// [suggestionsActive] controls whether arrow keys / Enter on a
  /// highlighted row are intercepted. Wide mode passes
  /// `overlayController.isShowing`; narrow mode passes `true` (the menu is
  /// always visible inside the sheet).
  KeyEventResult handleArrowEnterBackspace(
    KeyEvent event, {
    required bool suggestionsActive,
    required BuildContext context,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (suggestionsActive) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        suggestions.moveDown();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        suggestions.moveUp();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (suggestions.commit()) return KeyEventResult.handled;
        // Fall through — caller may want to commit free text.
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace && text.text.isEmpty) {
      final tokens = activeTokens(context);
      if (tokens.isNotEmpty) {
        final removed = tokens.last;
        // Announce the removal so screen-reader users hear which chip
        // popped — the visual disappearance alone has no a11y signal.
        SemanticsService.sendAnnouncement(
          View.of(context),
          '${removed.displayKey} ${removed.displayValue} removed',
          Directionality.of(context),
        );
        unawaited(removeToken(removed));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ── Paste ────────────────────────────────────────────────────────────

  /// Reads the clipboard and, when it parses as `<key>:<value>` tokens,
  /// applies them and returns true. Free text inside the paste is applied
  /// to the VM's search field. Returns false when the paste should fall
  /// through to a native text paste.
  Future<bool> handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final input = data?.text;
    if (input == null || !input.contains(':')) return false;
    final lex = lexFilterInput(input, filterKeys);
    if (lex.tokens.isEmpty) return false;
    for (final t in lex.tokens) {
      final key = keyById(t.keyId);
      if (key != null) {
        await key.addValue(vm, t.rawValue);
      }
    }
    if (lex.freeText.isNotEmpty) vm.setSearch(lex.freeText);
    text.clear();
    focus.requestFocus();
    return true;
  }
}
