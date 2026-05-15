import 'dart:convert';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/payments_api.dart';
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

http.Response _envelope({String id = 'p_1'}) => http.Response(
      jsonEncode({
        'data': {'id': id, 'number': 'P-001', 'amount': '100.00'},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('PaymentsApi.create', () {
    test(
      'always appends ?email_receipt=… on POST /payments, lifts the synthetic '
      '_send_email flag out of the body',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).create(
          payload: {
            'client_id': 'c_1',
            'amount': '100',
            kPaymentSendEmailKey: true,
          },
          idempotencyKey: 'idem',
        );
        expect(captured, isNotNull);
        expect(captured!.method, 'POST');
        expect(captured!.url.path, '/api/v1/payments');
        expect(captured!.url.queryParameters['email_receipt'], 'true');
        final body = jsonDecode((captured! as http.Request).body)
            as Map<String, dynamic>;
        expect(body['client_id'], 'c_1');
        expect(body['amount'], '100');
        expect(
          body.containsKey(kPaymentSendEmailKey),
          isFalse,
          reason: 'synthetic flag must not reach the server body',
        );
      },
    );

    test(
      'sends ?email_receipt=false when sendEmail flag is absent (default)',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).create(
          payload: const {'client_id': 'c_1', 'amount': '100'},
          idempotencyKey: 'idem',
        );
        expect(captured!.url.queryParameters['email_receipt'], 'false');
      },
    );
  });

  group('PaymentsApi.update', () {
    test(
      'only appends ?email_receipt=true when sendEmail is true (matches '
      'admin-portal payment_repository.dart:87-89)',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).update(
          id: 'p_1',
          payload: {
            'number': 'P-002',
            kPaymentSendEmailKey: true,
          },
          idempotencyKey: 'idem',
        );
        expect(captured!.method, 'PUT');
        expect(captured!.url.path, '/api/v1/payments/p_1');
        expect(captured!.url.queryParameters['email_receipt'], 'true');
      },
    );

    test(
      'omits the query param entirely when sendEmail is false (legacy parity '
      '— old client only emits the param on true)',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).update(
          id: 'p_1',
          payload: const {'number': 'P-002'},
          idempotencyKey: 'idem',
        );
        expect(captured!.url.queryParameters.containsKey('email_receipt'),
            isFalse);
      },
    );
  });

  group('PaymentsApi.refund', () {
    test(
      'POSTs /payments/refund with body {id, date, invoices} and lifts '
      'sendEmail/gatewayRefund to query params',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).refund(
          id: 'p_1',
          body: const {
            'id': 'p_1',
            'date': '2026-05-15',
            'invoices': [
              {'invoice_id': 'inv_1', 'amount': '25.00', 'id': ''},
            ],
          },
          idempotencyKey: 'idem',
          sendEmail: true,
          gatewayRefund: true,
        );
        expect(captured!.method, 'POST');
        expect(captured!.url.path, '/api/v1/payments/refund');
        expect(captured!.url.queryParameters['email_receipt'], 'true');
        expect(captured!.url.queryParameters['gateway_refund'], 'true');
        final body = jsonDecode((captured! as http.Request).body)
            as Map<String, dynamic>;
        expect(body['id'], 'p_1');
        expect(body['date'], '2026-05-15');
        final invoices = (body['invoices'] as List).cast<Map<String, dynamic>>();
        expect(invoices.single['invoice_id'], 'inv_1');
        expect(invoices.single['amount'], '25.00');
      },
    );

    test(
      'omits gateway_refund query param when false (only emits when true)',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).refund(
          id: 'p_1',
          body: const {
            'id': 'p_1',
            'date': '2026-05-15',
            'invoices': <Map<String, dynamic>>[],
          },
          idempotencyKey: 'idem',
          sendEmail: false,
          gatewayRefund: false,
        );
        expect(captured!.url.queryParameters['email_receipt'], 'false');
        expect(captured!.url.queryParameters.containsKey('gateway_refund'),
            isFalse);
      },
    );

    test(
      'returns the inner PaymentApi from the {data: <payment>} envelope',
      () async {
        final fake = MockClient((_) async => _envelope(id: 'p_refunded'));
        final api = PaymentsApi(_client(fake));
        final result = await api.refund(
          id: 'p_1',
          body: const {
            'id': 'p_1',
            'date': '2026-05-15',
            'invoices': <Map<String, dynamic>>[],
          },
          idempotencyKey: 'idem',
        );
        expect(result.id, 'p_refunded');
      },
    );
  });

  group('PaymentsApi.apply', () {
    test(
      'PUTs /payments/{id} with body {invoices: [...]} (allocations key is '
      '`invoices`, not `paymentables` — matches React Apply.tsx:90-91)',
      () async {
        http.BaseRequest? captured;
        final fake = MockClient((req) async {
          captured = req;
          return _envelope();
        });
        await PaymentsApi(_client(fake)).apply(
          id: 'p_1',
          allocations: const [
            {'_id': 'aa', 'invoice_id': 'inv_1', 'amount': '40.00'},
            {'_id': 'bb', 'invoice_id': 'inv_2', 'amount': '60.00'},
          ],
          idempotencyKey: 'idem',
        );
        expect(captured!.method, 'PUT');
        expect(captured!.url.path, '/api/v1/payments/p_1');
        final body = jsonDecode((captured! as http.Request).body)
            as Map<String, dynamic>;
        expect(body.keys.toList(), ['invoices']);
        final allocations =
            (body['invoices'] as List).cast<Map<String, dynamic>>();
        expect(allocations, hasLength(2));
        expect(allocations[0]['invoice_id'], 'inv_1');
        expect(allocations[1]['invoice_id'], 'inv_2');
      },
    );
  });
}
