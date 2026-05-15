import 'dart:io';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Per-entity document mutation handlers for the sync dispatcher.
///
/// Returns the trio of [MutationKind.documentUpload],
/// [MutationKind.documentDelete], and [MutationKind.documentVisibility]
/// dispatchers — identical in shape across every document-bearing entity
/// (Client, Product, Project, and the upcoming Expense / Vendor / Invoice).
/// Spread into [wireEntity]'s `customActions` so entities with extra
/// non-document actions (Task's `reorder`, Client's `addComment`) merge in
/// one place.
///
/// The factory lives here rather than on [BaseEntityRepository] because the
/// three endpoints span two services: the entity-scoped upload
/// (`POST /<entity>/{id}/upload`) and the doc-scoped delete + visibility
/// (`DocumentsApi`). The dispatcher layer is where multi-service HTTP shape
/// belongs; repositories stay focused on Drift + outbox.
Map<MutationKind, CustomMutationHandler<TInner>>
documentMutationHandlers<TInner>({
  required DocumentsApi documentsApi,
  required Future<TInner> Function({
    required String entityId,
    required String filePath,
    required String idempotencyKey,
  })
  upload,
  required Future<void> Function({
    required String companyId,
    required String entityId,
    required DocumentApi document,
  })
  applyChanged,
  required Future<void> Function({
    required String companyId,
    required String entityId,
    required String documentId,
  })
  applyDeleted,
}) {
  return {
    MutationKind.documentUpload: ({required row, required payload}) async {
      final localPath = payload['local_path'] as String;
      final entityId = payload['entity_id'] as String;
      // File moved/deleted between enqueue and dispatch — drop the row
      // rather than 5xx-looping. Matches CompanySyncDispatcher's behavior.
      if (!File(localPath).existsSync()) return null;
      return upload(
        entityId: entityId,
        filePath: localPath,
        idempotencyKey: row.idempotencyKey,
      );
    },
    MutationKind.documentDelete: ({required row, required payload}) async {
      final documentId = payload['document_id'] as String;
      final entityId = payload['entity_id'] as String;
      await documentsApi.delete(
        id: documentId,
        idempotencyKey: row.idempotencyKey,
        requiresPassword: true,
      );
      await applyDeleted(
        companyId: row.companyId,
        entityId: entityId,
        documentId: documentId,
      );
      return null;
    },
    MutationKind.documentVisibility: ({required row, required payload}) async {
      final documentId = payload['document_id'] as String;
      final entityId = payload['entity_id'] as String;
      final isPublic = payload['is_public'] as bool;
      final updated = await documentsApi.setVisibility(
        id: documentId,
        isPublic: isPublic,
        idempotencyKey: row.idempotencyKey,
      );
      if (updated != null) {
        await applyChanged(
          companyId: row.companyId,
          entityId: entityId,
          document: updated,
        );
      }
      return null;
    },
  };
}
