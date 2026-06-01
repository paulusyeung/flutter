import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/password_cache.dart';

// Imports only `invoices_api` (→ api_client) — deliberately NOT
// `invoice_actions`, so this runs even while a concurrent session's
// `BulkAction`/`invoice_list_view_model` change breaks that import graph.

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://t', token: 't'),
);

void main() {
  group('parseEInvoiceValidation (probed shape)', () {
    test('passes:true with empty groups → passes, no messages', () {
      final r = parseEInvoiceValidation({
        'passes': true,
        'invoices': <Object>[],
        'recurring_invoices': <Object>[],
        'clients': <Object>[],
        'companies': <Object>[],
      });
      expect(r.passes, isTrue);
      expect(r.messages, isEmpty);
    });

    test('failing groups → flattened readable messages', () {
      final r = parseEInvoiceValidation({
        'passes': false,
        'invoices': [
          {'message': 'Number is required'},
          {'label': 'Bad date'},
        ],
        'clients': [
          {'field': 'vat_number'},
          'raw string issue',
        ],
        'companies': [
          {'code': 'X1'}, // no message/label/field → JSON fallback
        ],
        'recurring_invoices': <Object>[],
      });
      expect(r.passes, isFalse);
      expect(r.messages, contains('Number is required'));
      expect(r.messages, contains('Bad date'));
      expect(r.messages, contains('vat_number'));
      expect(r.messages, contains('raw string issue'));
      expect(r.messages, contains(jsonEncode({'code': 'X1'})));
    });

    test('non-map / garbage → passes:false, empty', () {
      expect(parseEInvoiceValidation(null).passes, isFalse);
      expect(parseEInvoiceValidation('nope').messages, isEmpty);
      expect(parseEInvoiceValidation(<Object>[]).passes, isFalse);
    });
  });

  group('InvoicesApi.validateEInvoice', () {
    test(
      'POSTs validateEntity {entity:invoices,entity_id}; parses result',
      () async {
        Uri? url;
        Map<String, dynamic>? body;
        final fake = MockClient((req) async {
          url = req.url;
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'passes': false,
              'invoices': [
                {'message': 'Client VAT missing'},
              ],
              'recurring_invoices': <Object>[],
              'clients': <Object>[],
              'companies': <Object>[],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        });
        final api = InvoicesApi(
          ApiClient(
            credentials: _creds(),
            passwordCache: PasswordCache(),
            onUnauthorized: () async {},
            httpClient: fake,
          ),
        );

        final r = await api.validateEInvoice('inv1');
        expect(url!.path, '/api/v1/einvoice/validateEntity');
        expect(body!['entity'], 'invoices');
        expect(body!['entity_id'], 'inv1');
        expect(r.passes, isFalse);
        expect(r.messages, ['Client VAT missing']);
      },
    );

    test('valid invoice → passes, no messages', () async {
      final api = InvoicesApi(
        ApiClient(
          credentials: _creds(),
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'passes': true,
                'invoices': <Object>[],
                'recurring_invoices': <Object>[],
                'clients': <Object>[],
                'companies': <Object>[],
              }),
              200,
              headers: const {'content-type': 'application/json'},
            ),
          ),
        ),
      );
      final r = await api.validateEInvoice('inv1');
      expect(r.passes, isTrue);
      expect(r.messages, isEmpty);
    });
  });
}
