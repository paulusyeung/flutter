import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/views/advanced/e_invoice/payment_means_card.dart';

/// Unit tests for [paymentMeansSeedFromEInvoice] — the pure walk over the
/// server's nested `e_invoice.Invoice.PaymentMeans[0]` UBL shape that seeds the
/// Payment Means card. Guards the (easy-to-typo) path strings and the
/// null/wrong-type robustness, so a broken path can't silently fail to seed and
/// re-introduce the blind-save clobber bug.
void main() {
  group('paymentMeansSeedFromEInvoice', () {
    test('extracts code + bank sub-fields from a populated blob', () {
      final blob = <String, dynamic>{
        'Invoice': {
          'PaymentMeans': [
            {
              'PaymentMeansCode': {'value': '58'},
              'PayeeFinancialAccount': {
                'ID': {'value': 'DE89370400440532013000'},
                'Name': 'Acme GmbH',
                'SortCode': {'value': '08-30-12'},
                'FinancialInstitutionBranch': {
                  'FinancialInstitution': {
                    'ID': {'value': 'COBADEFFXXX'},
                  },
                },
              },
              'PayerFinancialAccount': {
                'ID': {'value': 'PAYER-123'},
              },
            },
          ],
        },
      };

      final seed = paymentMeansSeedFromEInvoice(blob);
      expect(seed.code, '58');
      expect(seed.fields['iban'], 'DE89370400440532013000');
      expect(seed.fields['account_holder'], 'Acme GmbH'); // bare-string leaf
      expect(seed.fields['bic_swift'], 'COBADEFFXXX'); // deepest 5-hop path
      expect(seed.fields['bsb_sort'], '08-30-12');
      expect(seed.fields['payer_bank_account'], 'PAYER-123');
      expect(seed.fields.containsKey('card_type'), isFalse);
    });

    test('extracts card sub-fields', () {
      final blob = <String, dynamic>{
        'Invoice': {
          'PaymentMeans': [
            {
              'PaymentMeansCode': {'value': '54'},
              'CardAccount': {
                'NetworkID': {'value': 'VISA'},
                'PrimaryAccountNumberID': {'value': '1234'},
                'HolderName': {'value': 'Jane Doe'},
              },
            },
          ],
        },
      };

      final seed = paymentMeansSeedFromEInvoice(blob);
      expect(seed.code, '54');
      expect(seed.fields['card_type'], 'VISA');
      expect(seed.fields['card_number'], '1234');
      expect(seed.fields['card_holder'], 'Jane Doe');
    });

    test('coerces a numeric leaf value to a string', () {
      final blob = <String, dynamic>{
        'Invoice': {
          'PaymentMeans': [
            {
              'PaymentMeansCode': {'value': 30},
            },
          ],
        },
      };
      expect(paymentMeansSeedFromEInvoice(blob).code, '30');
    });

    test('returns only the fields present (partial blob)', () {
      final blob = <String, dynamic>{
        'Invoice': {
          'PaymentMeans': [
            {
              'PaymentMeansCode': {'value': '30'},
              'PayeeFinancialAccount': {
                'ID': {'value': 'IBAN-ONLY'},
              },
            },
          ],
        },
      };
      final seed = paymentMeansSeedFromEInvoice(blob);
      expect(seed.code, '30');
      expect(seed.fields, {'iban': 'IBAN-ONLY'});
    });

    test('empty object → no code, no fields (fresh company)', () {
      final seed = paymentMeansSeedFromEInvoice(<String, dynamic>{});
      expect(seed.code, isNull);
      expect(seed.fields, isEmpty);
    });

    test('null blob → empty result', () {
      final seed = paymentMeansSeedFromEInvoice(null);
      expect(seed.code, isNull);
      expect(seed.fields, isEmpty);
    });

    test('survives wrong-typed nested hops without throwing', () {
      // Invoice is not a map.
      expect(
        paymentMeansSeedFromEInvoice(<String, dynamic>{
          'Invoice': 'nope',
        }).fields,
        isEmpty,
      );
      // PaymentMeans is not a list.
      expect(
        paymentMeansSeedFromEInvoice(<String, dynamic>{
          'Invoice': {'PaymentMeans': 'nope'},
        }).fields,
        isEmpty,
      );
      // PaymentMeans is an empty list (no [0]).
      final emptyList = paymentMeansSeedFromEInvoice(<String, dynamic>{
        'Invoice': {'PaymentMeans': <dynamic>[]},
      });
      expect(emptyList.code, isNull);
      expect(emptyList.fields, isEmpty);
      // PaymentMeans[0] is not a map.
      expect(
        paymentMeansSeedFromEInvoice(<String, dynamic>{
          'Invoice': {
            'PaymentMeans': ['nope'],
          },
        }).fields,
        isEmpty,
      );
    });
  });
}
