import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';

import '../../../../_localization_helper.dart';

/// Minimal company-scope host (`draft != null` ⇒ `isCascadeScope == false`),
/// mirroring the one in overridable_number_field_test.dart.
class _FakeHost extends SettingsDraftHost {
  _FakeHost(this._settings);
  CompanySettings _settings;

  @override
  CompanySettings get settings => _settings;
  @override
  CompanySettings get draftSettings => _settings;
  @override
  Company? get draft => const Company();
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

class _Opt {
  const _Opt(this.id, this.name);
  final String id;
  final String name;
}

void main() {
  testWidgets('clearing at company scope emits the empty-string sentinel, '
      'not null (H4)', (tester) async {
    final host = _FakeHost(const CompanySettings());
    Object? captured = 'unset';
    var called = false;

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
              child: OverridableSearchableDropdownField<_Opt>(
                label: 'Currency',
                apiKey: 'currency_id',
                value: '1',
                items: const [_Opt('1', 'USD'), _Opt('2', 'EUR')],
                displayString: (o) => o.name,
                idOf: (o) => o.id,
                onChanged: (v) {
                  called = true;
                  captured = v;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drive the inner picker's clear (onChanged(null)) directly — at company
    // scope it must map to '' so the cleared key survives the
    // {...rawSettings, ...toJson()} merge instead of being omitted (and the old
    // value resurrected) by CompanySettingsApi's includeIfNull:false toJson.
    final inner = tester.widget<SearchableDropdownField<_Opt>>(
      find.byType(SearchableDropdownField<_Opt>),
    );
    inner.onChanged(null);

    expect(called, isTrue);
    expect(captured, '');
  });
}
