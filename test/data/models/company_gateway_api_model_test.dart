import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_gateway_api_model.dart';

void main() {
  group('CompanyGatewayApi.fromJson', () {
    test('parses []-shaped empty fees_and_limits without crashing', () {
      // PHP serializes an empty assoc-array as `[]`; the strict cast used
      // to crash here.
      final api = CompanyGatewayApi.fromJson({
        'id': 'g_1',
        'gateway_key': 'stripe',
        'fees_and_limits': <dynamic>[],
      });
      expect(api.feesAndLimits, isEmpty);
      expect(api.id, 'g_1');
    });

    test('parses populated fees_and_limits map by gateway type id', () {
      final api = CompanyGatewayApi.fromJson({
        'id': 'g_2',
        'fees_and_limits': {
          '1': {
            'min_limit': 0,
            'max_limit': 100,
            'fee_amount': 0.5,
            'is_enabled': true,
          },
        },
      });
      expect(api.feesAndLimits.keys, ['1']);
      final entry = api.feesAndLimits['1']!;
      expect(entry.minLimit, 0);
      expect(entry.maxLimit, 100);
      expect(entry.feeAmount, 0.5);
      expect(entry.isEnabled, isTrue);
    });

    test('falls back to empty map when fees_and_limits key is missing', () {
      final api = CompanyGatewayApi.fromJson({'id': 'g_3'});
      expect(api.feesAndLimits, isEmpty);
    });
  });
}
