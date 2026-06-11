import 'package:flutter/foundation.dart';

import 'package:admin/data/models/domain/task.dart';

/// Client-side Project / Client / Assignee filtering shared by every task
/// view (kanban, calendar, daily, weekly). Empty string = "no filter".
///
/// Mixed onto a [ChangeNotifier]; the setters call [notifyListeners] so a bound
/// `TaskFilterBar` and the view rebuild together. Extracted verbatim from the
/// original inline `KanbanViewModel` filter block so behavior is preserved.
mixin TaskFiltersMixin on ChangeNotifier {
  String _projectId = '';
  String _clientId = '';
  String _assignedUserId = '';

  String get projectId => _projectId;
  String get clientId => _clientId;
  String get assignedUserId => _assignedUserId;

  bool get filtersActive =>
      _projectId.isNotEmpty ||
      _clientId.isNotEmpty ||
      _assignedUserId.isNotEmpty;

  void setProjectFilter(String id) {
    if (_projectId == id) return;
    _projectId = id;
    notifyListeners();
  }

  void setClientFilter(String id) {
    if (_clientId == id) return;
    _clientId = id;
    notifyListeners();
  }

  void setAssigneeFilter(String id) {
    if (_assignedUserId == id) return;
    _assignedUserId = id;
    notifyListeners();
  }

  void clearFilters() {
    if (!filtersActive) return;
    _projectId = '';
    _clientId = '';
    _assignedUserId = '';
    notifyListeners();
  }

  /// True when [t] passes all currently-active filters (AND across the trio).
  bool matchesFilters(Task t) =>
      (_projectId.isEmpty || t.projectId == _projectId) &&
      (_clientId.isEmpty || t.clientId == _clientId) &&
      (_assignedUserId.isEmpty || t.assignedUserId == _assignedUserId);
}
