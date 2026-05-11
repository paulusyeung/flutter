import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
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
class CompanyRepository extends BaseEntityRepository {
  CompanyRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
  }) : super(entityType: EntityType.company);

  final CompaniesApi api;

  @override
  String get entityTypeName => 'company';

  /// Watch the active company. Decodes the `settings` JSON blob on every
  /// emission; the UI binds to this directly.
  Stream<Company?> watch(String companyId) {
    return db.companiesDao.watchById(companyId).map(_fromRow);
  }

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
      await applyUpdateResponse(response: response.data);
    } catch (e, st) {
      _log.warning('refresh($companyId) failed', e, st);
    }
  }

  /// Apply the canonical company body returned by the server after a
  /// successful update. The login envelope already wrote the row at login
  /// time; this refreshes the settings blob and the top-level company
  /// fields the Details tab edits.
  Future<void> applyUpdateResponse({required CompanyApi response}) async {
    await (db.update(
      db.companies,
    )..where((c) => c.id.equals(response.id))).write(
      CompaniesCompanion(
        settings: Value(jsonEncode(response.settings)),
        customFields: Value(jsonEncode(response.customFields)),
        sizeId: Value(response.sizeId),
        industryId: Value(response.industryId),
        legalEntityId: Value(response.legalEntityId),
        name: Value(
          response.name.isNotEmpty
              ? response.name
              : (response.settings['name'] as String? ?? ''),
        ),
        updatedAt: Value(
          response.updatedAt > 0 ? response.updatedAt : _nowSeconds(),
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
    return Company(
      id: row.id,
      name: row.name,
      displayName: row.displayName ?? '',
      sizeId: row.sizeId,
      industryId: row.industryId,
      legalEntityId: row.legalEntityId,
      customFields: customFields,
      rawSettings: raw,
      settings: typed,
      updatedAt: row.updatedAt,
    );
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
