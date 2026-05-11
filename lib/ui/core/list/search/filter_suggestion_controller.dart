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
  /// When the row count changes (e.g. user types `is:` and the menu
  /// switches from key mode to value mode) the highlight resets to row 0
  /// so the first row is always preselected.
  void publishRows(List<VoidCallback> next) {
    final countChanged = next.length != _rowActions.length;
    _rowActions = List<VoidCallback>.unmodifiable(next);
    if (countChanged) _selectedIndex = 0;
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
