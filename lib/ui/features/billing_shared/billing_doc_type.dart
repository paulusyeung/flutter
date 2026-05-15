/// The five entity types that share line items, taxes, totals, contacts,
/// designs, PDF rendering, and email — invoice / quote / credit /
/// purchase_order / recurring_invoice. Used by widgets in
/// `lib/ui/features/billing_shared/` to branch on entity-specific copy
/// without importing the entity domain models (which keeps the shared
/// layer independent of any single entity).
enum BillingDocType {
  invoice,
  quote,
  credit,
  purchaseOrder,
  recurringInvoice;

  /// Wire name used in API paths (`/api/v1/invoices`, `/api/v1/quotes`,
  /// `/api/v1/credits`, `/api/v1/purchase_orders`, `/api/v1/recurring_invoices`).
  String get wireName => switch (this) {
    BillingDocType.invoice => 'invoice',
    BillingDocType.quote => 'quote',
    BillingDocType.credit => 'credit',
    BillingDocType.purchaseOrder => 'purchase_order',
    BillingDocType.recurringInvoice => 'recurring_invoice',
  };

  /// Pluralized API path segment.
  String get apiPath => switch (this) {
    BillingDocType.invoice => '/api/v1/invoices',
    BillingDocType.quote => '/api/v1/quotes',
    BillingDocType.credit => '/api/v1/credits',
    BillingDocType.purchaseOrder => '/api/v1/purchase_orders',
    BillingDocType.recurringInvoice => '/api/v1/recurring_invoices',
  };

  /// i18n key for the singular form ("Invoice", "Quote", …). Resolved via
  /// `context.tr(type.singularLabelKey)`.
  String get singularLabelKey => switch (this) {
    BillingDocType.invoice => 'invoice',
    BillingDocType.quote => 'quote',
    BillingDocType.credit => 'credit',
    BillingDocType.purchaseOrder => 'purchase_order',
    BillingDocType.recurringInvoice => 'recurring_invoice',
  };

  /// i18n key for the plural form ("Invoices", "Quotes", …).
  String get pluralLabelKey => switch (this) {
    BillingDocType.invoice => 'invoices',
    BillingDocType.quote => 'quotes',
    BillingDocType.credit => 'credits',
    BillingDocType.purchaseOrder => 'purchase_orders',
    BillingDocType.recurringInvoice => 'recurring_invoices',
  };

  /// Delivery-note PDF variant is invoice-only (admin-portal endpoint:
  /// `POST /api/v1/invoices/{id}/delivery_note`). Other billing docs hide
  /// the toggle.
  bool get supportsDeliveryNote => this == BillingDocType.invoice;
}
