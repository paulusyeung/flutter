import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/invitation_api_model.dart';
import 'package:admin/data/models/api/purchase_order_api_model.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_actions.dart';

import '../shell/_shell_test_helpers.dart';

/// Gating coverage for `PurchaseOrderActions.itemsFor` — the single source of
/// truth for which actions a PO surfaces. Encodes the server's real rules
/// (verified against the Laravel `PurchaseOrderController`):
///   - there is NO admin Accept (a PO is accepted by the vendor via the
///     portal; the `/bulk` allow-list has no `accept`),
///   - Cancel on a Draft or Sent PO (server no-ops cancel once `status > SENT`),
///   - Add to inventory only on an Accepted PO (→ Received),
///   - Convert to expense only while no expense exists; once expensed the menu
///     shows View expense instead,
///   - Vendor portal only when an invitation carries a portal link.
PurchaseOrder _po({
  String id = 'po1',
  String statusId = '1', // 1 draft / 2 sent / 3 accepted / 4 received
  String expenseId = '',
  bool isDeleted = false,
  int archivedAt = 0,
  List<InvitationApi> invitations = const [],
}) => PurchaseOrder.fromApi(
  PurchaseOrderApi(
    id: id,
    statusId: statusId,
    expenseId: expenseId,
    isDeleted: isDeleted,
    archivedAt: archivedAt,
    invitations: invitations,
  ),
);

void main() {
  Future<List<EntityActionItem<PurchaseOrderAction>>> resolveItems(
    WidgetTester tester,
    PurchaseOrder po, {
    String? eInvoiceType,
  }) async {
    final fixture = await buildFixture(
      companies: [const FakeCompany(id: 'co1', name: 'Co')],
    );
    addTearDown(fixture.dispose);

    late List<EntityActionItem<PurchaseOrderAction>> items;
    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        Builder(
          builder: (context) {
            items = PurchaseOrderActions.itemsFor(
              context,
              po,
              (_) {},
              eInvoiceType: eInvoiceType,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return items;
  }

  Set<PurchaseOrderAction> kindsOf(
    List<EntityActionItem<PurchaseOrderAction>> items,
  ) => items.map((i) => i.kind).toSet();

  bool? enabledOf(
    List<EntityActionItem<PurchaseOrderAction>> items,
    PurchaseOrderAction kind,
  ) {
    for (final i in items) {
      if (i.kind == kind) return i.enabled;
    }
    return null;
  }

  test('only mark_sent carries a save-param — accept is gone', () {
    // Accept used to be a save-param action (`?accept=true`), which the server
    // silently ignores. Removing it means mark_sent is the lone save-param.
    for (final a in PurchaseOrderAction.values) {
      final param = PurchaseOrderActions.saveParamFor(a);
      if (a == PurchaseOrderAction.markSent) {
        expect(param, {'mark_sent': 'true'});
      } else {
        expect(param, isNull, reason: '$a must not be a save-param action');
      }
    }
  });

  testWidgets('add to inventory is enabled only on an Accepted PO', (
    tester,
  ) async {
    expect(
      enabledOf(
        await resolveItems(tester, _po(statusId: '2')),
        PurchaseOrderAction.addToInventory,
      ),
      isFalse,
      reason: 'a Sent PO cannot be added to inventory yet',
    );
    expect(
      enabledOf(
        await resolveItems(tester, _po(statusId: '3')),
        PurchaseOrderAction.addToInventory,
      ),
      isTrue,
      reason: 'an Accepted PO can be added to inventory',
    );
  });

  testWidgets('cancel is enabled on a Draft or Sent PO', (tester) async {
    expect(
      enabledOf(
        await resolveItems(tester, _po(statusId: '1')),
        PurchaseOrderAction.cancel,
      ),
      isTrue,
      reason: 'server allows cancel while status <= SENT (Draft included)',
    );
    expect(
      enabledOf(
        await resolveItems(tester, _po(statusId: '2')),
        PurchaseOrderAction.cancel,
      ),
      isTrue,
    );
    expect(
      enabledOf(
        await resolveItems(tester, _po(statusId: '3')),
        PurchaseOrderAction.cancel,
      ),
      isFalse,
      reason: 'server no-ops cancel once status > SENT',
    );
  });

  testWidgets('convert-to-expense shows only until an expense exists', (
    tester,
  ) async {
    final noExpense = kindsOf(await resolveItems(tester, _po(statusId: '3')));
    expect(noExpense, contains(PurchaseOrderAction.convertToExpense));
    expect(noExpense, isNot(contains(PurchaseOrderAction.viewExpense)));

    final expensed = kindsOf(
      await resolveItems(tester, _po(statusId: '3', expenseId: 'e1')),
    );
    expect(expensed, contains(PurchaseOrderAction.viewExpense));
    expect(expensed, isNot(contains(PurchaseOrderAction.convertToExpense)));
  });

  testWidgets('vendor portal shows only with an invitation link', (
    tester,
  ) async {
    expect(
      kindsOf(await resolveItems(tester, _po())),
      isNot(contains(PurchaseOrderAction.vendorPortal)),
    );
    expect(
      kindsOf(
        await resolveItems(
          tester,
          _po(invitations: const [InvitationApi(link: 'https://portal/x')]),
        ),
      ),
      contains(PurchaseOrderAction.vendorPortal),
    );
  });

  testWidgets(
    'download e-purchase-order needs e-invoicing AND an invitation key',
    (tester) async {
      const keyed = [InvitationApi(key: 'k1', link: 'https://portal/x')];

      // e-invoicing off → hidden even with a keyed invitation.
      expect(
        kindsOf(await resolveItems(tester, _po(invitations: keyed))),
        isNot(contains(PurchaseOrderAction.downloadEPurchaseOrder)),
      );

      // e-invoicing on but no invitation (no key) → still hidden.
      expect(
        kindsOf(await resolveItems(tester, _po(), eInvoiceType: 'PEPPOL')),
        isNot(contains(PurchaseOrderAction.downloadEPurchaseOrder)),
      );

      // e-invoicing on + a keyed invitation → shown.
      expect(
        kindsOf(
          await resolveItems(
            tester,
            _po(invitations: keyed),
            eInvoiceType: 'PEPPOL',
          ),
        ),
        contains(PurchaseOrderAction.downloadEPurchaseOrder),
      );
    },
  );
}
