import 'dart:convert';
import 'dart:io';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/import_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// import_api-only import chain (→ api_client). Mirrors the chunked-upload
// test harness; independent of unrelated concurrent breakage.

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
      const ApiCredentials(baseUrl: 'https://test', token: 't'),
    );

String? _multipartField(Uint8List body, String name) {
  final text = utf8.decode(body, allowMalformed: true);
  final start = text.indexOf('name="$name"');
  if (start < 0) return null;
  final bodyStart = text.indexOf('\r\n\r\n', start);
  if (bodyStart < 0) return null;
  final boundary = text.indexOf('\r\n--', bodyStart + 4);
  if (boundary < 0) return null;
  return text.substring(bodyStart + 4, boundary);
}

Future<File> _tempArchive() async {
  final tmp = await Directory.systemTemp.createTemp('migration_test_');
  final f = File('${tmp.path}/migration.json');
  await f.writeAsBytes(utf8.encode('{"data":{}}'));
  return f;
}

void main() {
  group('ImportApi.runMigration wire shape', () {
    test('uploads the archive to /api/v1/import_json with import flags',
        () async {
      final file = await _tempArchive();
      final requests = <http.Request>[];
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: MockClient((req) async {
          requests.add(req);
          return http.Response('{"message":"Import queued"}', 200);
        }),
      );

      await ImportApi(client).runMigration(source: fileUploadSource(file.path), importSettings: true);

      expect(requests, hasLength(1), reason: 'tiny file → single chunk');
      final req = requests.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/import_json');
      // Truthy toggle echoed into the query string (matches the tested
      // uploadMultipartChunked contract).
      expect(req.url.queryParameters['import_data'], 'true');
      expect(req.url.queryParameters['chunk_number'], '0');
      expect(req.url.queryParameters['total_chunks'], '1');
      expect(req.headers['Idempotency-Key'], isNotEmpty);
      // import_settings rides as a multipart field reflecting the flag.
      expect(
        _multipartField(req.bodyBytes, 'import_settings'),
        'true',
      );
      expect(_multipartField(req.bodyBytes, 'import_data'), 'true');
    });

    test('importSettings=false sends import_settings=false', () async {
      final file = await _tempArchive();
      late http.Request captured;
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response('{}', 200);
        }),
      );

      await ImportApi(client).runMigration(source: fileUploadSource(file.path), importSettings: false);

      expect(_multipartField(captured.bodyBytes, 'import_settings'), 'false');
    });
  });
}
