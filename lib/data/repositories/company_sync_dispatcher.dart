import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

final _log = Logger('CompanySyncDispatcher');

/// Wires the company outbox rows to [CompaniesApi]. Only `update` is
/// supported — companies have no create/delete flow. The `_action` field
/// inside the payload steers between a regular settings PUT and the two
/// multipart upload paths (logo, document).
class CompanySyncDispatcher implements SyncDispatcher {
  CompanySyncDispatcher({required this.api, required this.repo});

  final CompaniesApi api;
  final CompanyRepository repo;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    if (kind != MutationKind.update) {
      _log.warning('Unexpected mutation kind for company: $kind — skipping.');
      return;
    }
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    final action = payload['_action'];
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
    );
    await repo.applyUpdateResponse(
      companyId: row.companyId,
      serverResponse: response.data,
    );
  }
}
