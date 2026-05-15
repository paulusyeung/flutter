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
  reorder,

  /// `PUT /<recurring_entity>/{id}?start=true` — activate a recurring entity
  /// (Draft/Paused → Active). Payload is `{'id': id}`. Routed via
  /// `customActions` on each recurring entity's dispatcher.
  start,

  /// `PUT /<recurring_entity>/{id}?stop=true` — pause an Active recurring
  /// entity. Payload is `{'id': id}`. Routed via `customActions` on each
  /// recurring entity's dispatcher.
  stop,

  /// `POST /<billing_doc>/{id}/mark_sent` — flip Draft → Sent on an invoice/
  /// quote/credit/PO. Server returns the updated entity. Payload is
  /// `{'id': id}`. Routed via `customActions` on each billing-doc dispatcher.
  markSent,

  /// `POST /invoices/{id}/mark_paid` — mark an invoice as fully paid (server
  /// records a synthetic payment for the outstanding balance). Payload is
  /// `{'id': id}`. Invoice-only today; future Credit could reuse.
  markPaid,

  /// `POST /<billing_doc>/{id}/email` — send the entity via email using a
  /// named template. Payload carries `template`, optional `subject`, `body`,
  /// `cc_email`. Generic name (`emailEntity` not `emailInvoice`) so Quote /
  /// Credit / PO share the same kind.
  emailEntity,

  /// `POST /<billing_doc>/{id}/email?send_at=...` — schedule the email for a
  /// future date. Payload carries `template` + `send_at` (ISO date/time).
  scheduleEmail,

  /// `POST /invoices/{id}/clone_to_invoice` — duplicate this billing doc as
  /// a new invoice. Payload is `{'id': id}`. The five clone variants are
  /// destination-specific because the server route ends in the target type.
  cloneToInvoice,

  /// `POST /<billing_doc>/{id}/clone_to_quote`.
  cloneToQuote,

  /// `POST /<billing_doc>/{id}/clone_to_credit`.
  cloneToCredit,

  /// `POST /<billing_doc>/{id}/clone_to_recurring_invoice`.
  cloneToRecurring,

  /// `POST /<billing_doc>/{id}/clone_to_purchase_order`.
  cloneToPurchaseOrder,

  /// `POST /invoices/{id}/auto_bill` — charge the invoice against the
  /// client's stored payment token. Payload is `{'id': id}`.
  autoBill,

  /// `POST /<billing_doc>/{id}/cancel` — cancel a sent invoice/quote/etc.
  /// Server marks it cancelled but keeps the row. Payload is `{'id': id}`.
  /// Generic name (`cancelEntity` not `cancelInvoice`) so Quote/Credit/PO
  /// share the same kind.
  cancelEntity,

  /// `POST /<billing_doc>/bulk` with `action: template` — apply a design or
  /// email template to one or more entities. Payload carries `template_id`
  /// + entity id. Routed via `customActions`.
  runTemplate;

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
    'start' => MutationKind.start,
    'stop' => MutationKind.stop,
    'mark_sent' => MutationKind.markSent,
    'mark_paid' => MutationKind.markPaid,
    'email_entity' => MutationKind.emailEntity,
    'schedule_email' => MutationKind.scheduleEmail,
    'clone_to_invoice' => MutationKind.cloneToInvoice,
    'clone_to_quote' => MutationKind.cloneToQuote,
    'clone_to_credit' => MutationKind.cloneToCredit,
    'clone_to_recurring' => MutationKind.cloneToRecurring,
    'clone_to_purchase_order' => MutationKind.cloneToPurchaseOrder,
    'auto_bill' => MutationKind.autoBill,
    'cancel_entity' => MutationKind.cancelEntity,
    'run_template' => MutationKind.runTemplate,
    _ => null,
  };

  String get wireName => switch (this) {
    MutationKind.addComment => 'add_comment',
    MutationKind.documentUpload => 'document_upload',
    MutationKind.documentDelete => 'document_delete',
    MutationKind.documentVisibility => 'document_visibility',
    MutationKind.markSent => 'mark_sent',
    MutationKind.markPaid => 'mark_paid',
    MutationKind.emailEntity => 'email_entity',
    MutationKind.scheduleEmail => 'schedule_email',
    MutationKind.cloneToInvoice => 'clone_to_invoice',
    MutationKind.cloneToQuote => 'clone_to_quote',
    MutationKind.cloneToCredit => 'clone_to_credit',
    MutationKind.cloneToRecurring => 'clone_to_recurring',
    MutationKind.cloneToPurchaseOrder => 'clone_to_purchase_order',
    MutationKind.autoBill => 'auto_bill',
    MutationKind.cancelEntity => 'cancel_entity',
    MutationKind.runTemplate => 'run_template',
    _ => name,
  };

  bool get isCreate => this == MutationKind.create;
  bool get isMutating =>
      this == MutationKind.create || this == MutationKind.update;
}
