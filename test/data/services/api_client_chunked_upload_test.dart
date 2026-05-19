import 'dart:convert';
import 'dart:io';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://test', token: 't'),
);

/// Pulls a single text field out of a finalized multipart body. Looks for
/// `Content-Disposition: form-data; name="<name>"` and returns the bytes
/// between the header and the next `--boundary`. Good enough for asserting
/// the `metadata` JSON shape without bringing in a multipart parser.
String? _readMultipartField(Uint8List body, String name) {
  final text = utf8.decode(body, allowMalformed: true);
  final marker = 'name="$name"';
  final start = text.indexOf(marker);
  if (start < 0) return null;
  // Skip past the header section (two CRLFs).
  final bodyStart = text.indexOf('\r\n\r\n', start);
  if (bodyStart < 0) return null;
  // Find the next boundary line.
  final boundary = text.indexOf('\r\n--', bodyStart + 4);
  if (boundary < 0) return null;
  return text.substring(bodyStart + 4, boundary);
}

Future<File> _writeTempFile(List<int> bytes, {String name = 'backup.zip'}) async {
  final tmp = await Directory.systemTemp.createTemp('chunked_upload_test_');
  final f = File('${tmp.path}/$name');
  await f.writeAsBytes(bytes);
  return f;
}

void main() {
  group('ApiClient.uploadMultipartChunked', () {
    test('5 MB file → 3 chunks, shared idempotency key, 0-indexed', () async {
      // Slightly bigger than 2×chunkBytes so the last chunk is smaller.
      final bytes = Uint8List(5 * 1024 * 1024);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = i & 0xff;
      }
      final file = await _writeTempFile(bytes);

      final requests = <http.Request>[];
      final fake = MockClient((req) async {
        requests.add(req);
        return http.Response('{"ok":true}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await client.uploadMultipartChunked(
        path: '/api/v1/import_json',
        source: fileUploadSource(file.path),
        commonFields: const {
          'import_settings': 'false',
          'import_data': 'true',
        },
        commonQueryTrue: const {'import_data': 'true'},
        idempotencyKey: 'idem-abc',
      );

      expect(requests.length, 3, reason: '5 MB / 2 MB → 3 chunks');
      for (var i = 0; i < requests.length; i++) {
        expect(requests[i].headers['Idempotency-Key'], 'idem-abc');
        final query = requests[i].url.queryParameters;
        expect(query['chunk_number'], '$i', reason: '0-indexed chunk number');
        expect(query['total_chunks'], '3');
        expect(
          query['import_data'],
          'true',
          reason: 'truthy toggle goes in query string',
        );
        expect(
          query.containsKey('import_settings'),
          isFalse,
          reason: 'falsy toggle is omitted from query string',
        );
      }
    });

    test('chunk metadata: shape, 0-indexed currentChunk, actual chunkSize',
        () async {
      final bytes = Uint8List(5 * 1024 * 1024);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 7) & 0xff;
      }
      final file = await _writeTempFile(bytes);

      final metadatas = <Map<String, dynamic>>[];
      final fake = MockClient((req) async {
        final raw = _readMultipartField(req.bodyBytes, 'metadata');
        if (raw != null) {
          metadatas.add(jsonDecode(raw) as Map<String, dynamic>);
        }
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await client.uploadMultipartChunked(
        path: '/api/v1/import_json',
        source: fileUploadSource(file.path),
        commonFields: const {},
        commonQueryTrue: const {},
        idempotencyKey: 'idem-xyz',
      );

      expect(metadatas.length, 3);
      for (var i = 0; i < metadatas.length; i++) {
        expect(metadatas[i]['totalChunks'], 3);
        expect(metadatas[i]['currentChunk'], i);
        expect(metadatas[i]['fileName'], 'backup.zip');
      }
      // First two chunks are 2 MB; last carries the remainder.
      expect(metadatas[0]['chunkSize'], 2 * 1024 * 1024);
      expect(metadatas[1]['chunkSize'], 2 * 1024 * 1024);
      expect(metadatas[2]['chunkSize'], bytes.length - 2 * 2 * 1024 * 1024);
    });

    test('fileHash covers only first 2 MB on a 5 MB file', () async {
      final bytes = Uint8List(5 * 1024 * 1024);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i + 1) & 0xff;
      }
      final file = await _writeTempFile(bytes);
      final expected =
          sha256.convert(bytes.sublist(0, 2 * 1024 * 1024)).toString();

      String? observed;
      final fake = MockClient((req) async {
        final raw = _readMultipartField(req.bodyBytes, 'metadata');
        if (raw != null) {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          observed = m['fileHash'] as String?;
        }
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await client.uploadMultipartChunked(
        path: '/api/v1/import_json',
        source: fileUploadSource(file.path),
        commonFields: const {},
        commonQueryTrue: const {},
        idempotencyKey: 'idem-hash',
      );

      expect(observed, expected);
    });

    test('fileHash covers whole file on a ≤ 2 MB file', () async {
      final bytes = Uint8List(1024 * 1024);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 3) & 0xff;
      }
      final file = await _writeTempFile(bytes);
      final expected = sha256.convert(bytes).toString();

      String? observed;
      var calls = 0;
      final fake = MockClient((req) async {
        calls++;
        final raw = _readMultipartField(req.bodyBytes, 'metadata');
        if (raw != null) {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          observed = m['fileHash'] as String?;
        }
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await client.uploadMultipartChunked(
        path: '/api/v1/import_json',
        source: fileUploadSource(file.path),
        commonFields: const {},
        commonQueryTrue: const {},
        idempotencyKey: 'idem-small',
      );

      expect(calls, 1, reason: '1 MB / 2 MB chunkBytes → 1 chunk');
      expect(observed, expected);
    });

    test('isCancelled bails between chunks with UploadCancelledException',
        () async {
      final bytes = Uint8List(5 * 1024 * 1024);
      final file = await _writeTempFile(bytes);

      var calls = 0;
      final fake = MockClient((req) async {
        calls++;
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      var cancelled = false;
      await expectLater(
        client.uploadMultipartChunked(
          path: '/api/v1/import_json',
          source: fileUploadSource(file.path),
          commonFields: const {},
          commonQueryTrue: const {},
          idempotencyKey: 'idem-cancel',
          isCancelled: () => cancelled,
          onProgress: (sent, _) {
            // Flip the flag after the first chunk completes.
            if (sent > 0) cancelled = true;
          },
        ),
        throwsA(isA<UploadCancelledException>()),
      );
      // First chunk completed; we cancelled before the second was issued.
      expect(calls, 1);
    });

    test('server 4xx bubbles up as ServerException', () async {
      final bytes = Uint8List(1024);
      final file = await _writeTempFile(bytes);
      final fake = MockClient((req) async => http.Response('boom', 500));
      final client = ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      );

      await expectLater(
        client.uploadMultipartChunked(
          path: '/api/v1/import_json',
          source: fileUploadSource(file.path),
          commonFields: const {},
          commonQueryTrue: const {},
          idempotencyKey: 'idem-err',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
