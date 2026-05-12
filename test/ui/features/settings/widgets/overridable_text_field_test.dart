import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';

/// Fake host used to drive the widget without booting Drift / a real
/// repository. Mirrors the public API the widget reads.
class _FakeHost extends SettingsDraftHost {
  CompanySettings _settings = const CompanySettingsApi();
  Map<String, List<String>> _fieldErrors = const {};
  int updateSettingsCalls = 0;
  String? lastValueWritten;
  int setOverrideCalls = 0;
  bool lastOverrideEnabled = false;

  @override
  CompanySettings get settings => _settings;

  @override
  Company? get draft =>
      Company(id: 'co', name: settings.name ?? '', settings: settings);

  @override
  Map<String, List<String>> get fieldErrors => _fieldErrors;

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
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    updateSettingsCalls += 1;
    _settings = edit(_settings);
    lastValueWritten = _settings.name;
    notifyListeners();
  }

  @override
  void updateCompany(Company Function(Company) edit) {}

  @override
  bool isOverridden(String apiKey) {
    final json = _settings.toJson();
    return json[apiKey] != null;
  }

  @override
  void setOverride({
    required String apiKey,
    required bool enabled,
    String? cascadedValue,
  }) {
    setOverrideCalls += 1;
    lastOverrideEnabled = enabled;
    final value = enabled ? cascadedValue : null;
    _settings = _settings.copyWith(vatNumber: value);
    notifyListeners();
  }

  void seed(CompanySettings s) {
    _settings = s;
    notifyListeners();
  }

  void setFieldErrors(Map<String, List<String>> errors) {
    _fieldErrors = errors;
    notifyListeners();
  }
}

Widget _wrap({
  required _FakeHost host,
  required SettingsLevelController level,
  required Widget child,
}) {
  return MaterialApp(
    // OverridableField reads `context.inTheme` (a `ThemeExtension`) at
    // group/client level, so the test theme has to be the real one.
    theme: buildInTheme(InTheme.light),
    home: MultiProvider(
      providers: [
        ListenableProvider<SettingsDraftHost>.value(value: host),
        ChangeNotifierProvider<SettingsLevelController>.value(value: level),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('OverridableTextField — company level', () {
    testWidgets('reads the current value off the host settings', (
      tester,
    ) async {
      final host = _FakeHost()..seed(const CompanySettingsApi(name: 'Acme'));
      final level = SettingsLevelController();

      await tester.pumpWidget(
        _wrap(
          host: host,
          level: level,
          child: const OverridableTextField(label: 'Name', apiKey: 'name'),
        ),
      );

      expect(find.text('Acme'), findsOneWidget);
    });

    testWidgets('onChanged calls host.updateSettings', (tester) async {
      final host = _FakeHost();
      final level = SettingsLevelController();

      await tester.pumpWidget(
        _wrap(
          host: host,
          level: level,
          child: const OverridableTextField(label: 'Name', apiKey: 'name'),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pump();

      expect(host.updateSettingsCalls, greaterThan(0));
      expect(host.lastValueWritten, 'Beta');
    });

    testWidgets(
      'host-side mutation (override-toggle-style) rebuilds the field',
      (tester) async {
        final host = _FakeHost();
        final level = SettingsLevelController();

        await tester.pumpWidget(
          _wrap(
            host: host,
            level: level,
            child: const OverridableTextField(
              label: 'VAT',
              apiKey: 'vat_number',
            ),
          ),
        );
        expect(find.text(''), findsOneWidget);

        // External mutation — emulates an override-toggle landing a new value.
        host.seed(const CompanySettingsApi(vatNumber: 'EU777'));
        await tester.pump();

        expect(find.text('EU777'), findsOneWidget);
      },
    );

    testWidgets(
      'fieldErrors[apiKey] surfaces as the InputDecoration.errorText',
      (tester) async {
        final host = _FakeHost();
        final level = SettingsLevelController();

        await tester.pumpWidget(
          _wrap(
            host: host,
            level: level,
            child: const OverridableTextField(label: 'Email', apiKey: 'email'),
          ),
        );

        host.setFieldErrors({
          'email': ['Email is not valid'],
        });
        await tester.pump();

        expect(find.text('Email is not valid'), findsOneWidget);
      },
    );

    testWidgets('no override checkbox at company level', (tester) async {
      final host = _FakeHost();
      final level = SettingsLevelController();

      await tester.pumpWidget(
        _wrap(
          host: host,
          level: level,
          child: const OverridableTextField(label: 'Name', apiKey: 'name'),
        ),
      );

      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('OverridableTextField — group level', () {
    testWidgets('renders the override checkbox', (tester) async {
      final host = _FakeHost();
      final level = SettingsLevelController()
        ..setLevel(SettingsLevel.group, targetId: 'g1');

      await tester.pumpWidget(
        _wrap(
          host: host,
          level: level,
          child: const OverridableTextField(label: 'VAT', apiKey: 'vat_number'),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('toggling the checkbox calls setOverride(enabled: true)', (
      tester,
    ) async {
      final host = _FakeHost();
      final level = SettingsLevelController()
        ..setLevel(SettingsLevel.group, targetId: 'g1');

      await tester.pumpWidget(
        _wrap(
          host: host,
          level: level,
          child: const OverridableTextField(label: 'VAT', apiKey: 'vat_number'),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(host.setOverrideCalls, 1);
      expect(host.lastOverrideEnabled, isTrue);
    });
  });
}
