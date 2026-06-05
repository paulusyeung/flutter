import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_number_field.dart';

import '../../../../_localization_helper.dart';

/// Minimal company-scope host: holds a mutable settings blob, applies
/// `updateSettings` edits, exposes a company [draft] (so the widget can read
/// the `use_comma_as_decimal_place` flag), and reports no field errors. At
/// company level `OverridableField.bind` renders the child unwrapped, so
/// `isOverridden` / `setOverride` are never reached.
class _FakeHost extends SettingsDraftHost {
  _FakeHost(this._settings, {this.useComma = false});
  CompanySettings _settings;
  final bool useComma;

  @override
  CompanySettings get settings => _settings;
  @override
  CompanySettings get draftSettings => _settings;
  @override
  Company? get draft => Company(useCommaAsDecimalPlace: useComma);
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
          child: const SizedBox(
            width: 360,
            child: OverridableNumberField(
              label: 'Default Task Rate',
              apiKey: 'default_task_rate',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TextEditingController _controllerOf(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!;

void main() {
  testWidgets(
    'focused decimal entry keeps the typed separator (no mid-typing swallow)',
    (tester) async {
      final host = _FakeHost(const CompanySettings());
      await _pump(tester, host);

      // Type up to the trailing-separator intermediate state. `parseDecimal`
      // canonicalises "75." to 75, so without the focus guard the next rebuild
      // would overwrite the focused field back to "75" — eating the separator
      // (typing 75.5 would land as 755). The guard keeps the visible "75.".
      await tester.enterText(find.byType(TextField), '75.');
      await tester.pumpAndSettle();

      expect(_controllerOf(tester).text, '75.');
    },
  );

  testWidgets('a complete decimal value commits and survives a rebuild', (
    tester,
  ) async {
    final host = _FakeHost(const CompanySettings());
    await _pump(tester, host);

    await tester.enterText(find.byType(TextField), '75.5');
    await tester.pumpAndSettle();
    expect(host.settings.defaultTaskRate, 75.5);

    // Blur → the field reformats to the canonical display (still 75.5).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(_controllerOf(tester).text, '75.5');
  });

  testWidgets('comma-locale blurred display uses the comma separator', (
    tester,
  ) async {
    final host = _FakeHost(const CompanySettings(), useComma: true);
    await _pump(tester, host);

    // Comma input is parsed to the canonical dot-encoded wire value...
    await tester.enterText(find.byType(TextField), '75,5');
    await tester.pumpAndSettle();
    expect(host.settings.defaultTaskRate, 75.5);

    // ...and on blur a comma-locale user sees "75,5", not "75.5".
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(_controllerOf(tester).text, '75,5');
  });

  testWidgets('zero renders empty, not "0"', (tester) async {
    final host = _FakeHost(
      const CompanySettings().copyWith(defaultTaskRate: 0),
    );
    await _pump(tester, host);

    expect(_controllerOf(tester).text, '');
  });
}
