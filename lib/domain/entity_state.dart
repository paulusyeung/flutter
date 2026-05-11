/// The lifecycle state of a server-side entity row.
///
/// Persisted on every entity table as two columns: `archived_at` (timestamp
/// or null) and `is_deleted` (bool). The three states map as:
///   * [active]   — `archivedAt == null && !isDeleted`
///   * [archived] — `archivedAt != null && !isDeleted`
///   * [deleted]  — `isDeleted == true` (overrides archived)
///
/// On the wire, `client_status=active,archived,deleted` is the query param
/// the server accepts; [serverName] is the camelCase value's canonical name.
enum EntityState {
  active,
  archived,
  deleted;

  /// The token the v2 server expects in the `client_status` (or equivalent)
  /// filter query string.
  String get serverName => switch (this) {
    EntityState.active => 'active',
    EntityState.archived => 'archived',
    EntityState.deleted => 'deleted',
  };

  /// Localization key for the user-facing label, also used as the
  /// active-filter chip text. Resolve via `context.tr(state.labelKey)`.
  String get labelKey => switch (this) {
    EntityState.active => 'active',
    EntityState.archived => 'archived',
    EntityState.deleted => 'deleted',
  };
}
