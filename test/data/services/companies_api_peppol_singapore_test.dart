import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/password_cache.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
      const ApiCredentials(baseUrl: 'https://t', token: 't'),
    );

void main() {
  group('CompaniesApi.peppolSetupWithRedirect', () {
    test('POSTs einvoice/peppol/setup; returns corppass_url when present',
        () async {
      Uri? url;
      Map<String, dynamic>? body;
      final fake = MockClient((req) async {
        url = req.url;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {'id': 'co1', 'name': 'Acme', 'legal_entity_id': 0},
            'corppass_url': 'https://corppass.gov.sg/auth?x=1',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final api = CompaniesApi(ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      ));

      final r = await api.peppolSetupWithRedirect(
        payload: const {
          'party_name': 'Acme',
          'country': '702',
          'id_number': 'UEN123',
          'c5_signer_name': 'Jane Tan',
          'c5_signer_email': 'jane@acme.sg',
          'classification': 'business',
          'e_invoicing_token': 'eitok',
        },
        idempotencyKey: 'k1',
      );

      expect(url!.path, '/api/v1/einvoice/peppol/setup');
      expect(body!['country'], '702');
      expect(body!['id_number'], 'UEN123');
      expect(body!['c5_signer_name'], 'Jane Tan');
      expect(body!['c5_signer_email'], 'jane@acme.sg');
      expect(body!['e_invoicing_token'], 'eitok');
      expect(r.corppassUrl, 'https://corppass.gov.sg/auth?x=1');
      expect(r.company.data.id, 'co1');
    });

    test('no corppass_url (EU-like immediate) → corppassUrl null', () async {
      final api = CompaniesApi(ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'data': {'id': 'co1', 'name': 'Acme', 'legal_entity_id': 7},
              }),
              200,
              headers: const {'content-type': 'application/json'},
            )),
      ));

      final r = await api.peppolSetupWithRedirect(
        payload: const {'country': '276'},
        idempotencyKey: 'k2',
      );
      expect(r.corppassUrl, isNull);
      expect(r.company.data.legalEntityId, 7);
    });
  });
}
