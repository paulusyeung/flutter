import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/static/pdf_catalogs.dart';

void main() {
  group('kPdfVariableSections', () {
    test('every section keyed under [PdfVariableSection] is present in '
        '[kPdfVariableSectionOrder] in display order', () {
      final keys = kPdfVariableSections.keys.toSet();
      final order = kPdfVariableSectionOrder.toSet();
      expect(
        keys,
        order,
        reason: 'kPdfVariableSections and kPdfVariableSectionOrder must '
            'enumerate the same section keys',
      );
    });

    test('every section\'s defaultSelected is a subset of available', () {
      for (final entry in kPdfVariableSections.entries) {
        final cat = entry.value;
        final missing = cat.defaultSelected
            .where((v) => !cat.available.contains(v))
            .toList();
        expect(
          missing,
          isEmpty,
          reason: 'section "${entry.key}" defaultSelected includes variables '
              'that are not in `available`: $missing',
        );
      }
    });

    test('every available variable starts with \$', () {
      for (final entry in kPdfVariableSections.entries) {
        for (final v in entry.value.available) {
          expect(
            v.startsWith('\$'),
            isTrue,
            reason: 'section "${entry.key}" variable "$v" missing leading \$',
          );
        }
      }
    });

    test('client_details includes location_name and postal_city variants '
        '(audit follow-up)', () {
      final available =
          kPdfVariableSections[PdfVariableSection.clientDetails]!.available;
      expect(available, contains('\$client.location_name'));
      expect(available, contains('\$client.postal_city'));
      expect(available, contains('\$client.postal_city_state'));
    });

    test('purchase_order_details includes po_number and balance_due '
        '(audit follow-up)', () {
      final available = kPdfVariableSections[
              PdfVariableSection.purchaseOrderDetails]!
          .available;
      expect(available, contains('\$purchase_order.po_number'));
      expect(available, contains('\$purchase_order.balance_due'));
    });

    test('total_columns default-selected does not include net_subtotal '
        '(matches admin-portal default)', () {
      final defaults =
          kPdfVariableSections[PdfVariableSection.totalColumns]!.defaultSelected;
      expect(defaults, isNot(contains('\$net_subtotal')));
      expect(defaults, contains('\$subtotal'));
    });
  });
}
