import 'package:drift/drift.dart';

/// Per-company envelope cached locally. The auth response (`LoginResponse`)
/// returns one of these per company the user has access to.
///
/// `settings` is the company settings blob; `permissions` is the per-company
/// permissions map; the rest is metadata shown in the company switcher.
@DataClassName('CompanyRow')
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get displayName => text().named('display_name').nullable()();
  // Logo URL persisted as its own column so the switcher doesn't depend on
  // the `settings` JSON round-tripping cleanly through codegen + SQLite +
  // jsonDecode. Populated at login; older rows get healed by the v7
  // migration via `json_extract(settings, '$.company_logo')`.
  TextColumn get logoUrl => text().named('logo_url').nullable()();
  TextColumn get settings => text()();
  TextColumn get permissions => text()();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get token => text()();
  // Top-level company fields that don't live inside `settings`. Stored so
  // the Company Details page can edit and round-trip them without a fresh
  // /auth/me. `custom_fields` is the `{ company1: "Label|type", ... }` map.
  TextColumn get customFields =>
      text().named('custom_fields').withDefault(const Constant('{}'))();
  TextColumn get sizeId =>
      text().named('size_id').withDefault(const Constant(''))();
  TextColumn get industryId =>
      text().named('industry_id').withDefault(const Constant(''))();
  IntColumn get legalEntityId =>
      integer().named('legal_entity_id').withDefault(const Constant(0))();
  BoolColumn get isAdmin =>
      boolean().named('is_admin').withDefault(const Constant(false))();
  BoolColumn get isOwner =>
      boolean().named('is_owner').withDefault(const Constant(false))();
  // JSON-encoded list of attachments returned on the company response.
  // Nullable so the v12 migration can `addColumn` without a backfill — the
  // next `applyUpdateResponse` (or `/auth/me`) repopulates it.
  TextColumn get documents => text().nullable()();
  // Top-level tax configuration. Mirrors `CompanyApi.enabledTaxRates` /
  // `enabledItemTaxRates` / `enabledExpenseTaxRates` / `calculateTaxes` /
  // `taxData`. The Settings → Tax Settings UI edits these and round-trips
  // them through the outbox without touching the `settings` JSON.
  IntColumn get enabledTaxRates =>
      integer().named('enabled_tax_rates').withDefault(const Constant(0))();
  IntColumn get enabledItemTaxRates => integer()
      .named('enabled_item_tax_rates')
      .withDefault(const Constant(0))();
  IntColumn get enabledExpenseTaxRates => integer()
      .named('enabled_expense_tax_rates')
      .withDefault(const Constant(0))();
  BoolColumn get calculateTaxes =>
      boolean().named('calculate_taxes').withDefault(const Constant(false))();
  // `tax_data` JSON map. Nullable: older companies (and self-hosted
  // installs that haven't been touched recently) ship without it; the UI
  // treats null as "no regions provisioned yet".
  TextColumn get taxDataJson => text().named('tax_data_json').nullable()();
  // Top-level product configuration. Settings → Product Settings round-trips
  // these through the outbox without touching the `settings` JSON. Defaults
  // are false/0; real values land on first `applyUpdateResponse` / login.
  BoolColumn get trackInventory =>
      boolean().named('track_inventory').withDefault(const Constant(false))();
  BoolColumn get stockNotification => boolean()
      .named('stock_notification')
      .withDefault(const Constant(false))();
  IntColumn get inventoryNotificationThreshold => integer()
      .named('inventory_notification_threshold')
      .withDefault(const Constant(0))();
  BoolColumn get enableProductDiscount => boolean()
      .named('enable_product_discount')
      .withDefault(const Constant(false))();
  BoolColumn get enableProductCost => boolean()
      .named('enable_product_cost')
      .withDefault(const Constant(false))();
  BoolColumn get enableProductQuantity => boolean()
      .named('enable_product_quantity')
      .withDefault(const Constant(false))();
  BoolColumn get defaultQuantity =>
      boolean().named('default_quantity').withDefault(const Constant(false))();
  BoolColumn get showProductDetails => boolean()
      .named('show_product_details')
      .withDefault(const Constant(false))();
  BoolColumn get fillProducts =>
      boolean().named('fill_products').withDefault(const Constant(false))();
  BoolColumn get updateProducts =>
      boolean().named('update_products').withDefault(const Constant(false))();
  BoolColumn get convertProducts =>
      boolean().named('convert_products').withDefault(const Constant(false))();
  BoolColumn get convertRateToClient => boolean()
      .named('convert_rate_to_client')
      .withDefault(const Constant(false))();
  // Top-level workflow configuration. Edited by Settings → Workflow Settings;
  // the per-entity workflow toggles (auto_email_invoice, lock_invoices, etc.)
  // ride along in the `settings` JSON blob.
  BoolColumn get stopOnUnpaidRecurring => boolean()
      .named('stop_on_unpaid_recurring')
      .withDefault(const Constant(false))();
  BoolColumn get useQuoteTermsOnConversion => boolean()
      .named('use_quote_terms_on_conversion')
      .withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Account-level info (one row per logged-in user). Stores hosted-vs-self
/// hosted, plan, trial info, feature flags, etc. — anything that's per-user
/// rather than per-company.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get plan => text()();
  IntColumn get numTrialDays => integer().named('num_trial_days')();
  BoolColumn get isHosted =>
      boolean().named('is_hosted').withDefault(const Constant(false))();
  TextColumn get defaultCompanyId =>
      text().named('default_company_id').nullable()();
  TextColumn get featuresJson => text().named('features_json').nullable()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
