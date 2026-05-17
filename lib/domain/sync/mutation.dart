/// Synthetic `entity_id` used by `MutationKind.reorder` outbox rows.
///
/// Reorder rows aren't keyed to a single entity — they carry a bulk-sort
/// payload (`{status_ids, task_ids}` for tasks, `{status_ids}` for
/// statuses). We park them under this constant so the outbox keeps its
/// non-null `entity_id` invariant; the Outbox screen renders them as
/// `Reorder &lt;entity&gt;` instead of `Sort #_sort` — see
/// `lib/ui/features/sync/views/outbox_screen.dart`.
const String kReorderEntityId = '_sort';

/// Synthetic `entity_id` used by `MutationKind.refreshAccounts` outbox
/// rows. Refresh rows aren't keyed to a single bank integration —
/// `POST /bank_integrations/refresh_accounts` is a tenant-wide refresh.
const String kRefreshAccountsEntityId = '_refresh';

/// Synthetic `entity_id` used by `MutationKind.convertMatched` and
/// `MutationKind.unlinkTransaction` outbox rows. The payload carries the
/// full `ids` array; this constant lets the outbox enforce its
/// non-null `entity_id` invariant without picking one transaction id
/// arbitrarily.
const String kBulkTransactionEntityId = '_bulk';

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
  runTemplate,

  /// `POST /quotes/{id}/approve` — manually mark a quote as approved by
  /// the client (override of the portal-driven flow). Quote-only.
  /// Payload is `{'id': id}`.
  approve,

  /// `POST /quotes/{id}/convert_to_invoice` — spawn an invoice from this
  /// quote. Server returns the new invoice envelope; the dispatcher
  /// returns null so the source row stays untouched (the new entity
  /// lands via a refresh or explicit navigation).
  convertToInvoice,

  /// `POST /quotes/{id}/convert_to_project` — spawn a project from this
  /// quote. Same null-return contract as `convertToInvoice`.
  convertToProject,

  /// `POST /purchase_orders/{id}/accept` — server-side mark-accepted for
  /// purchase orders (vendor-confirmed). PO-only.
  /// Payload is `{'id': id}`.
  acceptOrder,

  /// `POST /purchase_orders/{id}/expense` — convert a received purchase
  /// order into an expense (receipt). PO-only.
  /// Payload is `{'id': id}`.
  convertToExpense,

  /// `POST /recurring_invoices/{id}/send_now` — fire a one-off generation
  /// of the next invoice from this template, regardless of the schedule.
  /// RecurringInvoice-only. Payload is `{'id': id}`.
  sendNow,

  // ── E-Invoice / PEPPOL — Company-only custom actions ────────────────
  // All eight routes off `CompanySyncDispatcher`. The certificate upload
  // is a multipart POST; the rest are JSON. Each carries its own payload
  // shape (documented next to the corresponding method on
  // `CompaniesApi` / `CompanyRepository`).

  /// `POST /api/v1/companies/{id}/upload` with field `e_invoice_certificate`
  /// — multipart upload of a .p12 / .pfx / .pem / etc. certificate. Payload
  /// carries `{local_path}`; the dispatcher reads the file at send-time so
  /// the upload survives an app kill between save and network availability.
  uploadEInvoiceCertificate,

  /// `POST /api/v1/einvoice/peppol/setup` — bind a tenant to PEPPOL.
  /// Payload mirrors React `peppol/Onboarding.tsx`: party name, address,
  /// classification, sender/receiver, tenant_id.
  peppolSetup,

  /// `PUT /api/v1/einvoice/peppol/update` — change PEPPOL preferences
  /// (`acts_as_sender` / `acts_as_receiver`). Auto-fired by the
  /// Preferences card toggles, debounced.
  peppolUpdate,

  /// `POST /api/v1/einvoice/peppol/disconnect` — disconnect this tenant
  /// from PEPPOL.
  peppolDisconnect,

  /// `POST /api/v1/einvoice/peppol/add_additional_legal_identifier` — add
  /// a per-country VAT identifier (multi-country PEPPOL operation).
  /// Payload: `{country, vat_number}`.
  peppolAddTaxIdentifier,

  /// `DELETE /api/v1/einvoice/peppol/remove_additional_legal_identifier`
  /// — remove a per-country VAT identifier. Payload: `{country, vat_number}`.
  peppolRemoveTaxIdentifier,

  /// `POST /api/v1/einvoice/configurations` — save payment-means
  /// configuration (code + conditional IBAN/BIC/card sub-fields).
  eInvoicePaymentMeans,

  /// `POST /api/v1/einvoice/token/update` — regenerate the e-invoicing
  /// token. Surfaced by the Preferences card when the health-check
  /// endpoint reports the current token unhealthy.
  regenerateEInvoiceToken,

  // ── Bank Accounts / Transactions ───────────────────────────────────
  /// `POST /api/v1/bank_integrations/refresh_accounts` — ask the upstream
  /// provider (Yodlee/Nordigen) to refresh balances + the connected
  /// account list. No payload.
  refreshAccounts,

  /// `POST /api/v1/bank_transactions/match` (CREDIT, create payment) —
  /// payload: `{transactions: [{id, invoice_ids: "id1,id2"}]}`.
  matchToPayment,

  /// `POST /api/v1/bank_transactions/match` (CREDIT, link existing
  /// payment) — payload: `{transactions: [{id, payment_id}]}`.
  linkToPayment,

  /// `POST /api/v1/bank_transactions/match` (DEBIT, create expense) —
  /// payload: `{transactions: [{id, vendor_id, ninja_category_id}]}`.
  matchToExpense,

  /// `POST /api/v1/bank_transactions/match` (DEBIT, link existing
  /// expense) — payload: `{transactions: [{id, expense_id}]}`.
  linkToExpense,

  /// `POST /api/v1/bank_transactions/bulk` with `action=convert_matched`
  /// — convert matched rows into expenses/payments server-side.
  convertMatched,

  /// `POST /api/v1/bank_transactions/bulk` with `action=unlink` —
  /// detach a matched/converted row from its linked entities.
  unlinkTransaction,

  // ── User Management — non-CRUD user actions ────────────────────────
  /// `POST /api/v1/users/{id}/invite` — resend the invitation email to a
  /// pending user. Payload is `{'id': id}`. Routed via `customActions`
  /// on the User dispatcher.
  inviteUser,

  /// `DELETE /api/v1/users/{id}/detach_from_company` — remove the user
  /// from this company without deleting their user record (they still
  /// exist and may belong to other companies). Payload is `{'id': id}`.
  /// Routed via `customActions` on the User dispatcher.
  detachFromCompany,

  // ── Payments — non-CRUD payment actions ────────────────────────────
  /// `POST /api/v1/payments/refund?email_receipt=<bool>[&gateway_refund=true]`
  /// — refund a completed payment, optionally back through the gateway.
  /// Payload carries `{id, date, invoices: [{invoice_id, amount, id: ""}],
  /// send_email, gateway_refund}`. Server returns the updated payment.
  /// Routed via `customActions` on the Payment dispatcher.
  refundPayment,

  /// `PUT /api/v1/payments/{id}` with `{invoices: [{_id, amount, invoice_id,
  /// credit_id?, number?}]}` — apply unapplied payment funds to one or more
  /// invoices. Server returns the updated payment. Routed via `customActions`
  /// on the Payment dispatcher.
  applyPayment,

  /// `POST /api/v1/clients/{merge_into_id}/{merge_from_id}/merge` — absorb
  /// `merge_from` into `merge_into` (survivor). No body; password-gated
  /// (412), same as client delete/purge. Routed via `customActions` on the
  /// Client dispatcher; the absorbed client's local row is removed and the
  /// survivor upserted from the response.
  merge,

  /// Client locations are a standalone `/api/v1/locations` resource (POST /
  /// PUT / DELETE) that is *read-embedded* on the client. These three kinds
  /// route via `customActions` on the Client dispatcher; each handler calls
  /// `LocationsApi` then refreshes the parent client so `client.locations[]`
  /// reflects the change.
  locationCreate,
  locationUpdate,
  locationDelete,

  /// Invoice payment schedule. `paymentScheduleCreate` →
  /// `POST /invoices/{id}/payment_schedule` (number-of-payments flow);
  /// `paymentScheduleCreateCustom` → `POST /task_schedulers` (explicit
  /// rows); `paymentScheduleDelete` → `DELETE /invoices/{id}/payment_schedule`.
  /// Routed via `customActions` on the Invoice dispatcher; each handler
  /// re-fetches the invoice with `?show_schedule=true` so `invoice.schedule[]`
  /// reflects the change.
  paymentScheduleCreate,
  paymentScheduleCreateCustom,
  paymentScheduleDelete;

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
    'approve' => MutationKind.approve,
    'convert_to_invoice' => MutationKind.convertToInvoice,
    'convert_to_project' => MutationKind.convertToProject,
    'accept_order' => MutationKind.acceptOrder,
    'convert_to_expense' => MutationKind.convertToExpense,
    'send_now' => MutationKind.sendNow,
    'upload_e_invoice_certificate' => MutationKind.uploadEInvoiceCertificate,
    'peppol_setup' => MutationKind.peppolSetup,
    'peppol_update' => MutationKind.peppolUpdate,
    'peppol_disconnect' => MutationKind.peppolDisconnect,
    'peppol_add_tax_identifier' => MutationKind.peppolAddTaxIdentifier,
    'peppol_remove_tax_identifier' => MutationKind.peppolRemoveTaxIdentifier,
    'e_invoice_payment_means' => MutationKind.eInvoicePaymentMeans,
    'regenerate_e_invoice_token' => MutationKind.regenerateEInvoiceToken,
    'refresh_accounts' => MutationKind.refreshAccounts,
    'match_to_payment' => MutationKind.matchToPayment,
    'link_to_payment' => MutationKind.linkToPayment,
    'match_to_expense' => MutationKind.matchToExpense,
    'link_to_expense' => MutationKind.linkToExpense,
    'convert_matched' => MutationKind.convertMatched,
    'unlink_transaction' => MutationKind.unlinkTransaction,
    'invite_user' => MutationKind.inviteUser,
    'detach_from_company' => MutationKind.detachFromCompany,
    'refund_payment' => MutationKind.refundPayment,
    'apply_payment' => MutationKind.applyPayment,
    'merge' => MutationKind.merge,
    'location_create' => MutationKind.locationCreate,
    'location_update' => MutationKind.locationUpdate,
    'location_delete' => MutationKind.locationDelete,
    'payment_schedule_create' => MutationKind.paymentScheduleCreate,
    'payment_schedule_create_custom' =>
      MutationKind.paymentScheduleCreateCustom,
    'payment_schedule_delete' => MutationKind.paymentScheduleDelete,
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
    MutationKind.approve => 'approve',
    MutationKind.convertToInvoice => 'convert_to_invoice',
    MutationKind.convertToProject => 'convert_to_project',
    MutationKind.acceptOrder => 'accept_order',
    MutationKind.convertToExpense => 'convert_to_expense',
    MutationKind.sendNow => 'send_now',
    MutationKind.uploadEInvoiceCertificate => 'upload_e_invoice_certificate',
    MutationKind.peppolSetup => 'peppol_setup',
    MutationKind.peppolUpdate => 'peppol_update',
    MutationKind.peppolDisconnect => 'peppol_disconnect',
    MutationKind.peppolAddTaxIdentifier => 'peppol_add_tax_identifier',
    MutationKind.peppolRemoveTaxIdentifier => 'peppol_remove_tax_identifier',
    MutationKind.eInvoicePaymentMeans => 'e_invoice_payment_means',
    MutationKind.regenerateEInvoiceToken => 'regenerate_e_invoice_token',
    MutationKind.refreshAccounts => 'refresh_accounts',
    MutationKind.matchToPayment => 'match_to_payment',
    MutationKind.linkToPayment => 'link_to_payment',
    MutationKind.matchToExpense => 'match_to_expense',
    MutationKind.linkToExpense => 'link_to_expense',
    MutationKind.convertMatched => 'convert_matched',
    MutationKind.unlinkTransaction => 'unlink_transaction',
    MutationKind.inviteUser => 'invite_user',
    MutationKind.detachFromCompany => 'detach_from_company',
    MutationKind.refundPayment => 'refund_payment',
    MutationKind.applyPayment => 'apply_payment',
    MutationKind.merge => 'merge',
    MutationKind.locationCreate => 'location_create',
    MutationKind.locationUpdate => 'location_update',
    MutationKind.locationDelete => 'location_delete',
    MutationKind.paymentScheduleCreate => 'payment_schedule_create',
    MutationKind.paymentScheduleCreateCustom =>
      'payment_schedule_create_custom',
    MutationKind.paymentScheduleDelete => 'payment_schedule_delete',
    _ => name,
  };

  bool get isCreate => this == MutationKind.create;
  bool get isMutating =>
      this == MutationKind.create || this == MutationKind.update;
}
