import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

final _log = Logger('CompanySyncDispatcher');

/// Wires the company outbox rows to [CompaniesApi]. Settings + uploads go
/// through `update` (the `_action` field inside the payload steers between
/// the regular settings PUT and the two multipart upload paths); the
/// Danger Zone Delete-company flow goes through `delete`.
class CompanySyncDispatcher implements SyncDispatcher {
  CompanySyncDispatcher({required this.api, required this.repo});

  final CompaniesApi api;
  final CompanyRepository repo;

  /// Decode the JSON payload defensively. A corrupt row would otherwise
  /// throw to the catch-all in `SyncRepository._attempt` and burn 5 retries
  /// before mark-dead.
  Map<String, dynamic> _decodePayload(OutboxRow row) {
    try {
      return jsonDecode(row.payload) as Map<String, dynamic>;
    } catch (e) {
      _log.severe('Corrupt company payload (row ${row.id}): $e');
      throw ValidationException(
        'Corrupt outbox payload',
        const {'payload': ['Could not decode']},
      );
    }
  }

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    if (kind == MutationKind.delete) {
      final payload = _decodePayload(row);
      await api.deleteWithBody(
        id: row.entityId,
        body: payload,
        idempotencyKey: row.idempotencyKey,
      );
      return;
    }
    if (kind != MutationKind.update) {
      _log.warning('Unexpected mutation kind for company: $kind — skipping.');
      return;
    }
    final payload = _decodePayload(row);
    final action = payload['_action'];
    // The Email Settings page's "Sync send time to existing entities"
    // checkbox stashes a one-shot bool under this control key; pop it
    // before serializing so it doesn't leak into the company PUT body,
    // and pass it as a query param on the canonical settings PUT below.
    final syncSendTime = payload.remove('_sync_send_time');
    if (action == 'upload_logo') {
      final localPath = payload['local_path'] as String;
      if (!await File(localPath).exists()) {
        _log.warning(
          'Logo upload skipped: local file $localPath no longer exists.',
        );
        return;
      }
      final response = await api.uploadLogo(
        companyId: row.entityId,
        filePath: localPath,
        idempotencyKey: row.idempotencyKey,
      );
      await repo.applyUpdateResponse(
        companyId: row.companyId,
        serverResponse: response.data,
      );
      return;
    }
    if (action == 'upload_document') {
      final localPath = payload['local_path'] as String;
      if (!await File(localPath).exists()) {
        _log.warning(
          'Document upload skipped: local file $localPath no longer exists.',
        );
        return;
      }
      final response = await api.uploadDocument(
        companyId: row.entityId,
        filePath: localPath,
        idempotencyKey: row.idempotencyKey,
      );
      await repo.applyUpdateResponse(
        companyId: row.companyId,
        serverResponse: response.data,
      );
      return;
    }
    final response = await api.update(
      id: row.entityId,
      payload: payload,
      idempotencyKey: row.idempotencyKey,
      query: syncSendTime is bool
          ? {'sync_send_time': syncSendTime.toString()}
          : null,
    );
    await repo.applyUpdateResponse(
      companyId: row.companyId,
      serverResponse: response.data,
    );
  }
}
