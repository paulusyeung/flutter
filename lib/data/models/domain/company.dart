import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/domain/document.dart';
// `Document` moved out of this file when Client and Product started carrying
// document arrays too. Re-exported so existing call sites that `import
// 'company.dart'` keep working without churn.
export 'package:admin/data/models/domain/document.dart';

part 'company.freezed.dart';

/// Domain `Company` — what the UI sees.
///
/// The settings blob is carried in two parallel shapes:
///  * [settings] — typed [CompanySettings], holds the ~200 fields the app
///    actively understands. Field mutations flow through this.
///  * [rawSettings] — the original server JSON map. Holds every key the
///    server sent, including the ~50 we haven't modeled.
///
/// On save we merge `{...rawSettings, ...settings.toJson()}` so the PUT body
/// preserves every unknown key alongside the user's typed edits. Without
/// this, fields like `mailgun_secret` or `e_invoice_type` would silently
/// disappear from the server on the first settings save.
///
/// `legalEntityId != 0` is the signal that this tenant has bound a legal
/// entity; the Details tab disables the `id_number` and `vat_number` fields
/// when set (matches React `Details.tsx`).
@freezed
abstract class Company with _$Company {
  const Company._();

  const factory Company({
    @Default('') String id,
    @Default('') String displayName,
    @Default('') String name,
    @Default('') String companyKey,
    @Default('') String sizeId,
    @Default('') String industryId,
    @Default('') String firstMonthOfYear,
    @Default('') String firstDayOfWeek,
    @Default(0) int enabledModules,
    @Default(0) int legalEntityId,
    @Default('') String subdomain,
    @Default('') String portalDomain,
    @Default('') String portalMode,
    @Default(<String, String>{}) Map<String, String> customFields,
    @Default(<String, dynamic>{}) Map<String, dynamic> rawSettings,
    @Default(CompanySettings()) CompanySettings settings,
    @Default(false) bool enableApplyingPayments,
    @Default(false) bool convertPaymentCurrency,
    @Default(0) int enabledTaxRates,
    @Default(0) int enabledItemTaxRates,
    @Default(0) int enabledExpenseTaxRates,
    @Default(false) bool calculateTaxes,
    TaxConfigApi? taxData,
    // Top-level product configuration. Edited by Settings → Product Settings;
    // round-trips through the outbox without touching the `settings` JSON.
    @Default(false) bool trackInventory,
    @Default(false) bool stockNotification,
    @Default(0) int inventoryNotificationThreshold,
    @Default(false) bool enableProductDiscount,
    @Default(false) bool enableProductCost,
    @Default(false) bool enableProductQuantity,
    @Default(false) bool defaultQuantity,
    @Default(false) bool showProductDetails,
    @Default(false) bool fillProducts,
    @Default(false) bool updateProducts,
    @Default(false) bool convertProducts,
    @Default(false) bool convertRateToClient,
    // Top-level workflow configuration. Edited by Settings → Workflow Settings
    // alongside the cascade `settings.*` workflow toggles.
    @Default(false) bool stopOnUnpaidRecurring,
    @Default(false) bool useQuoteTermsOnConversion,
    // Top-level task configuration. Edited by Settings → Task Settings.
    @Default(false) bool autoStartTasks,
    @Default(false) bool showTaskEndDate,
    @Default(false) bool showTasksTable,
    @Default(false) bool invoiceTaskDatelog,
    @Default(false) bool invoiceTaskTimelog,
    @Default(false) bool invoiceTaskHours,
    @Default(false) bool invoiceTaskItemDescription,
    @Default(false) bool invoiceTaskProject,
    @Default(false) bool invoiceTaskProjectHeader,
    @Default(false) bool invoiceTaskLock,
    @Default(false) bool invoiceTaskDocuments,
    // Top-level expense configuration. Edited by Settings → Expense Settings.
    // Cascade `defaultExpensePaymentTypeId` lives on `CompanySettings`. The
    // `inboundMailbox*` block is self-hosted only.
    @Default(false) bool markExpensesInvoiceable,
    @Default(false) bool markExpensesPaid,
    @Default(false) bool convertExpenseCurrency,
    @Default(false) bool invoiceExpenseDocuments,
    @Default(false) bool notifyVendorWhenPaid,
    @Default(false) bool calculateExpenseTaxByAmount,
    @Default(false) bool expenseInclusiveTaxes,
    @Default(false) bool expenseMailboxActive,
    @Default('') String expenseMailbox,
    @Default(false) bool inboundMailboxAllowCompanyUsers,
    @Default(false) bool inboundMailboxAllowVendors,
    @Default(false) bool inboundMailboxAllowClients,
    @Default('') String inboundMailboxWhitelist,
    @Default('') String inboundMailboxBlacklist,
    @Default(false) bool inboundMailboxAllowUnknown,
    @Default(<Document>[]) List<Document> documents,
    @Default(0) int updatedAt,
    @Default(0) int archivedAt,
  }) = _Company;

