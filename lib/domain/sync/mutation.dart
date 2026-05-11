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
  restore;

  static MutationKind? tryParse(String raw) => switch (raw) {
    'create' => MutationKind.create,
    'update' => MutationKind.update,
    'delete' => MutationKind.delete,
    'archive' => MutationKind.archive,
    'restore' => MutationKind.restore,
    _ => null,
  };

  String get wireName => name;

  bool get isCreate => this == MutationKind.create;
  bool get isMutating =>
      this == MutationKind.create || this == MutationKind.update;
}
