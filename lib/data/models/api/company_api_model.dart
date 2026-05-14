import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';

// `DocumentApi` moved out of this file when Client and Product also started
// carrying document arrays. Re-exported so existing call sites keep working
// with no import churn.
export 'package:admin/data/models/api/document_api_model.dart';

part 'company_api_model.freezed.dart';
part 'company_api_model.g.dart';

/// Wire shape of `/api/v1/companies/{id}` (also embedded in `/auth/me` via
/// `CompanyEnvelopeApi`).
///
/// `settings` stays as a raw map for the same reason it does on
/// [CompanyEnvelopeApi] — the typed model only covers ~200 of ~250 server
/// fields, and round-tripping through it would drop the others silently.
/// Callers build the typed view via `CompanySettingsApi.fromJson(settings)`
/// when they need to read individual fields.
@freezed
abstract class CompanyApi with _$CompanyApi {
  @JsonSerializable(includeIfNull: false)
  const factory CompanyApi({
    @Default('') String id,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String name,
    @JsonKey(name: 'company_key') @Default('') String companyKey,
    @JsonKey(name: 'size_id') @Default('') String sizeId,
    @JsonKey(name: 'industry_id') @Default('') String industryId,
    @JsonKey(name: 'first_month_of_year') @Default('') String firstMonthOfYear,
    @JsonKey(name: 'first_day_of_week') @Default('') String firstDayOfWeek,
    @JsonKey(name: 'enabled_modules') @Default(0) int enabledModules,
    @JsonKey(name: 'legal_entity_id') @Default(0) int legalEntityId,
    @JsonKey(name: 'subdomain') @Default('') String subdomain,
    @JsonKey(name: 'portal_domain') @Default('') String portalDomain,
    @JsonKey(name: 'portal_mode') @Default('') String portalMode,
    @JsonKey(name: 'custom_fields')
    @Default(<String, String>{})
    Map<String, String> customFields,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    @JsonKey(name: 'enable_applying_payments')
    @Default(false)
    bool enableApplyingPayments,
    @JsonKey(name: 'convert_payment_currency')
    @Default(false)
    bool convertPaymentCurrency,
    // ── Tax configuration ────────────────────────────────────────────────
    // The three count fields, `calculate_taxes` and `tax_data` live at
    // company top-level, not in settings — matching the server contract
    // and the legacy admin-portal / React clients.
    @JsonKey(name: 'enabled_tax_rates') @Default(0) int enabledTaxRates,
    @JsonKey(name: 'enabled_item_tax_rates')
    @Default(0)
    int enabledItemTaxRates,
    @JsonKey(name: 'enabled_expense_tax_rates')
    @Default(0)
    int enabledExpenseTaxRates,
    @JsonKey(name: 'calculate_taxes') @Default(false) bool calculateTaxes,
    @JsonKey(name: 'tax_data') TaxConfigApi? taxData,
    // ── Product configuration ───────────────────────────────────────────
    // Top-level company fields edited by Settings → Product Settings.
    // Defaults stay false/0 so a fresh CompanyApi constructor doesn't
    // invent values; `Company.fromApi` always overlays whatever the wire
    // sent.
    @JsonKey(name: 'track_inventory') @Default(false) bool trackInventory,
    @JsonKey(name: 'stock_notification')
    @Default(false)
    bool stockNotification,
    @JsonKey(name: 'inventory_notification_threshold')
    @Default(0)
    int inventoryNotificationThreshold,
    @JsonKey(name: 'enable_product_discount')
    @Default(false)
    bool enableProductDiscount,
    @JsonKey(name: 'enable_product_cost')
    @Default(false)
    bool enableProductCost,
    @JsonKey(name: 'enable_product_quantity')
    @Default(false)
    bool enableProductQuantity,
    @JsonKey(name: 'default_quantity') @Default(false) bool defaultQuantity,
    @JsonKey(name: 'show_product_details')
    @Default(false)
    bool showProductDetails,
    @JsonKey(name: 'fill_products') @Default(false) bool fillProducts,
    @JsonKey(name: 'update_products') @Default(false) bool updateProducts,
    @JsonKey(name: 'convert_products') @Default(false) bool convertProducts,
    @JsonKey(name: 'convert_rate_to_client')
    @Default(false)
    bool convertRateToClient,
    // ── Workflow ────────────────────────────────────────────────────────
    // Top-level company fields edited by Settings → Workflow Settings.
    // Only the company-scope rows on that page; the per-entity workflow
    // toggles live under `settings.*` (auto_email_invoice, lock_invoices,
    // etc.) on `CompanySettingsApi`.
    @JsonKey(name: 'stop_on_unpaid_recurring')
    @Default(false)
    bool stopOnUnpaidRecurring,
    @JsonKey(name: 'use_quote_terms_on_conversion')
    @Default(false)
    bool useQuoteTermsOnConversion,
    // ── Task configuration ──────────────────────────────────────────────
    // Top-level company fields edited by Settings → Task Settings. Per-entity
    // task toggles (`default_task_rate`, `task_round_up`, …) live on
    // `CompanySettingsApi`. `invoiceTaskProjectHeader`: false = service,
    // true = description (parity with legacy admin-portal).
    @JsonKey(name: 'auto_start_tasks') @Default(false) bool autoStartTasks,
    @JsonKey(name: 'show_task_end_date') @Default(false) bool showTaskEndDate,
    @JsonKey(name: 'show_tasks_table') @Default(false) bool showTasksTable,
    @JsonKey(name: 'invoice_task_datelog')
    @Default(false)
    bool invoiceTaskDatelog,
    @JsonKey(name: 'invoice_task_timelog')
    @Default(false)
    bool invoiceTaskTimelog,
    @JsonKey(name: 'invoice_task_hours') @Default(false) bool invoiceTaskHours,
    @JsonKey(name: 'invoice_task_item_description')
    @Default(false)
    bool invoiceTaskItemDescription,
    @JsonKey(name: 'invoice_task_project')
    @Default(false)
    bool invoiceTaskProject,
    @JsonKey(name: 'invoice_task_project_header')
    @Default(false)
    bool invoiceTaskProjectHeader,
    @JsonKey(name: 'invoice_task_lock') @Default(false) bool invoiceTaskLock,
    @JsonKey(name: 'invoice_task_documents')
    @Default(false)
    bool invoiceTaskDocuments,
    @Default(<DocumentApi>[]) List<DocumentApi> documents,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
  }) = _CompanyApi;

  factory CompanyApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyApiFromJson(json);
}

/// Envelope for `/api/v1/companies/{id}` item responses (`{ data: ... }`).
@freezed
abstract class CompanyItemApi with _$CompanyItemApi {
  const factory CompanyItemApi({required CompanyApi data}) = _CompanyItemApi;

  factory CompanyItemApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyItemApiFromJson(json);
}
