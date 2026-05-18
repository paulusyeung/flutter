// Responsive regression net. Sweeps representative layout-bearing widgets
// across narrow / medium / wide surfaces and fails on any RenderFlex
// overflow or unbounded-constraint violation. The point is a cheap guard so
// a stray full-width `Expanded` / unconstrained `Row` doesn't silently break
// the mobile (or wide) layout — exactly the gap the foundation audit flagged.
//
// Scope: Services-free widgets only. Full feature screens (list / edit /
// settings) need the `Provider<Services>` harness; pulling each through here
// is the documented follow-up (see the plan's C3 reasoning — the VM-level
// pattern is the cheaper canonical edit/list assertion). New responsive bugs
// in pure layout widgets belong here; add the widget + a width sweep.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';

import '../_responsive_helper.dart';

void main() {
  group('no overflow across breakpoints', () {
    for (final width in kResponsiveWidths) {
      testWidgets('ClientDetailCardsGrid @ ${width.toInt()}px', (tester) async {
        final client = Client.fromApi(
          ClientApi(
            id: 'c1',
            name: 'Acme Corporation',
            phone: '555-0100',
            website: 'https://acme.example',
            updatedAt: 1,
          ),
        );
        await pumpAt(tester, width, ClientDetailCardsGrid(
          client: client,
          formatter: null,
        ));
        expectNoOverflow(tester);
      });

      testWidgets('EmptyState with action @ ${width.toInt()}px', (
        tester,
      ) async {
        await pumpAt(
          tester,
          width,
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
            subtitle: 'Create your first record to get started.',
            action: FilledButton(
              onPressed: () {},
              child: const Text('New record'),
            ),
          ),
          scroll: false,
        );
        expectNoOverflow(tester);
      });
    }
  });
}
