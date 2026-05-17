/// Live demo coverage — create/edit write round-trips.
///
/// Drives the real edit screens to create (and edit) records on
/// `https://demo.invoiceninja.com`, verifies them authoritatively via the
/// server API, and hard-deletes them in teardown. This **intentionally
/// writes** to the shared demo account (team-lead-approved override of the
/// "no automated writes" note in `docs/probing-the-demo-api.md`); records
/// use the [kWriteMarker] prefix. Shared infra is in
/// `../support/demo_harness.dart`. A focused growth area: add more entities
/// (invoice, quote, payment, …) here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_edit_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_list_screen.dart';

import '../support/demo_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerDemoReachabilityProbe();

  testWidgets(
    'create + edit a client round-trips to the demo server (UI → outbox → API)',
    (tester) async {
      if (skipIfUnreachable()) return;
      final services = await bootLoggedIn(
        tester,
        initialLocation: '/clients/new',
      );

      var createdId = '';
      // LIFO → runs before the app teardown, while creds are live, so a
      // mid-test failure still purges the created record.
      addTearDown(
        () => deleteEntityBestEffort(
          services,
          apiPath: '/api/v1/clients',
          id: createdId,
        ),
      );

      await withFailureCapture(tester, 'client-create-edit', () async {
        await pumpUntilFound(tester, find.byType(ClientEditScreen));
        final companyId = services.auth.session.value!.currentCompanyId;
        expect(companyId, isNotEmpty);

        // CREATE — type a unique name into the autofocused first field and
        // save through the real Save action. Verify on the *server*.
        final createName = uniqueLabel('client');
        await enterIdentity(tester, ClientEditScreen, createName);
        await saveAndLeaveEditor(
          tester,
          ClientEditScreen,
          listRoute: '/clients',
          listType: ClientListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        createdId = await findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/clients',
          unique: createName,
        );
        expect(
          createdId,
          isNotEmpty,
          reason: 'client create did not round-trip to the demo server',
        );

        // EDIT — full UI: open the created record's edit form, change the
        // name, Save, and confirm the *server* reflects it. First wait for
        // the row to exist locally so the edit screen loads in edit mode
        // (not create); `awaitPrefillContains` then waits for the field to
        // be populated before typing — typing pre-load would leave the VM
        // create-like and Save would POST a duplicate.
        final editName = uniqueLabel('client-edited');
        await services.clients
            .watch(companyId: companyId, id: createdId)
            .firstWhere((c) => c != null && c.id == createdId)
            .timeout(const Duration(seconds: 30));
        goRouter(tester).go('/clients/$createdId/edit');
        await pumpUntilFound(tester, find.byType(ClientEditScreen));
        await enterIdentity(
          tester,
          ClientEditScreen,
          editName,
          awaitPrefillContains: kWriteMarker,
        );
        await saveAndLeaveEditor(
          tester,
          ClientEditScreen,
          listRoute: '/clients',
          listType: ClientListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        final editedId = await findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/clients',
          unique: editName,
        );
        expect(
          editedId,
          createdId,
          reason: 'client edit did not round-trip to the demo server',
        );
      });
    },
  );

  testWidgets('create a product round-trips to the demo server', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;
    final services = await bootLoggedIn(
      tester,
      initialLocation: '/products/new',
    );

    var createdId = '';
    addTearDown(
      () => deleteEntityBestEffort(
        services,
        apiPath: '/api/v1/products',
        id: createdId,
      ),
    );

    await withFailureCapture(tester, 'product-create', () async {
      await pumpUntilFound(tester, find.byType(ProductEditScreen));
      final companyId = services.auth.session.value!.currentCompanyId;

      // First field on the product form is the product key (autofocused).
      final productKey = uniqueLabel('product');
      await enterIdentity(tester, ProductEditScreen, productKey);
      await saveAndLeaveEditor(
        tester,
        ProductEditScreen,
        listRoute: '/products',
        listType: ProductListScreen,
      );
      await services.sync.drainOnce(companyId: companyId);

      createdId = await findServerEntityId(
        tester,
        services,
        listPath: '/api/v1/products',
        unique: productKey,
      );
      expect(
        createdId,
        isNotEmpty,
        reason: 'product create did not round-trip to the demo server',
      );
    });
  });

  testWidgets(
    'create + edit a vendor round-trips to the demo server (UI → outbox → API)',
    (tester) async {
      if (skipIfUnreachable()) return;
      final services = await bootLoggedIn(
        tester,
        initialLocation: '/vendors/new',
      );

      var createdId = '';
      addTearDown(
        () => deleteEntityBestEffort(
          services,
          apiPath: '/api/v1/vendors',
          id: createdId,
        ),
      );

      await withFailureCapture(tester, 'vendor-create-edit', () async {
        await pumpUntilFound(tester, find.byType(VendorEditScreen));
        final companyId = services.auth.session.value!.currentCompanyId;
        expect(companyId, isNotEmpty);

        // Vendor is the same single-identity-field shape as client:
        // `draftIsNonEmpty` ⇒ name. Same create → server-verify → edit →
        // server-verify → cleanup flow as the client test.
        final createName = uniqueLabel('vendor');
        await enterIdentity(tester, VendorEditScreen, createName);
        await saveAndLeaveEditor(
          tester,
          VendorEditScreen,
          listRoute: '/vendors',
          listType: VendorListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        createdId = await findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/vendors',
          unique: createName,
        );
        expect(
          createdId,
          isNotEmpty,
          reason: 'vendor create did not round-trip to the demo server',
        );

        // EDIT — wait for the row locally so the edit screen loads in edit
        // mode (not create), then change the name and verify on the server.
        final editName = uniqueLabel('vendor-edited');
        await services.vendors
            .watch(companyId: companyId, id: createdId)
            .firstWhere((v) => v != null && v.id == createdId)
            .timeout(const Duration(seconds: 30));
        goRouter(tester).go('/vendors/$createdId/edit');
        await pumpUntilFound(tester, find.byType(VendorEditScreen));
        await enterIdentity(
          tester,
          VendorEditScreen,
          editName,
          awaitPrefillContains: kWriteMarker,
        );
        await saveAndLeaveEditor(
          tester,
          VendorEditScreen,
          listRoute: '/vendors',
          listType: VendorListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        final editedId = await findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/vendors',
          unique: editName,
        );
        expect(
          editedId,
          createdId,
          reason: 'vendor edit did not round-trip to the demo server',
        );
      });
    },
  );
}
