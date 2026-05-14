import 'package:drift/drift.dart';

import 'package:admin/domain/entity_state.dart';

/// Translate a set of UI [EntityState]s into a Drift predicate over the
/// standard `archivedAt` / `isDeleted` columns. Every CRUD entity that
/// participates in archive/restore/delete shares these two columns, so the
/// filter shape is uniform.
///
/// Caller passes the two column expressions explicitly because Drift's
/// generator pattern doesn't let us infer them by table type:
///
/// ```dart
/// if (states.isNotEmpty) {
///   q.where(
///     (c) => entityStateFilter(
///       states: states,
///       archivedAt: c.archivedAt,
///       isDeleted: c.isDeleted,
///     ),
///   );
/// }
/// ```
///
/// An empty `states` set is the caller's contract for "no state restriction"
/// — short-circuit there instead of calling this function (it asserts).
Expression<bool> entityStateFilter({
  required Set<EntityState> states,
  required Expression<int> archivedAt,
  required Expression<bool> isDeleted,
}) {
  assert(states.isNotEmpty, 'pass a non-empty state set or skip the filter');
  Expression<bool>? acc;
  for (final s in states) {
    final pred = switch (s) {
      EntityState.active => archivedAt.isNull() & isDeleted.equals(false),
      EntityState.archived => archivedAt.isNotNull() & isDeleted.equals(false),
      EntityState.deleted => isDeleted.equals(true),
    };
    acc = acc == null ? pred : acc | pred;
  }
  return acc!;
}