  factory Company.fromApi(CompanyApi api) => Company(
    id: api.id,
    displayName: api.displayName,
    name: api.name,
    companyKey: api.companyKey,
    sizeId: api.sizeId,
    industryId: api.industryId,
    firstMonthOfYear: api.firstMonthOfYear,
    firstDayOfWeek: api.firstDayOfWeek,
    enabledModules: api.enabledModules,
    legalEntityId: api.legalEntityId,
    subdomain: api.subdomain,
    portalDomain: api.portalDomain,
    portalMode: api.portalMode,
    customFields: api.customFields,
    rawSettings: api.settings,
    settings: CompanySettingsApi.fromJson(api.settings),
    enableApplyingPayments: api.enableApplyingPayments,
    convertPaymentCurrency: api.convertPaymentCurrency,
    enabledTaxRates: api.enabledTaxRates,
    enabledItemTaxRates: api.enabledItemTaxRates,
    enabledExpenseTaxRates: api.enabledExpenseTaxRates,
    calculateTaxes: api.calculateTaxes,
    taxData: api.taxData,
    trackInventory: api.trackInventory,
    stockNotification: api.stockNotification,
    inventoryNotificationThreshold: api.inventoryNotificationThreshold,
    enableProductDiscount: api.enableProductDiscount,
    enableProductCost: api.enableProductCost,
    enableProductQuantity: api.enableProductQuantity,
    defaultQuantity: api.defaultQuantity,
    showProductDetails: api.showProductDetails,
    fillProducts: api.fillProducts,
    updateProducts: api.updateProducts,
    convertProducts: api.convertProducts,
    convertRateToClient: api.convertRateToClient,
    stopOnUnpaidRecurring: api.stopOnUnpaidRecurring,
    useQuoteTermsOnConversion: api.useQuoteTermsOnConversion,
    autoStartTasks: api.autoStartTasks,
    showTaskEndDate: api.showTaskEndDate,
    showTasksTable: api.showTasksTable,
    invoiceTaskDatelog: api.invoiceTaskDatelog,
    invoiceTaskTimelog: api.invoiceTaskTimelog,
    invoiceTaskHours: api.invoiceTaskHours,
    invoiceTaskItemDescription: api.invoiceTaskItemDescription,
    invoiceTaskProject: api.invoiceTaskProject,
    invoiceTaskProjectHeader: api.invoiceTaskProjectHeader,
    invoiceTaskLock: api.invoiceTaskLock,
    invoiceTaskDocuments: api.invoiceTaskDocuments,
    markExpensesInvoiceable: api.markExpensesInvoiceable,
    markExpensesPaid: api.markExpensesPaid,
    convertExpenseCurrency: api.convertExpenseCurrency,
    invoiceExpenseDocuments: api.invoiceExpenseDocuments,
    notifyVendorWhenPaid: api.notifyVendorWhenPaid,
    calculateExpenseTaxByAmount: api.calculateExpenseTaxByAmount,
    expenseInclusiveTaxes: api.expenseInclusiveTaxes,
    expenseMailboxActive: api.expenseMailboxActive,
    expenseMailbox: api.expenseMailbox,
    inboundMailboxAllowCompanyUsers: api.inboundMailboxAllowCompanyUsers,
    inboundMailboxAllowVendors: api.inboundMailboxAllowVendors,
    inboundMailboxAllowClients: api.inboundMailboxAllowClients,
    inboundMailboxWhitelist: api.inboundMailboxWhitelist,
    inboundMailboxBlacklist: api.inboundMailboxBlacklist,
    inboundMailboxAllowUnknown: api.inboundMailboxAllowUnknown,
    documents: api.documents.map(Document.fromApi).toList(growable: false),
    updatedAt: api.updatedAt,
    archivedAt: api.archivedAt,
  );

