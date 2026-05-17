import 'package:flutter/foundation.dart';

import 'package:admin/domain/entity_state.dart';

/// A one-shot filter directive carried via GoRouter `extra` when the user
/// taps a dashboard panel ("View All" footer / KPI card). The destination
/// list screen consumes it exactly once — keyed by [token] — and applies it
/// through the VM's normal mutators so the datatable shows the *same records*
/// the panel showed, surfaced as real, removable filter chips.
///
/// Why `extra` and not query params: the master-detail `ShellRoute` builds
/// the list once with an invariant page key and reuses its Element on
/// same-route navigation, so a query-param/`listBuilder` approach silently
/// fails to re-filter an already-mounted list. The destination reads this
/// from `GoRouterState.of(context).extra` on every build and applies it via
/// [GenericListViewModel.applyDeepLinkIntent], which works in cold, warm,
/// and same-route-mounted cases.
@immutable
class ListFilterIntent {
  ListFilterIntent({
    this.extraFilters = const {},
    this.states,
    this.sortField,
    this.sortAscending,
    String? token,
  }) : token = token ?? 'lfi_${DateTime.now().microsecondsSinceEpoch}';

  /// Server-param → values written verbatim into the VM's `extraFilters`
  /// (e.g. `{'overdue': {'true'}}`, `{'client_status': {'expired'}}`). The
  /// keys must be the flat query params the v2 API accepts.
  final Map<String, Set<String>> extraFilters;

  /// Entity-lifecycle states. Null leaves the destination at its default
  /// (`{active}`); pass a set to force a specific lifecycle scope.
  final Set<EntityState>? states;

  /// Column id to sort by. Ignored when the destination VM doesn't
  /// recognise it (`isValidColumnId`).
  final String? sortField;
  final bool? sortAscending;

  /// Unique per navigation. The destination VM records the last token it
  /// consumed so a rebuild can't re-apply — and thereby clobber — a filter
  /// the user has since changed by hand.
  final String token;
}
