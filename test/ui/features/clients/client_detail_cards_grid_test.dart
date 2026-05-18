import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_cards_grid.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_details_card.dart';

import '../../../_localization_helper.dart';

/// `ClientDetailCardsGrid` keeps a wholly-empty Details card in the wide
/// 3-column grid (so the columns stay aligned — no gap) but drops it from the
/// stacked single-column layout (mobile / master-detail sidebar preview).

Client _client({String phone = ''}) => Client.fromApi(
  ClientApi(id: 'c1', name: 'Acme', phone: phone, updatedAt: 1),
);

Future<void> _pump(WidgetTester tester, Client client, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClientDetailCardsGrid(client: client, formatter: null),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ClientDetailCardsGrid', () {
    testWidgets('empty Details card is dropped in the stacked layout', (
      tester,
    ) async {
      await _pump(tester, _client(), 500);
      expect(find.byType(ClientDetailDetailsCard), findsNothing);
    });

    testWidgets('empty Details card is kept in the wide grid (no gap)', (
      tester,
    ) async {
      await _pump(tester, _client(), 1200);
      expect(find.byType(ClientDetailDetailsCard), findsOneWidget);
    });

    testWidgets('Details card with a value is shown in the stacked layout', (
      tester,
    ) async {
      await _pump(tester, _client(phone: '555-1234'), 500);
      expect(find.byType(ClientDetailDetailsCard), findsOneWidget);
    });

    testWidgets(
      'stacked layout omits blank standard rows (label hidden), keeps the '
      'populated one',
      (tester) async {
        await _pump(tester, _client(phone: '555-1234'), 500);
        expect(find.text('Phone'), findsOneWidget);
        expect(find.text('555-1234'), findsOneWidget);
        // Website / VAT Number / ID Number are blank → no label, no dash.
        expect(find.text('Website'), findsNothing);
        expect(find.text('VAT Number'), findsNothing);
        expect(find.text('ID Number'), findsNothing);
        expect(find.text('—'), findsNothing);
      },
    );

    testWidgets(
      'wide grid keeps blank standard rows with a dimmed dash',
      (tester) async {
        await _pump(tester, _client(phone: '555-1234'), 1200);
        expect(find.text('Website'), findsOneWidget);
        expect(find.text('Phone'), findsOneWidget);
        expect(find.text('VAT Number'), findsOneWidget);
        expect(find.text('ID Number'), findsOneWidget);
        // The three blank standard fields each render a `—` placeholder.
        expect(find.text('—'), findsNWidgets(3));
      },
    );
  });
}
