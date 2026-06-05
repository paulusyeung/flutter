import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/template_options.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/widgets/reminder_rule_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_currency_field.dart';
import 'package:admin/utils/formatting.dart';

import '../../../../../../_localization_helper.dart';

/// Minimal company-scope host (mirrors `overridable_date_field_test.dart`):
/// holds a mutable settings blob, applies `updateSettings` edits, no field
/// errors. At company level `OverridableField.bind` renders children unwrapped.
class _FakeHost extends SettingsDraftHost {
  _FakeHost(this._settings);
  CompanySettings _settings;

  @override
  CompanySettings get settings => _settings;
  @override
  CompanySettings get draftSettings => _settings;
  @override
  Map<String, List<String>> get fieldErrors => const {};
  @override
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    _settings = edit(_settings);
    notifyListeners();
  }

  @override
  bool get isLoaded => true;
  @override
  bool get isDirty => false;
  @override
  bool get isSaving => false;
  @override
  String? get loadError => null;
  @override
  String? get submitError => null;
  @override
  void reset() {}
  @override
  Future<Object?> save() async => null;
  @override
  Future<void> load() async {}
}

final _formatter = Formatter(
  settings: const CompanyFormatSettings(
    currencyId: '1',
    countryId: '840',
    dateFormatId: 'X',
    useCommaAsDecimalPlace: false,
    showCurrencyCode: false,
    enableMilitaryTime: false,
    locale: '',
  ),
  currencies: const {},
  countries: const {},
  dateFormats: const {'X': DatetimeFormat(id: 'X', format: 'd/MMM/yyyy')},
);

TemplateOption get _reminder1 =>
    kTemplateOptions.firstWhere((o) => o.key == 'reminder1');

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Formatter? formatter,
    required bool enabled,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsLevelController>.value(
                value: SettingsLevelController(),
              ),
              ChangeNotifierProvider<SettingsDraftHost>.value(
                value: _FakeHost(const CompanySettings()),
              ),
            ],
            child: SingleChildScrollView(
              child: ReminderRuleSection(
                template: _reminder1,
                formatter: formatter,
                currencyId: '',
                enabled: enabled,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('formatter present → late-fee amount uses the currency field', (
    tester,
  ) async {
    await pump(tester, formatter: _formatter, enabled: true);

    expect(find.byType(OverridableCurrencyField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'formatter null → section still renders (no currency field, number '
    'fallback), so reminder config is never hidden',
    (tester) async {
      await pump(tester, formatter: null, enabled: true);

      // The currency field is the only part that needs a Formatter; it falls
      // back to a plain number field when none is available.
      expect(find.byType(OverridableCurrencyField), findsNothing);
      // The rest of the rule still renders: enable switch + schedule dropdown.
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('enabled:false → enable switch and schedule dropdown are gated', (
    tester,
  ) async {
    await pump(tester, formatter: _formatter, enabled: false);

    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.onChanged, isNull);

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.onChanged, isNull);
  });
}
