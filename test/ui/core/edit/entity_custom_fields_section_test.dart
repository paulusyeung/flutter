import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

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

  testWidgets(
    'wrapInCard:true with no cardTitle renders inline, no empty card',
    (tester) async {
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
                // wrapInCard defaults to true; no cardTitle → must not draw a
                // titleless DashboardCardShell (the stray empty box).
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Slot One'), findsOneWidget);
      expect(find.byType(DashboardCardShell), findsNothing);
    },
  );

  group('type-aware rendering', () {
    Future<void> pumpTyped(
      WidgetTester tester, {
      required Company company,
      required List<String> values,
      required List<ValueChanged<String>> onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildInTheme(InTheme.light),
          localizationsDelegates: kTestLocalizationsDelegates,
          supportedLocales: kTestSupportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: EntityCustomFieldsSection(
                keyPrefix: 'invoice',
                companyStream: Stream.value(company),
                values: values,
                onChanged: onChanged,
                wrapInCard: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('switch renders a Switch and writes yes/no', (tester) async {
      String? written;
      await pumpTyped(
        tester,
        company: const Company(customFields: {'invoice1': 'Active|switch'}),
        values: const ['no', '', '', ''],
        onChanged: [(v) => written = v, (_) {}, (_) {}, (_) {}],
      );
      expect(find.byType(Switch), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(written, 'yes');
    });

    testWidgets('date renders an InDateField', (tester) async {
      await pumpTyped(
        tester,
        company: const Company(customFields: {'invoice1': 'Due|date'}),
        values: const ['', '', '', ''],
        onChanged: [(_) {}, (_) {}, (_) {}, (_) {}],
      );
      expect(find.byType(InDateField), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
    });

    testWidgets('dropdown renders a SearchableDropdownField', (tester) async {
      await pumpTyped(
        tester,
        company: const Company(
          customFields: {'invoice1': 'Region|North,South'},
        ),
        values: const ['', '', '', ''],
        onChanged: [(_) {}, (_) {}, (_) {}, (_) {}],
      );
      expect(find.byType(SearchableDropdownField<String>), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
    });

    testWidgets('dropdown surfaces a stored value no longer in the options', (
      tester,
    ) async {
      // Options were edited to North,South after this entity was saved with
      // 'West' — the stored value must stay visible + selected, not blank.
      await pumpTyped(
        tester,
        company: const Company(
          customFields: {'invoice1': 'Region|North,South'},
        ),
        values: const ['West', '', '', ''],
        onChanged: [(_) {}, (_) {}, (_) {}, (_) {}],
      );
      final field = tester.widget<SearchableDropdownField<String>>(
        find.byType(SearchableDropdownField<String>),
      );
      expect(field.items, contains('West'));
      expect(field.initialValue, 'West');
    });

    testWidgets('multi-line renders a 3-line EntityEditField', (tester) async {
      await pumpTyped(
        tester,
        company: const Company(
          customFields: {'invoice1': 'Notes|multi_line_text'},
        ),
        values: const ['', '', '', ''],
        onChanged: [(_) {}, (_) {}, (_) {}, (_) {}],
      );
      final field = tester.widget<EntityEditField>(
        find.byType(EntityEditField),
      );
      expect(field.maxLines, 3);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('single-line writes the entered text', (tester) async {
      String? written;
      await pumpTyped(
        tester,
        company: const Company(
          customFields: {'invoice1': 'Ref|single_line_text'},
        ),
        values: const ['', '', '', ''],
        onChanged: [(v) => written = v, (_) {}, (_) {}, (_) {}],
      );
      expect(find.byType(EntityEditField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ABC-1');
      expect(written, 'ABC-1');
    });
  });
}
