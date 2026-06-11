/// All entity types this app knows about.
///
/// New entities arrive in later milestones by adding to this enum AND adding
/// an entry to `EntityRegistry` (lib/domain/entity_registry.dart). The
/// registry is the central source of truth for icons, API paths, route paths,
/// parent/child relationships, and which mutations require a password.
enum EntityType {
  // Customers + sales
  client,
  invoice,
  quote,
  credit,
  payment,
  recurringInvoice,
  purchaseOrder,

  // Time + work
  project,
  task,
  taskStatus,
  tag,

  // Vendors + expenses
  vendor,
  expense,
  expenseCategory,
  recurringExpense,

  // Catalog
  product,

  // Banking
  bankAccount,
  transaction,
  transactionRule,

  // Org / access
  user,
  group,
  token,
  webhook,

  // Configuration
  paymentTerm,
  design,
  taxRate,
  companyGateway,
  schedule,
  paymentLink,

  // Misc
  document,

  // Singleton: one per tenant, loaded from /auth/me. Updates land via the
  // outbox like any other entity but there's no list/create/delete flow —
  // only update + uploads (logo, documents).
  company,
}
