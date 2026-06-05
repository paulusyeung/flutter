// Regression guard: the biometric toggle renders straight from the auth
// session, with no internal availability FutureBuilder. The Device Settings
// screen already gates the whole Security section on
// BiometricService.isAvailable(), so the tile must not re-check — it just
// reflects session.biometricEnabled.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/widgets/biometric_toggle_tile.dart';

import '../../shell/_shell_test_helpers.dart';

void main() {
  testWidgets(
    'renders the switch directly from the session (no availability gate)',
    (tester) async {
      final fixture = await buildFixture(
        companies: const [
          FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
        ],
        currentCompanyId: 'c1',
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(
        wrapWithShell(fixture.services, const BiometricToggleTile()),
      );
      await tester.pumpAndSettle();

      // Visible immediately from the session — not gated behind an async
      // isAvailable() round-trip. No biometric flag persisted → off.
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.text('Biometric Authentication'), findsOneWidget);

      fixture.services.recentlyViewed.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
