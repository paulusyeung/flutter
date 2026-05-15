import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/system_log.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/system_logs_api.dart';

final _log = Logger('SystemLogRepository');

/// Outcome of a [SystemLogRepository.refresh] call. The UI uses this to
/// distinguish "empty because the server has no logs" from "empty because
/// the account isn't allowed to view them" — important on self-hosted
/// installs that disable the endpoint.
enum SystemLogRefreshResult { ok, forbidden, notFound, networkError }

/// Read-only repository for `/api/v1/system_logs`. Mirrors
/// [StaticsRepository]'s shape — no outbox, no mutation surface; the
/// server is the only writer.
class SystemLogRepository {
  SystemLogRepository({
    required AppDatabase db,
    required SystemLogsApi api,
    DateTime Function()? now,
  }) : _db = db,
       _api = api,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SystemLogsApi _api;
  final DateTime Function() _now;

  /// Stream of cached system logs for [companyId], newest first.
  Stream<List<SystemLog>> watch(String companyId) {
    if (companyId.isEmpty) {
      return Stream<List<SystemLog>>.value(const []);
    }
    return _db.systemLogDao.watchForCompany(companyId: companyId).map(
      (rows) => rows.map(_fromRow).toList(growable: false),
    );
  }

  /// Latest `fetched_at` for [companyId], or null if the cache is empty.
  Future<DateTime?> lastFetchedAt(String companyId) async {
    if (companyId.isEmpty) return null;
    return _db.systemLogDao.lastFetchedAt(companyId);
  }

  /// Fetch a fresh page and replace the cache for [companyId]. The 403 /
  /// 404 / 412 / network branches return the matching enum instead of
  /// throwing — most self-hosted installs gate this endpoint and the UI
  /// needs to render a different empty state.
  Future<SystemLogRefreshResult> refresh(String companyId) async {
    if (companyId.isEmpty) return SystemLogRefreshResult.ok;
    try {
      final list = await _api.fetchPage();
      final nowSeconds = _now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final rows = list.data
          .map(
            (a) => SystemLogsCompanion.insert(
              id: a.id,
              companyId: companyId,
              userId: Value(a.userId),
              clientId: Value(a.clientId),
              eventId: a.eventId,
              categoryId: a.categoryId,
              typeId: a.typeId,
              log: Value(a.log),
              createdAt: a.createdAt,
              updatedAt: a.updatedAt,
              fetchedAt: nowSeconds,
            ),
          )
          .toList(growable: false);
      await _db.systemLogDao.replaceForCompany(
        companyId: companyId,
        rows: rows,
      );
      return SystemLogRefreshResult.ok;
    } on PasswordRequiredException {
      // 412 — server demands password to view; we treat this the same as 403
      // since the System Logs feed has no password prompt UI of its own.
      _log.info('System logs gated (412 password required) for $companyId');
      return SystemLogRefreshResult.forbidden;
    } on ServerException catch (e) {
      if (e.statusCode == 403) {
        _log.info('System logs forbidden (403) for $companyId');
        return SystemLogRefreshResult.forbidden;
      }
      if (e.statusCode == 404) {
        _log.info('System logs endpoint not found (404) for $companyId');
        return SystemLogRefreshResult.notFound;
      }
      _log.warning('System logs refresh failed (${e.statusCode}): ${e.message}');
      return SystemLogRefreshResult.networkError;
    } on NetworkException catch (e) {
      _log.warning('System logs refresh: network error', e);
      return SystemLogRefreshResult.networkError;
    } on ApiException catch (e) {
      _log.warning('System logs refresh: api exception', e);
      return SystemLogRefreshResult.networkError;
    }
  }

  SystemLog _fromRow(SystemLogRow row) => SystemLog(
    id: row.id,
    companyId: row.companyId,
    userId: row.userId,
    clientId: row.clientId,
    eventId: row.eventId,
    categoryId: row.categoryId,
    typeId: row.typeId,
    log: row.log,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAt * 1000,
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      row.updatedAt * 1000,
      isUtc: true,
    ),
  );
}
