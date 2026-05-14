import 'package:flutter/foundation.dart';

import 'package:admin/domain/entity_type.dart';

/// A named snapshot of a list-screen's filter+sort+search state. Local-only
/// (no API endpoint). Persisted in the `saved_views` Drift table; surfaced
/// in the sidebar's "Saved" section and the bookmark sheet on each entity
/// list screen.
@immutable
class SavedView {
  const SavedView({
    required this.id,
    required this.companyId,
    required this.entityType,
    required this.name,
    required this.snapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final EntityType entityType;
  final String name;

  /// Decoded payload — same shape as the per-entity slot inside
  /// `nav_state.filters_json`: keys `search`, `states`, `sortField`,
  /// `sortAscending`, `customFilters`, `extraFilters`.
  final Map<String, dynamic> snapshot;

  final int createdAt;
  final int updatedAt;
}
