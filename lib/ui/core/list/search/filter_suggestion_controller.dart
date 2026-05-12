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

  /// Currently highlighted row, in the menu's display order. Always in
  /// `[0, rowCount)` when [rowCount] > 0; `0` when the menu is empty.
  int get selectedIndex => _selectedIndex;

  /// Number of rows the menu just published.
  int get rowCount => _rowActions.length;

  /// Called by the menu after each rebuild — typically from a
  /// post-frame callback so `notifyListeners` doesn't fire while widgets
  /// are still being built. Pass the row actions in display order.
  ///
  /// Resets the highlight to row 0 whenever the published actions
  /// change identity (the menu re-issued a fresh list because the
  /// rows differ). Without this, the highlight at index 3 would stick
  /// even after the user typed a character that pruned the list — and
  /// Enter would commit the wrong row. We compare by identity rather
  /// than by length so a same-length swap (e.g. one key row replaced
  /// by another after a filter narrows) still resets.
  void publishRows(List<VoidCallback> next) {
    final identityChanged = !_actionsIdenticalTo(next);
    _rowActions = List<VoidCallback>.unmodifiable(next);
    if (identityChanged) _selectedIndex = 0;
    notifyListeners();
  }

  bool _actionsIdenticalTo(List<VoidCallback> next) {
    if (next.length != _rowActions.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (!identical(next[i], _rowActions[i])) return false;
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
