import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/services_document_handlers.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Unit tests for the document-mutation-handlers factory.
///
/// The factory replaces ~65 LOC of duplicated upload / delete / visibility
/// blocks that lived once per document-bearing entity in `services.dart`.
/// These tests assert the shape of each handler so the next document-bearing
/// entity (expense / vendor / invoice) can adopt it without re-deriving the
/// behavior from the call sites.
void main() {
  group('documentMutationHandlers', () {
    test(
      'documentUpload short-circuits when the local file is missing',
      () async {
        final fakeDocsApi = _RecordingDocumentsApi();
        final uploadCalls = <Map<String, dynamic>>[];
        final handlers = documentMutationHandlers<String>(
          documentsApi: fakeDocsApi,
          upload:
              ({
                required entityId,
                required source,
                required idempotencyKey,
              }) async {
                uploadCalls.add({
                  'entityId': entityId,
                  'fileName': source.fileName,
                  'idempotencyKey': idempotencyKey,
                });
                return 'inner-dto';
              },
          applyChanged:
              ({
                required companyId,
                required entityId,
                required document,
              }) async {},
          applyDeleted:
              ({
                required companyId,
                required entityId,
                required documentId,
              }) async {},
        );

        final handler = handlers[MutationKind.documentUpload]!;
        final row = _row(mutationKind: 'document_upload');
        final result = await handler(
          row: row,
          payload: {
            'entity_id': 'e1',
            'local_path': '/tmp/definitely-not-a-real-file-xyz',
          },
        );

        expect(result, isNull);
        expect(
          uploadCalls,
          isEmpty,
          reason: 'Upload closure must not fire when the file is missing',
        );
      },
    );

    test('documentUpload forwards entityId + localPath + idempotencyKey '
        'and returns the inner dto', () async {
      final fakeDocsApi = _RecordingDocumentsApi();
      final tmp = await File(
        '${Directory.systemTemp.path}/svc-doc-handlers-test-${DateTime.now().microsecondsSinceEpoch}.txt',
      ).create();
      addTearDown(() async {
        if (await tmp.exists()) await tmp.delete();
      });

      final uploadCalls = <Map<String, dynamic>>[];
      final handlers = documentMutationHandlers<String>(
        documentsApi: fakeDocsApi,
        upload:
            ({
              required entityId,
              required source,
              required idempotencyKey,
            }) async {
              uploadCalls.add({
                'entityId': entityId,
                'fileName': source.fileName,
                'idempotencyKey': idempotencyKey,
              });
              return 'inner-dto';
            },
        applyChanged:
            ({
              required companyId,
              required entityId,
              required document,
            }) async {},
        applyDeleted:
            ({
              required companyId,
              required entityId,
              required documentId,
            }) async {},
      );

      final handler = handlers[MutationKind.documentUpload]!;
      final result = await handler(
        row: _row(mutationKind: 'document_upload', idempotencyKey: 'idk-1'),
        payload: {'entity_id': 'e7', 'local_path': tmp.path},
      );

      expect(result, 'inner-dto');
      expect(uploadCalls, hasLength(1));
      expect(uploadCalls.single['entityId'], 'e7');
      expect(uploadCalls.single['fileName'], tmp.path.split('/').last);
      expect(uploadCalls.single['idempotencyKey'], 'idk-1');
    });

    test(
      'documentDelete calls documentsApi.delete then applyDeleted',
      () async {
        final fakeDocsApi = _RecordingDocumentsApi();
        final deletedCalls = <Map<String, dynamic>>[];

        final handlers = documentMutationHandlers<String>(
          documentsApi: fakeDocsApi,
          upload:
              ({
                required entityId,
                required source,
                required idempotencyKey,
              }) async => '',
          applyChanged:
              ({
                required companyId,
                required entityId,
                required document,
              }) async {},
          applyDeleted:
              ({
                required companyId,
                required entityId,
                required documentId,
              }) async {
                deletedCalls.add({
                  'companyId': companyId,
                  'entityId': entityId,
                  'documentId': documentId,
                });
              },
        );

        final handler = handlers[MutationKind.documentDelete]!;
        final result = await handler(
          row: _row(
            companyId: 'co1',
            mutationKind: 'document_delete',
            idempotencyKey: 'idk-d',
          ),
          payload: {'entity_id': 'e2', 'document_id': 'd99'},
        );

        expect(result, isNull);
        expect(fakeDocsApi.deleteCalls, hasLength(1));
        expect(fakeDocsApi.deleteCalls.single['id'], 'd99');
        expect(fakeDocsApi.deleteCalls.single['idempotencyKey'], 'idk-d');
        expect(
          fakeDocsApi.deleteCalls.single['requiresPassword'],
          isTrue,
          reason: 'documents.delete must always gate on password',
        );
        expect(deletedCalls, hasLength(1));
        expect(deletedCalls.single['companyId'], 'co1');
        expect(deletedCalls.single['entityId'], 'e2');
        expect(deletedCalls.single['documentId'], 'd99');
      },
    );

    test('documentVisibility calls setVisibility then applyChanged with the '
        'returned document — and skips applyChanged when the server returns '
        'null', () async {
      final returnDoc = const DocumentApi(id: 'd99', isPublic: true);
      final fakeDocsApi = _RecordingDocumentsApi(
        setVisibilityReturn: returnDoc,
      );
      final changedCalls = <DocumentApi>[];

      final handlers = documentMutationHandlers<String>(
        documentsApi: fakeDocsApi,
        upload:
            ({
              required entityId,
              required source,
              required idempotencyKey,
            }) async => '',
        applyChanged:
            ({required companyId, required entityId, required document}) async {
              changedCalls.add(document);
            },
        applyDeleted:
            ({
              required companyId,
              required entityId,
              required documentId,
            }) async {},
      );

      final handler = handlers[MutationKind.documentVisibility]!;

      await handler(
        row: _row(mutationKind: 'document_visibility', idempotencyKey: 'idk-v'),
        payload: {'entity_id': 'e3', 'document_id': 'd99', 'is_public': true},
      );

      expect(fakeDocsApi.setVisibilityCalls, hasLength(1));
      expect(fakeDocsApi.setVisibilityCalls.single['isPublic'], isTrue);
      expect(changedCalls, [returnDoc]);

      // Second pass with a null return — applyChanged must NOT fire (the
      // server response shape was malformed; we don't fabricate a doc).
      fakeDocsApi
        ..setVisibilityReturn = null
        ..setVisibilityCalls.clear();
      changedCalls.clear();

      await handler(
        row: _row(mutationKind: 'document_visibility'),
        payload: {'entity_id': 'e3', 'document_id': 'd99', 'is_public': false},
      );

      expect(fakeDocsApi.setVisibilityCalls, hasLength(1));
      expect(changedCalls, isEmpty);
    });
  });
}

