import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';

ValueListenable<ApiCredentials?> _creds() => ValueNotifier<ApiCredentials?>(
  const ApiCredentials(baseUrl: 'https://t', token: 't'),
);

Invoice _inv(String statusId, {bool deleted = false}) =>
    Invoice.fromApi(InvoiceApi(id: 'i1', statusId: statusId,
        isDeleted: deleted));

void main() {
  group('canSendEInvoice (tightened: Sent only)', () {
    test('configured + status Sent → true', () {
      expect(canSendEInvoice(_inv('2'), 'PEPPOL'), isTrue);
      expect(canSendEInvoice(_inv('2'), 'VERIFACTU'), isTrue);
    });

    test('partial / paid → false (already transmitted)', () {
      expect(canSendEInvoice(_inv('3'), 'PEPPOL'), isFalse); // partial
      expect(canSendEInvoice(_inv('4'), 'PEPPOL'), isFalse); // paid
    });

    test('no e-invoice type → false', () {
      expect(canSendEInvoice(_inv('2'), null), isFalse);
      expect(canSendEInvoice(_inv('2'), ''), isFalse);
    });

    test('draft / cancelled / reversed / deleted → false', () {
      expect(canSendEInvoice(_inv('1'), 'PEPPOL'), isFalse); // draft
      expect(canSendEInvoice(_inv('5'), 'PEPPOL'), isFalse); // cancelled
      expect(canSendEInvoice(_inv('6'), 'PEPPOL'), isFalse); // reversed
      expect(
        canSendEInvoice(_inv('2', deleted: true), 'PEPPOL'),
        isFalse,
      );
    });
  });

  group('canValidateEInvoice (read-only pre-flight: not Sent-only)', () {
    test('configured → true at any non-deleted status, incl. draft', () {
      expect(canValidateEInvoice(_inv('1'), 'PEPPOL'), isTrue); // draft
      expect(canValidateEInvoice(_inv('2'), 'PEPPOL'), isTrue); // sent
      expect(canValidateEInvoice(_inv('3'), 'VERIFACTU'), isTrue); // partial
      expect(canValidateEInvoice(_inv('4'), 'PEPPOL'), isTrue); // paid
      expect(canValidateEInvoice(_inv('5'), 'PEPPOL'), isTrue); // cancelled
      expect(canValidateEInvoice(_inv('6'), 'PEPPOL'), isTrue); // reversed
    });

    test('no e-invoice type → false', () {
      expect(canValidateEInvoice(_inv('1'), null), isFalse);
      expect(canValidateEInvoice(_inv('2'), ''), isFalse);
    });

    test('deleted → false', () {
      expect(canValidateEInvoice(_inv('1', deleted: true), 'PEPPOL'), isFalse);
    });
  });

  group('InvoicesApi e-invoice endpoints', () {
    test('sendEInvoice POSTs peppol/send {entity:invoice,entity_id}',
        () async {
      Uri? url;
      Map<String, dynamic>? body;
      final fake = MockClient((req) async {
        url = req.url;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{}', 200,
            headers: const {'content-type': 'application/json'});
      });
      final api = InvoicesApi(ApiClient(
        credentials: _creds(),
        passwordCache: PasswordCache(),
        onUnauthorized: () async {},
        httpClient: fake,
      ));

      await api.sendEInvoice(id: 'i1', idempotencyKey: 'k');
      expect(url!.path, '/api/v1/einvoice/peppol/send');
      expect(body!['entity'], 'invoice');
      expect(body!['entity_id'], 'i1');
    });
    // validateEInvoice contract is covered in
    // test/data/services/einvoice_validate_test.dart (kept off the
    // invoice_actions import so it runs despite concurrent breakage).
  });
}
