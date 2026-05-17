import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/membership_filter_key.dart';

/// Tasks expose state (active/archived/deleted) as their built-in
/// filter dimension plus per-project and per-status filters resolved
/// through their respective repository name suggestions.
List<FilterKey> buildTaskFilterKeys({
  required ProjectRepository projects,
  required TaskStatusRepository statuses,
  required String companyId,
}) => <FilterKey>[
  const IsFilterKey(),
  ProjectFilterKey(projects: projects, companyId: companyId),
  StatusFilterKey(statuses: statuses, companyId: companyId),
];

/// `status:foo` — multi-valued, resolved through the task-status
/// repository. Mirrors [ProjectFilterKey] line-for-line; different
/// `serverKey` (`status_id`) and watch source (`watchAll`).
class StatusFilterKey extends MembershipFilterKey {
  StatusFilterKey({required this.statuses, required this.companyId});

  final TaskStatusRepository statuses;
  final String companyId;

  @override
  String get id => 'status';

  @override
  String get serverKey => 'status_id';

  /// Render checkboxes — inherits the single-write `selectExclusive` from
  /// [MembershipFilterKey].
  @override
  bool get checkboxMultiSelect => true;

  @override
  String displayLabel(BuildContext context) => context.tr('status');

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return statuses.watchAll(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((s) => s.name.toLowerCase().contains(q));
      return [
        for (final s in filtered)
          FilterValueSuggestion(
            rawValue: s.id,
            displayLabel: s.name.isEmpty ? s.id : s.name,
          ),
      ];
    });
  }
}

/// `project:foo` — multi-valued, resolved through the project repository.
/// Raw value is the server project id; the suggestion menu streams the
/// cheap `(id, name)` projection from
/// `ProjectRepository.watchActiveNames` (no full row materialization).
/// The same stream populates an in-memory `id → name` cache so chip
/// text shows the project name instead of the raw id.
///
/// Caveat: chips render synchronously; the very first paint after picking
/// a project may show the raw id until the names stream produces its next
/// event. Reactive chip updates would require the chip widget itself to
/// subscribe — out of scope.
class ProjectFilterKey extends MembershipFilterKey {
  ProjectFilterKey({required this.projects, required this.companyId}) {
    _namesSub = projects.watchActiveNames(companyId: companyId).listen((rows) {
      _names
        ..clear()
        ..addEntries(rows.map((r) => MapEntry(r.id, r.name)));
    });
  }

  final ProjectRepository projects;
  final String companyId;
  final Map<String, String> _names = <String, String>{};
  StreamSubscription<List<({String id, String name})>>? _namesSub;

  @override
  String get id => 'project';

  @override
  String get serverKey => 'project_id';

  @override
  String displayLabel(BuildContext context) => context.tr('project');

  @override
  String displayValueFor(String rawValue) {
    final cached = _names[rawValue];
    if (cached != null && cached.isNotEmpty) return cached;
    return rawValue;
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return projects.watchActiveNames(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((p) => p.name.toLowerCase().contains(q));
      return [
        for (final p in filtered)
          FilterValueSuggestion(
            rawValue: p.id,
            displayLabel: p.name.isEmpty ? p.id : p.name,
          ),
      ];
    });
  }

  /// Release the names-cache subscription when the filter key is replaced
  /// (e.g. on company switch). `FilterKey` doesn't have a lifecycle hook
  /// today, so the subscription effectively lives until GC. Acceptable
  /// for v1 — the next instance subscribes against the new tenant's data.
  void dispose() {
    _namesSub?.cancel();
    _namesSub = null;
  }
}
