// Locks down the two bulk-PDF methods added to BaseEntityApi (inherited by
// invoices / quotes / credits / purchase_orders):
//   * bulkPrintPdf  → POST {basePath}/bulk {action:'bulk_print', ids}, raw PDF
//   * bulkDownloadPdf → POST {basePath}/bulk {action:'bulk_download', ids}, void
// BaseEntityApi is abstract, so we exercise it through the concrete subclasses.

import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/credits_api.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/purchase_orders_api.dart';
import 'package:admin/data/services/quotes_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClient httpClient) => ApiClient(
  credentials: ValueNotifier<ApiCredentials?>(
    const ApiCredentials(baseUrl: 'https://test', token: 't'),
  ),
  passwordCache: PasswordCache(),
  onUnauthorized: () async {},
  httpClient: httpClient,
);

http.Response _pdf() => http.Response.bytes(
  Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46, 0x2d]), // "%PDF-"
  200,
  headers: {'content-type': 'application/pdf'},
);

http.Response _jsonOk() => http.Response(
  jsonEncode({'data': <dynamic>[]}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('BaseEntityApi.bulkPrintPdf', () {
    test('POSTs {basePath}/bulk with action:bulk_print + ids and returns the '
        'PDF bytes', () async {
      http.BaseRequest? captured;
      final fake = MockClient((req) async {
        captured = req;
        return _pdf();
      });

      final bytes = await InvoicesApi(
        _client(fake),
      ).bulkPrintPdf(ids: const ['a', 'b']);

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/invoices/bulk');
      final body =
          jsonDecode((captured! as http.Request).body) as Map<String, dynamic>;
      expect(body['action'], 'bulk_print');
      expect(body['ids'], ['a', 'b']);
      expect(bytes, isNotEmpty);
    });

    test('raises ServerException on a 200 + JSON envelope (postRaw '
        'content-type guard, not handed to the PDF renderer)', () async {
      final fake = MockClient((req) async => _jsonOk());
      expect(
        () => InvoicesApi(_client(fake)).bulkPrintPdf(ids: const ['a']),
        throwsA(isA<ServerException>()),
      );
    });

    test('routes by basePath for quotes / credits / purchase_orders', () async {
      final seen = <String>[];
      final fake = MockClient((req) async {
        seen.add(req.url.path);
        return _pdf();
      });
      await QuotesApi(_client(fake)).bulkPrintPdf(ids: const ['q']);
      await CreditsApi(_client(fake)).bulkPrintPdf(ids: const ['c']);
      await PurchaseOrdersApi(_client(fake)).bulkPrintPdf(ids: const ['p']);
      expect(seen, [
        '/api/v1/quotes/bulk',
        '/api/v1/credits/bulk',
        '/api/v1/purchase_orders/bulk',
      ]);
    });
  });

  group('BaseEntityApi.bulkDownloadPdf', () {
    test('POSTs {basePath}/bulk with action:bulk_download + ids and rides the '
        'Idempotency-Key header (retry-safe)', () async {
      http.BaseRequest? captured;
      final fake = MockClient((req) async {
        captured = req;
        return _jsonOk();
      });

      await CreditsApi(
        _client(fake),
      ).bulkDownloadPdf(ids: const ['a', 'b'], idempotencyKey: 'idem-9');

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/credits/bulk');
      final body =
          jsonDecode((captured! as http.Request).body) as Map<String, dynamic>;
      expect(body['action'], 'bulk_download');
      expect(body['ids'], ['a', 'b']);
      expect(captured!.headers['Idempotency-Key'], 'idem-9');
    });
  });
}
