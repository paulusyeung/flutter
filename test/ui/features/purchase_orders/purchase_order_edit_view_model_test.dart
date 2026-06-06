import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/purchase_order_repository.dart';
import 'package:admin/data/services/purchase_orders_api.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_edit_view_model.dart';

class _NoopApi implements PurchaseOrdersApi {
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected API call: ${invocation.memberName}');
}

void main() {
  late AppDatabase db;
  late PurchaseOrderRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PurchaseOrderRepository(db: db, api: _NoopApi());
  });
  tearDown(() async {
    await db.close();
  });

  PurchaseOrderEditViewModel buildVm() => PurchaseOrderEditViewModel(
    repo: repo,
    companyId: 'co',
    vendorRequiredMessage: 'vendor required',
  );

  // Purchase-order invitations are keyed by `vendor_contact_id`. Changing the
  // vendor must drop invitations bound to the previous vendor — otherwise they
  // stay invisibly in the draft and serialize to a wrong-vendor recipient on
  // save. (The client-doc path does the same via `selectClient`.)
  group('setVendorId invitation lifecycle', () {
    test('changing the vendor clears invitations bound to the old vendor', () {
      final vm = buildVm();
      vm.setVendorId('v1');
      vm.setVendorContactInvitation('c1', true);
      expect(vm.draft.invitations, isNotEmpty);

      vm.setVendorId('v2');

      expect(vm.draft.vendorId, 'v2');
      expect(
        vm.draft.invitations,
        isEmpty,
        reason: 'invitations pointed at v1 contacts',
      );
      vm.dispose();
    });

    test('re-selecting the same vendor preserves the chosen contacts', () {
      final vm = buildVm();
      vm.setVendorId('v1');
      vm.setVendorContactInvitation('c1', true);

      vm.setVendorId('v1'); // no-op change must not wipe the selection

      expect(vm.draft.invitations.map((i) => i.vendorContactId), ['c1']);
      vm.dispose();
    });
  });
}
