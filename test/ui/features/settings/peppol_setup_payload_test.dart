import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/views/advanced/e_invoice/peppol_onboarding_card.dart';

Map<String, dynamic> _build({
  required bool isSingapore,
  required bool isBusiness,
}) => buildPeppolSetupPayload(
  isSingapore: isSingapore,
  isBusiness: isBusiness,
  partyName: 'Acme',
  line1: 'L1',
  line2: 'L2',
  city: 'Town',
  county: 'State',
  zip: '00000',
  countryId: isSingapore ? '702' : '276',
  vatNumber: 'VAT1',
  idNumber: 'ID1',
  actsAsSender: true,
  actsAsReceiver: false,
  tenantId: 'co1',
  signerName: 'Jane Tan',
  signerEmail: 'jane@acme.sg',
  eInvoicingToken: 'eitok',
);

void main() {
  group('buildPeppolSetupPayload — EU (regression guard)', () {
    test('business: exact historically-shipped keys, no SG fields', () {
      final p = _build(isSingapore: false, isBusiness: true);
      expect(p.keys.toSet(), {
        'party_name',
        'line1',
        'line2',
        'city',
        'county',
        'zip',
        'country',
        'acts_as_sender',
        'acts_as_receiver',
        'tenant_id',
        'vat_number',
        'classification',
      });
      expect(p['classification'], 'business');
      expect(p['vat_number'], 'VAT1');
      expect(p['country'], '276');
      expect(p.containsKey('id_number'), isFalse);
      expect(p.containsKey('c5_signer_name'), isFalse);
      expect(p.containsKey('e_invoicing_token'), isFalse);
    });

    test('individual: id_number replaces vat, classification individual', () {
      final p = _build(isSingapore: false, isBusiness: false);
      expect(p['classification'], 'individual');
      expect(p['id_number'], 'ID1');
      expect(p.containsKey('vat_number'), isFalse);
    });
  });

  group('buildPeppolSetupPayload — Singapore (CorpPass)', () {
    test('always sends UEN + C5 signer + e_invoicing_token', () {
      final p = _build(isSingapore: true, isBusiness: true);
      expect(p['country'], '702');
      expect(p['id_number'], 'ID1'); // UEN, always
      expect(p['c5_signer_name'], 'Jane Tan');
      expect(p['c5_signer_email'], 'jane@acme.sg');
      expect(p['e_invoicing_token'], 'eitok');
      expect(p['classification'], 'business');
      expect(p.containsKey('vat_number'), isFalse);
    });

    test('non-business classification is government (not individual)', () {
      final p = _build(isSingapore: true, isBusiness: false);
      expect(p['classification'], 'government');
      expect(p['id_number'], 'ID1');
    });
  });
}
