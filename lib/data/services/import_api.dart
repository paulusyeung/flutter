import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:admin/data/models/domain/import_preview.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/upload_source.dart';

/// Entities the CSV importer supports. Wire keys match React's
/// `import_type` / multipart `files[<entity>]` naming.
const kImportableEntities = <String>[
  'client',
  'invoice',
  'quote',
  'recurring_invoice',
  'payment',
  'product',
  'vendor',
  'expense',
  'task',
  'purchase_order',
  'bank_transaction',
];

/// Thin HTTP service for the two-call CSV import flow:
/// - [preImport]: multipart `POST /api/v1/preimport` → `{hash, mappings}`
///   so the UI can render a column-mapping table.
/// - [runImport]: `POST /api/v1/import` with the user's column map; the
///   server queues the import and emails the user on completion.
class ImportApi {
  ImportApi(this.client);

  final ApiClient client;
  final _uuid = const Uuid();

  /// Upload the CSV and get back the header/sample/available-field mapping
  /// metadata for [entity]. Mirrors React's multipart shape:
  /// `files[<entity>]` + an `import_type` field.
  Future<ImportPreview> preImport({
    required String entity,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final raw = await client.uploadMultipart(
      path: '/api/v1/preimport',
      fields: {'import_type': entity},
      files: [
        http.MultipartFile.fromBytes(
          'files[$entity]',
          bytes,
          filename: fileName,
        ),
      ],
      idempotencyKey: _uuid.v4(),
    );
    final json = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
              ? raw.map((k, v) => MapEntry('$k', v))
              : <String, dynamic>{});
    return ImportPreview.fromJson(json, entity);
  }

  /// Submit the finalized column map. [columnMap] is
  /// `{columnIndex: 'entity.field'}`; the server expects string keys nested
  /// under `column_map[<entity>].mapping`. Returns the server's message.
  Future<String> runImport({
    required String hash,
    required String entity,
    required bool skipHeader,
    required Map<int, String> columnMap,
    String? bankIntegrationId,
  }) async {
    final mapping = <String, String>{
      for (final e in columnMap.entries)
        if (e.value.isNotEmpty) '${e.key}': e.value,
    };
    final body = <String, dynamic>{
      'hash': hash,
      'import_type': entity,
      'skip_header': skipHeader,
      'column_map': {
        entity: {'mapping': mapping},
      },
      if (bankIntegrationId != null && bankIntegrationId.isNotEmpty)
        'bank_integration_id': bankIntegrationId,
    };
    final raw = await client.postJson('/api/v1/import', body: body);
    if (raw is Map && raw['message'] is String) {
      return raw['message'] as String;
    }
    return '';
  }

  /// Company / competitor migration: upload an Invoice Ninja migration
  /// archive (the JSON/zip a v1 instance or the IN migration tool produces
  /// from FreshBooks / Wave / etc.) to `POST /api/v1/import_json`. The
  /// server parses + queues the import asynchronously and emails the user on
  /// completion — same async contract as the CSV [runImport].
  ///
  /// Reuses the existing chunked uploader (already transport-tested): the
  /// archive is streamed in 2 MB chunks under one idempotency key, with the
  /// truthy `import_data` toggle echoed into the query string (mirrors
  /// `api_client_chunked_upload_test`). [importSettings] controls whether
  /// company settings are imported alongside the data.
  Future<void> runMigration({
    required UploadSource source,
    required bool importSettings,
  }) async {
    await client.uploadMultipartChunked(
      path: '/api/v1/import_json',
      source: source,
      commonFields: {
        'import_settings': '$importSettings',
        'import_data': 'true',
      },
      commonQueryTrue: const {'import_data': 'true'},
      idempotencyKey: _uuid.v4(),
    );
  }
}
