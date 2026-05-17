/// Live demo coverage — settings screens.
///
/// Boots a live session and walks the settings shells (Company Details,
/// User Details, Localization) against `https://demo.invoiceninja.com`.
/// A focused growth area: add more settings sub-screens here. Shared infra
/// is in `../support/demo_harness.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/payment_terms_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/tax_rates_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_shell.dart';
import 'package:admin/ui/features/settings/views/basic/device_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_shell.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/user_details_shell.dart';

import '../support/demo_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerDemoReachabilityProbe();

  testWidgets('settings screens mount against a live session', (tester) async {
    if (skipIfUnreachable()) return;

    await bootLoggedIn(tester, initialLocation: '/settings/company_details');
    await pumpUntilFound(tester, find.byType(CompanyDetailsShell));
    expect(find.byType(CompanyDetailsShell), findsOneWidget);

    await goAndExpect(
      tester,
      route: '/settings/user_details',
      screenType: UserDetailsShell,
    );
    await goAndExpect(
      tester,
      route: '/settings/localization',
      screenType: LocalizationShell,
    );

    // Breadth across the settings decision-tree styles: a device-local
    // screen (no VM/server) and two entity-like settings list screens.
    // Mount-only — proves the screen loads against a live session without
    // an ErrorView (🟡 in FEATURES.md, not a behaviour assertion).
    await goAndExpect(
      tester,
      route: '/settings/device_settings',
      screenType: DeviceSettingsScreen,
    );
    await goAndExpect(
      tester,
      route: '/settings/payment_terms',
      screenType: PaymentTermsScreen,
    );
    await goAndExpect(
      tester,
      route: '/settings/tax_rates',
      screenType: TaxRatesScreen,
    );

    // End on a non-editor screen so `super_editor` (mounted by the markdown
    // override fields on the settings shells) disposes gracefully while
    // frames are still pumping, instead of mid-animation at teardown.
    await goAndExpect(tester, route: '/clients', screenType: ClientListScreen);
  });
}
