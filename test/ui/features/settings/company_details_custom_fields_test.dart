import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/domain/custom_field_types.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';

import '../../../_localization_helper.dart';

/// Company Details renders the four company custom-field VALUE inputs through
/// the shared [EntityCustomFieldsSection] (`keyPrefix: 'company'`), so they
/// respect the configured type — date / switch / dropdown / text — instead of
/// the plain text box they used to be. These tests pin that company-specific
/// wiring: the `'company'` prefix, the `CompanySettings.customValue*` read /
/// write path, and the gate predicate the screen uses to show/hide the section.

/// One of each type, keyed under `company1..4` (the slots Company Details reads).
const _company = Company(
  customFields: {
    'company1': 'Joined|date',
    'company2': 'Active|switch',
    'company3': 'Region|North,South',
    'company4': 'Notes|single_line_text',
  },
);

/// Pumps exactly the section `CompanyDetailsScreen` builds, backed by a mutable
/// [CompanySettings] so the `onChanged` write-back path can be asserted.
Widget _host({
  required Company company,
  required CompanySettings Function() get,
  required ValueChanged<CompanySettings> set,
}) {
  return MaterialApp(
    theme: buildInTheme(InTheme.light),
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setState) {
            final s = get();
            return EntityCustomFieldsSection(
              keyPrefix: 'company',
              companyStream: Stream.value(company),
              wrapInCard: false,
              values: [
                s.customValue1 ?? '',
                s.customValue2 ?? '',
                s.customValue3 ?? '',
                s.customValue4 ?? '',
              ],
              onChanged: [
                (v) => setState(() => set(s.copyWith(customValue1: v))),
                (v) => setState(() => set(s.copyWith(customValue2: v))),
                (v) => setState(() => set(s.copyWith(customValue3: v))),
                (v) => setState(() => set(s.copyWith(customValue4: v))),
              ],
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'company custom values render by their configured type, not plain text',
    (tester) async {
      var settings = const CompanySettings();
      await tester.pumpWidget(
        _host(company: _company, get: () => settings, set: (s) => settings = s),
      );
      await tester.pumpAndSettle();

      // Pre-fix every slot was an OverridableTextField; now each renders the
      // widget its type calls for.
      expect(find.byType(InDateField), findsOneWidget); // company1 = date
      expect(find.byType(Switch), findsOneWidget); // company2 = switch
      expect(
        find.byType(SearchableDropdownField<String>),
        findsOneWidget, // company3 = dropdown
      );
      // Labels come from the part before the pipe.
      expect(find.text('Joined'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    },
  );

  testWidgets('toggling the switch writes yes/no to CompanySettings', (
    tester,
  ) async {
    var settings = const CompanySettings();
    await tester.pumpWidget(
      _host(company: _company, get: () => settings, set: (s) => settings = s),
    );
    await tester.pumpAndSettle();

    expect(settings.customValue2 ?? '', '');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    // company2 is the switch slot → its value lands on settings.customValue2.
    expect(settings.customValue2, 'yes');
  });

  testWidgets('typing in the slot-4 text field writes only customValue4', (
    tester,
  ) async {
    var settings = const CompanySettings();
    await tester.pumpWidget(
      _host(company: _company, get: () => settings, set: (s) => settings = s),
    );
    await tester.pumpAndSettle();

    // company4 = 'Notes|single_line_text' is a plain text field. Target it by
    // its label so we don't hit the date / dropdown fields' internal TextFields.
    final notesField = find.ancestor(
      of: find.text('Notes'),
      matching: find.byType(TextField),
    );
    expect(notesField, findsOneWidget);
    await tester.enterText(notesField, 'ACME-9');

    // The 4th onChanged closure must write customValue4 — and leave the other
    // three slots untouched (guards against a copy-paste slot mis-wire).
    expect(settings.customValue4, 'ACME-9');
    expect(settings.customValue1 ?? '', '');
    expect(settings.customValue2 ?? '', '');
    expect(settings.customValue3 ?? '', '');
  });

  test(
    'gate predicate shows the section only for a configured company slot',
    () {
      // The exact check `CompanyDetailsScreen.build` uses to decide whether to
      // render the Custom Fields card. A client-prefixed definition must not
      // trigger it — only `company1..4` count.
      bool hasCompanyCustomFields(Company c) => [1, 2, 3, 4].any(
        (i) => parseCustomField(c.customFields['company$i']).label.isNotEmpty,
      );

      expect(hasCompanyCustomFields(const Company()), isFalse);
      expect(
        hasCompanyCustomFields(
          const Company(customFields: {'client1': 'Region|North,South'}),
        ),
        isFalse,
      );
      expect(hasCompanyCustomFields(_company), isTrue);
      expect(
        hasCompanyCustomFields(
          const Company(customFields: {'company3': 'Tier'}),
        ),
        isTrue,
      );
    },
  );
}
