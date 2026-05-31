import 'package:admin/data/models/domain/design.dart';

/// Bounded undo/redo history for the WYSIWYG designer canvas. Ports
/// React's `hooks/useBuilderHistory.ts` semantics: each snapshot is a
/// deep-enough copy of the blocks list (Freezed [DesignBlock]s are
/// immutable, so a shallow `List.of(...)` is safe), the stack caps at
/// [maxSize], and only **structural mutations** snapshot — property-panel
/// text edits don't pile up in the history.
///
/// Snapshots are taken **before** the mutation is applied so the user
/// can `undo()` back to the previous state. After an `undo()`, applying
/// a new mutation truncates the redo tail.
class DesignerHistoryStack {
  DesignerHistoryStack({this.maxSize = 50})
      : assert(maxSize > 0, 'maxSize must be positive');

  final int maxSize;

  /// Reverse-chronological order: `_undoStack.last` is the most recent
  /// snapshot, ready to pop on the next `undo()`.
  final List<List<DesignBlock>> _undoStack = [];
  final List<List<DesignBlock>> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Debug accessor — current undo depth (capped at [maxSize]).
  int get undoDepth => _undoStack.length;
  int get redoDepth => _redoStack.length;

  /// Record [current] as the state to revert to on the next `undo()`. Call
  /// this BEFORE applying a structural mutation. Resets the redo tail
  /// (any pending redoes become unreachable once you branch off).
  void record(List<DesignBlock> current) {
    _undoStack.add(List<DesignBlock>.of(current));
    if (_undoStack.length > maxSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Step backward. Returns the blocks list to revert to, or null if
  /// there's nothing to undo. Caller passes the *current* live blocks
  /// list so we can push it onto the redo stack.
  List<DesignBlock>? undo(List<DesignBlock> current) {
    if (_undoStack.isEmpty) return null;
    final previous = _undoStack.removeLast();
    _redoStack.add(List<DesignBlock>.of(current));
    if (_redoStack.length > maxSize) {
      _redoStack.removeAt(0);
    }
    return previous;
  }

  /// Step forward. Returns the blocks list to fast-forward to, or null if
  /// there's nothing to redo. Caller passes the *current* live blocks
  /// list so we can push it back onto the undo stack.
  List<DesignBlock>? redo(List<DesignBlock> current) {
    if (_redoStack.isEmpty) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(List<DesignBlock>.of(current));
    if (_undoStack.length > maxSize) {
      _undoStack.removeAt(0);
    }
    return next;
  }

  /// Drop both stacks. Used by `resetToEmpty` so a discarded draft
  /// doesn't carry stale history into the next session.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
