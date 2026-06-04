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
import 'package:admin/ui/features/settings/widgets/overridable_date_field.dart';
import 'package:admin/utils/formatting.dart';

import '../../../../_localization_helper.dart';

const _settings = CompanyFormatSettings(
  currencyId: '1',
  countryId: '840',
  dateFormatId: 'X',
  useCommaAsDecimalPlace: false,
  showCurrencyCode: false,
  enableMilitaryTime: false,
  locale: '',
);

final _formatter = Formatter(
  settings: _settings,
  currencies: const {},
  countries: const {},
  dateFormats: const {'X': DatetimeFormat(id: 'X', format: 'd/MMM/yyyy')},
);

/// Minimal company-scope host: holds a mutable settings blob, applies
/// `updateSettings` edits, and reports no field errors. At company level
/// `OverridableField.bind` renders the child unwrapped, so `isOverridden` /
/// `setOverride` are never reached.
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

  // Lifecycle surface — inert for this isolated field test.
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

Future<void> _pump(WidgetTester tester, _FakeHost host) async {
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
            ChangeNotifierProvider<SettingsDraftHost>.value(value: host),
          ],
          child: SizedBox(
            width: 360,
            child: OverridableDateField(
              label: 'Next Reset',
              apiKey: 'reset_counter_date',
              formatter: _formatter,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the seeded value in the company date format', (
    tester,
  ) async {
    final host = _FakeHost(
      const CompanySettings().copyWith(resetCounterDate: '2026-05-14'),
    );
    await _pump(tester, host);

    expect(find.text('14/May/2026'), findsOneWidget);
    // Typed-entry field (InDateField), not the old tap-only InputDecorator.
    expect(find.byIcon(Icons.date_range), findsOneWidget);
  });

  testWidgets('typing an ISO date commits it as ISO to the host', (
    tester,
  ) async {
    final host = _FakeHost(const CompanySettings());
    await _pump(tester, host);

    await tester.enterText(find.byType(TextField), '2026-07-15');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(host.settings.resetCounterDate, '2026-07-15');
  });

  testWidgets('typing the "today" shortcut commits today as ISO', (
    tester,
  ) async {
    final host = _FakeHost(const CompanySettings());
    await _pump(tester, host);

    await tester.enterText(find.byType(TextField), 'today');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expected =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    expect(host.settings.resetCounterDate, expected);
  });
}