  /// Build the PUT body. The `settings` map merges `rawSettings` (so unknown
  /// server keys round-trip) with the typed `settings.toJson()` (so the
  /// user's typed edits win).
  Map<String, dynamic> toApiJson() {
    final mergedSettings = <String, dynamic>{
      ...rawSettings,
      ...settings.toJson(),
    };
    return CompanyApi(
      id: id,
      displayName: displayName,
      name: name,
      companyKey: companyKey,
      sizeId: sizeId,
      industryId: industryId,
      firstMonthOfYear: firstMonthOfYear,
      firstDayOfWeek: firstDayOfWeek,
      enabledModules: enabledModules,
      legalEntityId: legalEntityId,
      subdomain: subdomain,
      portalDomain: portalDomain,
      portalMode: portalMode,
      customFields: customFields,
      settings: mergedSettings,
      enableApplyingPayments: enableApplyingPayments,
      convertPaymentCurrency: convertPaymentCurrency,
      enabledTaxRates: enabledTaxRates,
      enabledItemTaxRates: enabledItemTaxRates,
      enabledExpenseTaxRates: enabledExpenseTaxRates,
      calculateTaxes: calculateTaxes,
      taxData: taxData,
      trackInventory: trackInventory,
      stockNotification: stockNotification,
      inventoryNotificationThreshold: inventoryNotificationThreshold,
      enableProductDiscount: enableProductDiscount,
      enableProductCost: enableProductCost,
      enableProductQuantity: enableProductQuantity,
      defaultQuantity: defaultQuantity,
      showProductDetails: showProductDetails,
      fillProducts: fillProducts,
      updateProducts: updateProducts,
      convertProducts: convertProducts,
      convertRateToClient: convertRateToClient,
      stopOnUnpaidRecurring: stopOnUnpaidRecurring,
      useQuoteTermsOnConversion: useQuoteTermsOnConversion,
      autoStartTasks: autoStartTasks,
      showTaskEndDate: showTaskEndDate,
      showTasksTable: showTasksTable,
      invoiceTaskDatelog: invoiceTaskDatelog,
      invoiceTaskTimelog: invoiceTaskTimelog,
      invoiceTaskHours: invoiceTaskHours,
      invoiceTaskItemDescription: invoiceTaskItemDescription,
      invoiceTaskProject: invoiceTaskProject,
      invoiceTaskProjectHeader: invoiceTaskProjectHeader,
      invoiceTaskLock: invoiceTaskLock,
      invoiceTaskDocuments: invoiceTaskDocuments,
      markExpensesInvoiceable: markExpensesInvoiceable,
      markExpensesPaid: markExpensesPaid,
      convertExpenseCurrency: convertExpenseCurrency,
      invoiceExpenseDocuments: invoiceExpenseDocuments,
      notifyVendorWhenPaid: notifyVendorWhenPaid,
      calculateExpenseTaxByAmount: calculateExpenseTaxByAmount,
      expenseInclusiveTaxes: expenseInclusiveTaxes,
      expenseMailboxActive: expenseMailboxActive,
      expenseMailbox: expenseMailbox,
      inboundMailboxAllowCompanyUsers: inboundMailboxAllowCompanyUsers,
      inboundMailboxAllowVendors: inboundMailboxAllowVendors,
      inboundMailboxAllowClients: inboundMailboxAllowClients,
      inboundMailboxWhitelist: inboundMailboxWhitelist,
      inboundMailboxBlacklist: inboundMailboxBlacklist,
      inboundMailboxAllowUnknown: inboundMailboxAllowUnknown,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    ).toJson();
  }
}
