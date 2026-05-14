import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('CompanyRepository');

/// Source of truth for the active company row. Companies are loaded into the
/// `companies` Drift table by [AuthRepository] at login; this repo provides
/// the typed watch stream the settings UI binds to, plus the outbox-backed
/// update path.
///
/// Unlike most entities there is no create/delete/archive flow — a company's
/// lifecycle is managed at the account level. Logo + document uploads still
/// go through the outbox so they survive offline.
class CompanyRepository extends BaseEntityRepository<Company, CompanyApi> {
  CompanyRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
  }) : super(entityType: EntityType.company);

  final CompaniesApi api;

  @override
  String get entityTypeName => 'company';

  /// Delete-company is destructive and requires the user's password — flag
  /// the outbox row so the sync engine includes `X-API-PASSWORD-BASE64`.
  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || super.requiresPasswordFor(kind);

  /// Enqueue a Danger-Zone delete. Returns the outbox row id so the caller
  /// can poll for the row's terminal state after the drain.
  Future<int> deleteCompany({
    required String companyId,
    required String cancellationMessage,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: companyId,
      kind: MutationKind.delete,
      payload: {'cancellation_message': cancellationMessage},
    );
  }

  /// Watch the active company. Decodes the `settings` JSON blob on every
  /// emission; the UI binds to this directly.
  ///
  /// Distinct from [BaseEntityRepository.watch] because company is a
  /// settings-only entity — there is no separate `(companyId, id)` tuple,
  /// the company *is* the row keyed by `companyId`. The generic `watch`
  /// machinery (tmp-id remap, id_remap subscription) doesn't apply.
  Stream<Company?> watchCompany(String companyId) {
    return db.companiesDao.watchById(companyId).map(_fromRow);
  }

  @override
  Stream<Company?> watchByRealId({
    required String companyId,
    required String id,
  }) => throw UnsupportedError(
    'CompanyRepository is settings-only; use watchCompany(companyId) instead.',
  );

  Future<Company?> get(String companyId) async {
    final row = await db.companiesDao.byId(companyId);
    return _fromRow(row);
  }

  /// Persist a settings change. Writes the new settings JSON to Drift
  /// (optimistic) and enqueues a `PUT /companies/{id}` outbox row.
  Future<void> updateCompany({required Company draft}) async {
    final body = draft.toApiJson();
    // Merge raw + typed exactly as `toApiJson` does so the on-disk row
    // matches what we POST. Without this, fields the model doesn't cover
    // would disappear from the local cache after each save.
    final mergedSettings = <String, dynamic>{
      ...draft.rawSettings,
      ...draft.settings.toJson(),
    };
    await db.transaction(() async {
      await (db.update(
        db.companies,
      )..where((c) => c.id.equals(draft.id))).write(
        CompaniesCompanion(
          displayName: Value(
            draft.displayName.isNotEmpty ? draft.displayName : null,
          ),
          name: Value(
            draft.name.isNotEmpty ? draft.name : draft.settings.name ?? '',
          ),
          settings: Value(jsonEncode(mergedSettings)),
          customFields: Value(jsonEncode(draft.customFields)),
          sizeId: Value(draft.sizeId),
          industryId: Value(draft.industryId),
          legalEntityId: Value(draft.legalEntityId),
          enabledModules: Value(draft.enabledModules),
          googleAnalyticsKey: Value(draft.googleAnalyticsKey),
          matomoId: Value(draft.matomoId),
          matomoUrl: Value(draft.matomoUrl),
          sessionTimeout: Value(draft.sessionTimeout),
          defaultPasswordTimeout: Value(draft.defaultPasswordTimeout),
          oauthPasswordRequired: Value(draft.oauthPasswordRequired),
          isDisabled: Value(draft.isDisabled),
          markdownEnabled: Value(draft.markdownEnabled),
          markdownEmailEnabled: Value(draft.markdownEmailEnabled),
          reportIncludeDrafts: Value(draft.reportIncludeDrafts),
          reportIncludeDeleted: Value(draft.reportIncludeDeleted),
          quickbooksJson: Value(
            draft.quickbooks == null ? null : jsonEncode(draft.quickbooks),
          ),
          enabledTaxRates: Value(draft.enabledTaxRates),
          enabledItemTaxRates: Value(draft.enabledItemTaxRates),
          enabledExpenseTaxRates: Value(draft.enabledExpenseTaxRates),
          calculateTaxes: Value(draft.calculateTaxes),
          taxDataJson: Value(
            draft.taxData == null ? null : jsonEncode(draft.taxData!.toJson()),
          ),
          customSurchargeTaxes1: Value(draft.customSurchargeTaxes1),
          customSurchargeTaxes2: Value(draft.customSurchargeTaxes2),
          customSurchargeTaxes3: Value(draft.customSurchargeTaxes3),
          customSurchargeTaxes4: Value(draft.customSurchargeTaxes4),
          trackInventory: Value(draft.trackInventory),
          stockNotification: Value(draft.stockNotification),
          inventoryNotificationThreshold: Value(
            draft.inventoryNotificationThreshold,
          ),
          enableProductDiscount: Value(draft.enableProductDiscount),
          enableProductCost: Value(draft.enableProductCost),
          enableProductQuantity: Value(draft.enableProductQuantity),
          defaultQuantity: Value(draft.defaultQuantity),
          showProductDetails: Value(draft.showProductDetails),
          fillProducts: Value(draft.fillProducts),
          updateProducts: Value(draft.updateProducts),
          convertProducts: Value(draft.convertProducts),
          convertRateToClient: Value(draft.convertRateToClient),
          stopOnUnpaidRecurring: Value(draft.stopOnUnpaidRecurring),
          useQuoteTermsOnConversion: Value(draft.useQuoteTermsOnConversion),
          autoStartTasks: Value(draft.autoStartTasks),
          showTaskEndDate: Value(draft.showTaskEndDate),
          showTasksTable: Value(draft.showTasksTable),
          invoiceTaskDatelog: Value(draft.invoiceTaskDatelog),
          invoiceTaskTimelog: Value(draft.invoiceTaskTimelog),
          invoiceTaskHours: Value(draft.invoiceTaskHours),
          invoiceTaskItemDescription: Value(draft.invoiceTaskItemDescription),
          invoiceTaskProject: Value(draft.invoiceTaskProject),
          invoiceTaskProjectHeader: Value(draft.invoiceTaskProjectHeader),
          invoiceTaskLock: Value(draft.invoiceTaskLock),
          invoiceTaskDocuments: Value(draft.invoiceTaskDocuments),
          markExpensesInvoiceable: Value(draft.markExpensesInvoiceable),
          markExpensesPaid: Value(draft.markExpensesPaid),
          convertExpenseCurrency: Value(draft.convertExpenseCurrency),
          invoiceExpenseDocuments: Value(draft.invoiceExpenseDocuments),
          notifyVendorWhenPaid: Value(draft.notifyVendorWhenPaid),
          calculateExpenseTaxByAmount: Value(draft.calculateExpenseTaxByAmount),
          expenseInclusiveTaxes: Value(draft.expenseInclusiveTaxes),
          expenseMailboxActive: Value(draft.expenseMailboxActive),
          expenseMailbox: Value(draft.expenseMailbox),
          inboundMailboxAllowCompanyUsers: Value(
            draft.inboundMailboxAllowCompanyUsers,
          ),
          inboundMailboxAllowVendors: Value(draft.inboundMailboxAllowVendors),
          inboundMailboxAllowClients: Value(draft.inboundMailboxAllowClients),
          inboundMailboxWhitelist: Value(draft.inboundMailboxWhitelist),
          inboundMailboxBlacklist: Value(draft.inboundMailboxBlacklist),
          inboundMailboxAllowUnknown: Value(draft.inboundMailboxAllowUnknown),
          updatedAt: Value(_nowSeconds()),
        ),
      );
      await enqueueMutation(
        companyId: draft.id,
        entityId: draft.id,
        kind: MutationKind.update,
        payload: body,
      );
    });
  }

  /// Enqueue a logo upload. The dispatcher reads the file from `localPath` at
  /// send-time so the upload survives the app being killed between save and
  /// network availability.
  Future<void> uploadLogo({
    required String companyId,
    required String localPath,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: companyId,
      kind: MutationKind.update,
      payload: {'_action': 'upload_logo', 'local_path': localPath},
    );
  }

  /// Enqueue a document upload (multipart).
  Future<void> uploadDocument({
    required String companyId,
    required String localPath,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: companyId,
      kind: MutationKind.update,
      payload: {'_action': 'upload_document', 'local_path': localPath},
    );
  }

  /// Pull the canonical company from `GET /api/v1/companies/{id}` and upsert
  /// it into Drift. Used by the Company Details page on mount so the form
  /// always shows live server state — the login-time settings blob is a
  /// snapshot that can be stale or missing fields the server fills in
  /// elsewhere. Errors are swallowed (logged only): the page still renders
  /// from the cached row.
  Future<void> refresh(String companyId) async {
    if (companyId.isEmpty) return;
    try {
      final response = await api.get(companyId);
      await applyUpdateResponse(
        companyId: companyId,
        serverResponse: response.data,
      );
    } catch (e, st) {
      _log.warning('refresh($companyId) failed', e, st);
    }
  }

  /// Apply the canonical company body returned by the server after a
  /// successful update. The login envelope already wrote the row at login
  /// time; this refreshes the settings blob and the top-level company
  /// fields the Details tab edits.
  ///
  /// `companyId` is part of the standard repository contract; for company
  /// it always equals `serverResponse.id`.
  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required CompanyApi serverResponse,
  }) async {
    await (db.update(
      db.companies,
    )..where((c) => c.id.equals(serverResponse.id))).write(
      CompaniesCompanion(
        settings: Value(jsonEncode(serverResponse.settings)),
        customFields: Value(jsonEncode(serverResponse.customFields)),
        sizeId: Value(serverResponse.sizeId),
        industryId: Value(serverResponse.industryId),
        legalEntityId: Value(serverResponse.legalEntityId),
        enabledModules: Value(serverResponse.enabledModules),
        googleAnalyticsKey: Value(serverResponse.googleAnalyticsKey),
        matomoId: Value(serverResponse.matomoId),
        matomoUrl: Value(serverResponse.matomoUrl),
        sessionTimeout: Value(serverResponse.sessionTimeout),
        defaultPasswordTimeout: Value(serverResponse.defaultPasswordTimeout),
        oauthPasswordRequired: Value(serverResponse.oauthPasswordRequired),
        isDisabled: Value(serverResponse.isDisabled),
        markdownEnabled: Value(serverResponse.markdownEnabled),
        markdownEmailEnabled: Value(serverResponse.markdownEmailEnabled),
        reportIncludeDrafts: Value(serverResponse.reportIncludeDrafts),
        reportIncludeDeleted: Value(serverResponse.reportIncludeDeleted),
        quickbooksJson: Value(
          serverResponse.quickbooks == null
              ? null
              : jsonEncode(serverResponse.quickbooks),
        ),
        enabledTaxRates: Value(serverResponse.enabledTaxRates),
        enabledItemTaxRates: Value(serverResponse.enabledItemTaxRates),
        enabledExpenseTaxRates: Value(serverResponse.enabledExpenseTaxRates),
        calculateTaxes: Value(serverResponse.calculateTaxes),
        taxDataJson: Value(
          serverResponse.taxData == null
              ? null
              : jsonEncode(serverResponse.taxData!.toJson()),
        ),
        customSurchargeTaxes1: Value(serverResponse.customSurchargeTaxes1),
        customSurchargeTaxes2: Value(serverResponse.customSurchargeTaxes2),
        customSurchargeTaxes3: Value(serverResponse.customSurchargeTaxes3),
        customSurchargeTaxes4: Value(serverResponse.customSurchargeTaxes4),
        trackInventory: Value(serverResponse.trackInventory),
        stockNotification: Value(serverResponse.stockNotification),
        inventoryNotificationThreshold: Value(
          serverResponse.inventoryNotificationThreshold,
        ),
        enableProductDiscount: Value(serverResponse.enableProductDiscount),
        enableProductCost: Value(serverResponse.enableProductCost),
        enableProductQuantity: Value(serverResponse.enableProductQuantity),
        defaultQuantity: Value(serverResponse.defaultQuantity),
        showProductDetails: Value(serverResponse.showProductDetails),
        fillProducts: Value(serverResponse.fillProducts),
        updateProducts: Value(serverResponse.updateProducts),
        convertProducts: Value(serverResponse.convertProducts),
        convertRateToClient: Value(serverResponse.convertRateToClient),
        stopOnUnpaidRecurring: Value(serverResponse.stopOnUnpaidRecurring),
        useQuoteTermsOnConversion: Value(serverResponse.useQuoteTermsOnConversion),
        autoStartTasks: Value(serverResponse.autoStartTasks),
        showTaskEndDate: Value(serverResponse.showTaskEndDate),
        showTasksTable: Value(serverResponse.showTasksTable),
        invoiceTaskDatelog: Value(serverResponse.invoiceTaskDatelog),
        invoiceTaskTimelog: Value(serverResponse.invoiceTaskTimelog),
        invoiceTaskHours: Value(serverResponse.invoiceTaskHours),
        invoiceTaskItemDescription: Value(
          serverResponse.invoiceTaskItemDescription,
        ),
        invoiceTaskProject: Value(serverResponse.invoiceTaskProject),
        invoiceTaskProjectHeader: Value(serverResponse.invoiceTaskProjectHeader),
        invoiceTaskLock: Value(serverResponse.invoiceTaskLock),
        invoiceTaskDocuments: Value(serverResponse.invoiceTaskDocuments),
        markExpensesInvoiceable: Value(serverResponse.markExpensesInvoiceable),
        markExpensesPaid: Value(serverResponse.markExpensesPaid),
        convertExpenseCurrency: Value(serverResponse.convertExpenseCurrency),
        invoiceExpenseDocuments: Value(serverResponse.invoiceExpenseDocuments),
        notifyVendorWhenPaid: Value(serverResponse.notifyVendorWhenPaid),
        calculateExpenseTaxByAmount: Value(
          serverResponse.calculateExpenseTaxByAmount,
        ),
        expenseInclusiveTaxes: Value(serverResponse.expenseInclusiveTaxes),
        expenseMailboxActive: Value(serverResponse.expenseMailboxActive),
        expenseMailbox: Value(serverResponse.expenseMailbox),
        inboundMailboxAllowCompanyUsers: Value(
          serverResponse.inboundMailboxAllowCompanyUsers,
        ),
        inboundMailboxAllowVendors: Value(
          serverResponse.inboundMailboxAllowVendors,
        ),
        inboundMailboxAllowClients: Value(
          serverResponse.inboundMailboxAllowClients,
        ),
        inboundMailboxWhitelist: Value(serverResponse.inboundMailboxWhitelist),
        inboundMailboxBlacklist: Value(serverResponse.inboundMailboxBlacklist),
        inboundMailboxAllowUnknown: Value(
          serverResponse.inboundMailboxAllowUnknown,
        ),
        documents: Value(
          jsonEncode(serverResponse.documents.map((d) => d.toJson()).toList()),
        ),
        name: Value(
          serverResponse.name.isNotEmpty
              ? serverResponse.name
              : (serverResponse.settings['name'] as String? ?? ''),
        ),
        updatedAt: Value(
          serverResponse.updatedAt > 0
              ? serverResponse.updatedAt
              : _nowSeconds(),
        ),
      ),
    );
  }

  Company? _fromRow(CompanyRow? row) {
    if (row == null) return null;
    final raw = _decodeSettingsMap(row.settings);
    // The generated `_$$CompanySettingsApiImplFromJson` uses ~200 bare type
    // casts (`as bool?`, `as int?`, ...). Invoice Ninja sometimes ships a
    // legacy field as `0`/`1` where we model it as `bool`; a single mismatch
    // throws a `TypeError` and would otherwise wedge `CompanyDetailsViewModel`
    // on its spinner forever. Falling back to empty typed settings keeps
    // the UI alive — `rawSettings` is still the unmodified server map, so
    // the next save merges every original key back into the PUT body.
    CompanySettingsApi typed;
    try {
      typed = CompanySettingsApi.fromJsonLenient(raw);
    } catch (e, st) {
      _log.warning(
        'CompanySettingsApi.fromJson failed for companyId=${row.id}; '
        'falling back to empty typed view',
        e,
        st,
      );
      typed = const CompanySettingsApi();
    }
    final customFields = _decodeCustomFields(row.customFields);
    final documents = decodeDocumentsColumn(row.documents);
    TaxConfigApi? taxData;
    final taxDataJson = row.taxDataJson;
    if (taxDataJson != null && taxDataJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(taxDataJson);
        if (decoded is Map<String, dynamic>) {
          taxData = TaxConfigApi.fromJson(decoded);
        }
      } catch (e, st) {
        _log.warning(
          'TaxConfigApi.fromJson failed for companyId=${row.id}',
          e,
          st,
        );
      }
    }
    return Company(
      id: row.id,
      name: row.name,
      displayName: row.displayName ?? '',
      sizeId: row.sizeId,
      industryId: row.industryId,
      legalEntityId: row.legalEntityId,
      enabledModules: row.enabledModules,
      googleAnalyticsKey: row.googleAnalyticsKey,
      matomoId: row.matomoId,
      matomoUrl: row.matomoUrl,
      sessionTimeout: row.sessionTimeout,
      defaultPasswordTimeout: row.defaultPasswordTimeout,
      oauthPasswordRequired: row.oauthPasswordRequired,
      isDisabled: row.isDisabled,
      markdownEnabled: row.markdownEnabled,
      markdownEmailEnabled: row.markdownEmailEnabled,
      reportIncludeDrafts: row.reportIncludeDrafts,
      reportIncludeDeleted: row.reportIncludeDeleted,
      quickbooks: _decodeQuickbooks(row.quickbooksJson),
      customFields: customFields,
      rawSettings: raw,
      settings: typed,
      enabledTaxRates: row.enabledTaxRates,
      enabledItemTaxRates: row.enabledItemTaxRates,
      enabledExpenseTaxRates: row.enabledExpenseTaxRates,
      calculateTaxes: row.calculateTaxes,
      taxData: taxData,
      customSurchargeTaxes1: row.customSurchargeTaxes1,
      customSurchargeTaxes2: row.customSurchargeTaxes2,
      customSurchargeTaxes3: row.customSurchargeTaxes3,
      customSurchargeTaxes4: row.customSurchargeTaxes4,
      trackInventory: row.trackInventory,
      stockNotification: row.stockNotification,
      inventoryNotificationThreshold: row.inventoryNotificationThreshold,
      enableProductDiscount: row.enableProductDiscount,
      enableProductCost: row.enableProductCost,
      enableProductQuantity: row.enableProductQuantity,
      defaultQuantity: row.defaultQuantity,
      showProductDetails: row.showProductDetails,
      fillProducts: row.fillProducts,
      updateProducts: row.updateProducts,
      convertProducts: row.convertProducts,
      convertRateToClient: row.convertRateToClient,
      stopOnUnpaidRecurring: row.stopOnUnpaidRecurring,
      useQuoteTermsOnConversion: row.useQuoteTermsOnConversion,
      autoStartTasks: row.autoStartTasks,
      showTaskEndDate: row.showTaskEndDate,
      showTasksTable: row.showTasksTable,
      invoiceTaskDatelog: row.invoiceTaskDatelog,
      invoiceTaskTimelog: row.invoiceTaskTimelog,
      invoiceTaskHours: row.invoiceTaskHours,
      invoiceTaskItemDescription: row.invoiceTaskItemDescription,
      invoiceTaskProject: row.invoiceTaskProject,
      invoiceTaskProjectHeader: row.invoiceTaskProjectHeader,
      invoiceTaskLock: row.invoiceTaskLock,
      invoiceTaskDocuments: row.invoiceTaskDocuments,
      markExpensesInvoiceable: row.markExpensesInvoiceable,
      markExpensesPaid: row.markExpensesPaid,
      convertExpenseCurrency: row.convertExpenseCurrency,
      invoiceExpenseDocuments: row.invoiceExpenseDocuments,
      notifyVendorWhenPaid: row.notifyVendorWhenPaid,
      calculateExpenseTaxByAmount: row.calculateExpenseTaxByAmount,
      expenseInclusiveTaxes: row.expenseInclusiveTaxes,
      expenseMailboxActive: row.expenseMailboxActive,
      expenseMailbox: row.expenseMailbox,
      inboundMailboxAllowCompanyUsers: row.inboundMailboxAllowCompanyUsers,
      inboundMailboxAllowVendors: row.inboundMailboxAllowVendors,
      inboundMailboxAllowClients: row.inboundMailboxAllowClients,
      inboundMailboxWhitelist: row.inboundMailboxWhitelist,
      inboundMailboxBlacklist: row.inboundMailboxBlacklist,
      inboundMailboxAllowUnknown: row.inboundMailboxAllowUnknown,
      documents: documents,
      updatedAt: row.updatedAt,
    );
  }

  /// Decode the `quickbooks_json` Drift column back to the map shape the
  /// API + UI consume. Null / empty / malformed inputs all map to `null` so
  /// the UI's `quickbooks == null` "not connected" check stays a single
  /// branch.
  Map<String, dynamic>? _decodeQuickbooks(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _decodeSettingsMap(String raw) {
    if (raw.isEmpty) return const <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const <String, dynamic>{};
  }

  Map<String, String> _decodeCustomFields(String raw) {
    if (raw.isEmpty) return const <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return {
          for (final e in decoded.entries) e.key: e.value?.toString() ?? '',
        };
      }
    } catch (_) {}
    return const <String, String>{};
  }

  int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
