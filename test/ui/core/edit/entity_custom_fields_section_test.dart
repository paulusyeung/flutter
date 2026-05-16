import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';

import '../../../_localization_helper.dart';

const _company = Company(
  customFields: {
    'invoice1': 'Slot One|a,b',
    'invoice2': 'Slot Two',
    'invoice3': 'Slot Three',
    'invoice4': 'Slot Four',
  },
);

Future<void> _pump(WidgetTester tester, {required List<int> slots}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: EntityCustomFieldsSection(
            keyPrefix: 'invoice',
            companyStream: Stream.value(_company),
            values: const ['', '', '', ''],
            onChanged: [(_) {}, (_) {}, (_) {}, (_) {}],
            wrapInCard: false,
            slots: slots,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default renders all four configured slots', (tester) async {
    await _pump(tester, slots: const [1, 2, 3, 4]);
    expect(find.text('Slot One'), findsOneWidget);
    expect(find.text('Slot Two'), findsOneWidget);
    expect(find.text('Slot Three'), findsOneWidget);
    expect(find.text('Slot Four'), findsOneWidget);
  });

  testWidgets('slots:[1,3] renders only custom 1 & 3', (tester) async {
    await _pump(tester, slots: const [1, 3]);
    expect(find.text('Slot One'), findsOneWidget);
    expect(find.text('Slot Three'), findsOneWidget);
    expect(find.text('Slot Two'), findsNothing);
    expect(find.text('Slot Four'), findsNothing);
  });

  testWidgets('slots:[2,4] renders only custom 2 & 4', (tester) async {
    await _pump(tester, slots: const [2, 4]);
    expect(find.text('Slot Two'), findsOneWidget);
    expect(find.text('Slot Four'), findsOneWidget);
    expect(find.text('Slot One'), findsNothing);
    expect(find.text('Slot Three'), findsNothing);
  });
}
