import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/models/domain/company.dart';

void main() {
  group('Company top-level field mapping', () {
    test('round-trips Workflow Settings top-level booleans through '
        'fromApi → toApiJson', () {
      const api = CompanyApi(
        id: 'co',
        name: 'Acme',
        stopOnUnpaidRecurring: true,
        useQuoteTermsOnConversion: true,
      );

      final domain = Company.fromApi(api);
      expect(domain.stopOnUnpaidRecurring, isTrue);
      expect(domain.useQuoteTermsOnConversion, isTrue);

      final json = domain.toApiJson();
      expect(json['stop_on_unpaid_recurring'], isTrue);
      expect(json['use_quote_terms_on_conversion'], isTrue);
    });

    test('Workflow Settings top-level booleans default to false when missing '
        'from the wire', () {
      final api = CompanyApi.fromJson(<String, dynamic>{'id': 'co'});
      final domain = Company.fromApi(api);
      expect(domain.stopOnUnpaidRecurring, isFalse);
      expect(domain.useQuoteTermsOnConversion, isFalse);
    });
  });
}
