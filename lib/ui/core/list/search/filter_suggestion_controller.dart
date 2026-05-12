import 'package:flutter/foundation.dart';

/// Shared state between [FilterSuggestionMenu] (which renders rows) and
/// [TokenSearchField] (which intercepts keyboard events via its `Focus`
/// wrapper). The menu publishes its rows in display order; the field
/// drives the highlight + commit.
///
/// We can't put the index inside the menu alone because the field needs
/// to know the row count for arrow-key clamping and the row's action for
/// Enter — and we can't put it inside the field alone because the menu's
/// row list is derived from streamed value suggestions the field doesn't
/// have access to. A shared `ChangeNotifier` is the smallest piece of
/// glue that lets each side own what it knows.
class FilterSuggestionController extends ChangeNotifier {
  int _selectedIndex = 0;
  List<VoidCallback> _rowActions = const [];
  List<Object> _rowKeys = const [];

  /// Currently highlighted row, in the menu's display order. Always in
  /// `[0, rowCount)` when [rowCount] > 0; `0` when the menu is empty.
  int get selectedIndex => _selectedIndex;

  /// Number of rows the menu just published.
  int get rowCount => _rowActions.length;

  /// Called by the menu after each rebuild — typically from a
  /// post-frame callback so `notifyListeners` doesn't fire while widgets
  /// are still being built. Pass the row actions in display order
  /// alongside a parallel list of stable [keys] that identify each row
  /// by content (e.g. `'key:status'`, `'value:status:active'`).
  ///
  /// The highlight resets to row 0 only when the published [keys]
  /// differ from the previous publish — by length or by per-index
  /// `==`. Same keys → same logical rows → highlight survives the
  /// publish, even though the closures in [actions] are fresh objects
  /// from this rebuild. This is what keeps the highlight glued to the
  /// row the user arrow-keyed to while a VM `notifyListeners` storms
  /// through (network load → list page swap → many no-op rebuilds).
  /// A genuine content change (filter narrows, value list shrinks)
  /// still flips at least one key and resets correctly.
  void publishRows(List<VoidCallback> actions, List<Object> keys) {
    assert(actions.length == keys.length);
    final unchanged = _keysMatch(keys);
    _rowActions = List<VoidCallback>.unmodifiable(actions);
    _rowKeys = List<Object>.unmodifiable(keys);
    if (!unchanged) _selectedIndex = 0;
    notifyListeners();
  }

  bool _keysMatch(List<Object> next) {
    if (next.length != _rowKeys.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _rowKeys[i]) return false;
    }
    return true;
  }

  /// Set the highlight to a specific row. Used by mouse hover so a
  /// pointing user sees the same surface-alt background as a keyboard
  /// user — and Enter commits whichever row was last hovered or arrowed
  /// to. No-ops on out-of-range or unchanged input so spurious hover
  /// events don't fire notifications.
  void setSelectedIndex(int index) {
    if (index < 0 || index >= _rowActions.length) return;
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void moveUp() {
    if (_rowActions.isEmpty) return;
    final last = _rowActions.length - 1;
    _selectedIndex = _selectedIndex <= 0 ? last : _selectedIndex - 1;
    notifyListeners();
  }

  void moveDown() {
    if (_rowActions.isEmpty) return;
    _selectedIndex = (_selectedIndex + 1) % _rowActions.length;
    notifyListeners();
  }

  /// Fire the currently-highlighted row's action. Returns true when an
  /// action ran (the caller can stop further handling), false when there
  /// were no rows to commit (the caller may fall back to free-text
  /// search).
  bool commit() {
    if (_rowActions.isEmpty) return false;
    if (_selectedIndex < 0 || _selectedIndex >= _rowActions.length) {
      return false;
    }
    _rowActions[_selectedIndex]();
    return true;
  }
}
