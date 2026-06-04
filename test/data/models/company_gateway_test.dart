import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/domain/gateway_constants.dart';

void main() {
  group('CompanyGateway.fromApi token_billing normalization', () {
    String billing(String wire) => CompanyGateway.fromApi(
      CompanyGatewayApi(tokenBilling: wire),
    ).tokenBilling;

    test('empty string coerces to off', () {
      expect(billing(''), kAutoBillOff);
    });

    test('value outside the known options coerces to off', () {
      // A non-empty stray value (legacy `opt_out`/`opt_in`, or anything else
      // the server might return) must not reach the Settings-tab dropdown
      // verbatim — it would trip Flutter's "exactly one item" assertion.
      // fromApi is the boundary that normalizes it.
      expect(billing('opt_out'), kAutoBillOff);
      expect(billing('opt_in'), kAutoBillOff);
      expect(billing('garbage'), kAutoBillOff);
    });

    test('known options pass through unchanged', () {
      for (final option in kAutoBillOptions) {
        expect(billing(option), option);
      }
    });
  });
}
