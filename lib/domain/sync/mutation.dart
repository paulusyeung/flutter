/// Synthetic `entity_id` used by `MutationKind.reorder` outbox rows.
///
/// Reorder rows aren't keyed to a single entity — they carry a bulk-sort
/// payload (`{status_ids, task_ids}` for tasks, `{status_ids}` for
/// statuses). We park them under this constant so the outbox keeps its
/// non-null `entity_id` invariant; the Outbox screen renders them as
/// `Reorder &lt;entity&gt;` instead of `Sort #_sort` — see
/// `lib/ui/features/sync/views/outbox_screen.dart`.
const String kReorderEntityId = '_sort';

/// The kind of mutation queued in the outbox.
///
/// Stored as a plain TEXT column so M2+ can add new server-side actions
/// (`upload`, `action:send_email`, `action:mark_paid`, etc.) without a
/// schema migration. The enum here covers the M1 CRUD set; the helpers
/// translate to/from the stored string.
enum MutationKind {
  create,
  update,
  delete,
  archive,
  restore,
  purge,
  addComment,
  // Documents sub-system — same outbox pipeline, custom-actions dispatch.
  // `documentDelete` is password-gated server-side; entity repos that
  // expose documents must return true from `requiresPasswordFor` for it.
  documentUpload,
  documentDelete,
  documentVisibility,

  /// Bulk reorder — used by kanban drag-drop on tasks and by drag-handle
  /// reorder on task_statuses. Payload carries `{status_ids, task_ids}` or
  /// equivalent; `entityId` is a synthetic `'_sort'` because the row doesn't
  /// map to a single entity. Routed via `customActions` on the dispatcher.
  reorder;

  static MutationKind? tryParse(String raw) => switch (raw) {
    'create' => MutationKind.create,
    'update' => MutationKind.update,
    'delete' => MutationKind.delete,
    'archive' => MutationKind.archive,
    'restore' => MutationKind.restore,
    'purge' => MutationKind.purge,
    'add_comment' => MutationKind.addComment,
    'document_upload' => MutationKind.documentUpload,
    'document_delete' => MutationKind.documentDelete,
    'document_visibility' => MutationKind.documentVisibility,
    'reorder' => MutationKind.reorder,
    _ => null,
  };

  String get wireName => switch (this) {
    MutationKind.addComment => 'add_comment',
    MutationKind.documentUpload => 'document_upload',
    MutationKind.documentDelete => 'document_delete',
    MutationKind.documentVisibility => 'document_visibility',
    _ => name,
  };

  bool get isCreate => this == MutationKind.create;
  bool get isMutating =>
      this == MutationKind.create || this == MutationKind.update;
}
