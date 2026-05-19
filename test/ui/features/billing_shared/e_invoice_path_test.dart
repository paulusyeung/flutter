import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/billing/invitation.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/ui/features/billing_shared/view_models/billing_doc_edit_view_model.dart';

/// Minimal billing doc — only the open-ended `eInvoice` map matters here.
class _Doc {
  const _Doc(this.eInvoice);
  final Map<String, dynamic>? eInvoice;
}

/// Bare concrete VM to exercise the `eInvoice` path helpers in isolation.
class _FakeVm extends GenericBillingDocEditViewModel<_Doc> {
  _FakeVm(Map<String, dynamic>? seed) : super(initialDraft: _Doc(seed));

  @override
  List<LineItem> lineItemsOf(_Doc d) => const [];
  @override
  _Doc copyWithLineItems(_Doc d, List<LineItem> items) => d;
  @override
  List<Invitation> invitationsOf(_Doc d) => const [];
  @override
  _Doc copyWithInvitations(_Doc d, List<Invitation> inv) => d;
  @override
  Map<String, dynamic>? eInvoiceOf(_Doc d) => d.eInvoice;
  @override
  _Doc copyWithEInvoice(_Doc d, Map<String, dynamic>? e) => _Doc(e);
  @override
  BillingTotalsInput totalsInputOf(_Doc d) => BillingTotalsInput(
        lineItems: const [],
        discount: Decimal.zero,
        isAmountDiscount: false,
        usesInclusiveTaxes: false,
      );
  @override
  Future<_Doc> performSave() async => draft;
}

const _idPath = <Object>[
  'CreditNote',
  'BillingReference',
  0,
  'InvoiceDocumentReference',
  'ID',
];

void main() {
  group('setEInvoicePath / readEInvoicePath', () {
    test('builds nested maps + a JSON array index and round-trips', () {
      final vm = _FakeVm(null);
      vm.setEInvoicePath(_idPath, 'INV-1');

      expect(vm.readEInvoicePath(vm.draft, _idPath), 'INV-1');
      final e = vm.eInvoiceOf(vm.draft)!;
      final ref = e['CreditNote']['BillingReference'];
      expect(ref, isA<List<dynamic>>());
      expect((ref as List).length, 1);
      expect(ref[0]['InvoiceDocumentReference']['ID'], 'INV-1');
    });

    test('prunes only along the edited path — unrelated branches survive', () {
      final vm = _FakeVm({
        'Other': <String, dynamic>{}, // empty map, off-path
        'Keep': {'x': 'y'},
        'Arr': [
          <String, dynamic>{},
          {'k': 1},
        ],
      });

      vm.setEInvoicePath(_idPath, 'INV-9');

      final e = vm.eInvoiceOf(vm.draft)!;
      // Off-path empty map is NOT stripped (a whole-tree prune would).
      expect(e.containsKey('Other'), isTrue);
      expect(e['Keep'], {'x': 'y'});
      // Sibling array indices unchanged (no global compaction).
      expect((e['Arr'] as List).length, 2);
      expect(e['Arr'][1], {'k': 1});
      expect(vm.readEInvoicePath(vm.draft, _idPath), 'INV-9');
    });

    test('removing the leaf prunes the empty chain but not siblings', () {
      final vm = _FakeVm({'Keep': {'x': 'y'}});
      vm.setEInvoicePath(_idPath, 'INV-2');
      vm.setEInvoicePath(_idPath, null);

      final e = vm.eInvoiceOf(vm.draft);
      expect(e, isNotNull);
      expect(e!['Keep'], {'x': 'y'});
      // The whole CreditNote chain collapsed away once its only leaf went.
      expect(e.containsKey('CreditNote'), isFalse);
      expect(vm.readEInvoicePath(vm.draft, _idPath), isNull);
    });

    test('root collapses to null when the last value is removed', () {
      final vm = _FakeVm(null);
      vm.setEInvoicePath(_idPath, 'INV-3');
      vm.setEInvoicePath(_idPath, null);
      expect(vm.eInvoiceOf(vm.draft), isNull);
    });

    test('readEInvoicePath returns null for a missing path', () {
      final vm = _FakeVm({'CreditNote': <String, dynamic>{}});
      expect(vm.readEInvoicePath(vm.draft, _idPath), isNull);
    });
  });
}
