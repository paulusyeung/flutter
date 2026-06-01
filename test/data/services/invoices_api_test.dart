import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/password_cache.dart';
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
  const [0x25, 0x50, 0x44, 0x46], // "%PDF"
  200,
  headers: {'content-type': 'application/pdf'},
);

void main() {
  group('InvoicesApi.downloadPdf', () {
    test('saved invoice, no delivery note → POST /api/v1/live_preview with the '
        'entity body, no delivery_note key on the wire', () async {
      http.BaseRequest? captured;
      final fake = MockClient((req) async {
        captured = req;
        return _pdf();
      });
      final bytes = await InvoicesApi(
        _client(fake),
      ).downloadPdf(entityJson: {'id': 'inv_1', 'number': 'INV-001'});
      expect(bytes, isNotEmpty);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/live_preview');
      expect(captured!.url.queryParameters['entity'], 'invoice');
      expect(captured!.url.queryParameters['entity_id'], 'inv_1');
      final body =
          jsonDecode((captured! as http.Request).body) as Map<String, dynamic>;
      expect(body['id'], 'inv_1');
      expect(body['number'], 'INV-001');
      expect(body.containsKey('delivery_note'), isFalse);
    });

    test(
      'saved invoice + deliveryNote: true → GET dedicated delivery_note route, '
      'no request body',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _pdf();
        });
        await InvoicesApi(_client(fake)).downloadPdf(
          entityJson: {'id': 'inv_1', 'number': 'INV-001'},
          deliveryNote: true,
        );
        expect(captured!.method, 'GET');
        expect(captured!.url.path, '/api/v1/invoices/inv_1/delivery_note');
        expect(captured!.url.queryParameters, isEmpty);
        // No JSON body on a GET.
        expect((captured! as http.Request).body, isEmpty);
      },
    );

    test(
      'delivery note + designId override → ?design_id is carried on the URL',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _pdf();
        });
        await InvoicesApi(_client(fake)).downloadPdf(
          entityJson: {'id': 'inv_1'},
          designId: 'design_42',
          deliveryNote: true,
        );
        expect(captured!.method, 'GET');
        expect(captured!.url.path, '/api/v1/invoices/inv_1/delivery_note');
        expect(captured!.url.queryParameters['design_id'], 'design_42');
      },
    );

    test(
      'unsaved (tmp_…) invoice + deliveryNote: true → falls through to '
      'live_preview, no entity_id query, no delivery_note body field',
      () async {
        // The UI hides the toggle until the invoice is saved, but if a caller
        // ever asks for delivery_note on a tmp_ id we must not 404 — we return
        // the normal-layout PDF instead of hitting the dedicated route.
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _pdf();
        });
        await InvoicesApi(_client(fake)).downloadPdf(
          entityJson: {'id': 'tmp_abc', 'number': 'draft'},
          deliveryNote: true,
        );
        expect(captured!.method, 'POST');
        expect(captured!.url.path, '/api/v1/live_preview');
        expect(captured!.url.queryParameters.containsKey('entity_id'), isFalse);
        final body =
            jsonDecode((captured! as http.Request).body)
                as Map<String, dynamic>;
        expect(body.containsKey('delivery_note'), isFalse);
      },
    );

    test(
      'saved + designId, no delivery note → POST live_preview carries design_id '
      'in the body, not on the URL',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _pdf();
        });
        await InvoicesApi(
          _client(fake),
        ).downloadPdf(entityJson: {'id': 'inv_1'}, designId: 'design_42');
        expect(captured!.method, 'POST');
        expect(captured!.url.path, '/api/v1/live_preview');
        expect(captured!.url.queryParameters.containsKey('design_id'), isFalse);
        final body =
            jsonDecode((captured! as http.Request).body)
                as Map<String, dynamic>;
        expect(body['design_id'], 'design_42');
      },
    );
  });
}