OutboxRow _row({
  String companyId = 'co',
  String mutationKind = 'document_upload',
  String idempotencyKey = 'idk',
}) {
  return OutboxRow(
    id: 1,
    companyId: companyId,
    entityType: 'client',
    entityId: 'c1',
    mutationKind: mutationKind,
    payload: jsonEncode(const {}),
    idempotencyKey: idempotencyKey,
    state: 'pending',
    attempts: 0,
    nextAttemptAt: 0,
    createdAt: 0,
    requiresPassword: false,
  );
}

class _RecordingDocumentsApi implements DocumentsApi {
  _RecordingDocumentsApi({this.setVisibilityReturn});

  final deleteCalls = <Map<String, dynamic>>[];
  final setVisibilityCalls = <Map<String, dynamic>>[];
  DocumentApi? setVisibilityReturn;

  @override
  Future<void> delete({
    required String id,
    required String idempotencyKey,
    required bool requiresPassword,
  }) async {
    deleteCalls.add({
      'id': id,
      'idempotencyKey': idempotencyKey,
      'requiresPassword': requiresPassword,
    });
  }

  @override
  Future<DocumentApi?> setVisibility({
    required String id,
    required bool isPublic,
    required String idempotencyKey,
  }) async {
    setVisibilityCalls.add({
      'id': id,
      'isPublic': isPublic,
      'idempotencyKey': idempotencyKey,
    });
    return setVisibilityReturn;
  }
}
