import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/custom_field_row.dart';

import '../../../../_localization_helper.dart';

/// Minimal company-scoped [SettingsDraftHost] that just holds an in-memory
/// draft and applies `updateCompany` edits — enough to drive a [CustomFieldRow].
class _FakeHost extends SettingsDraftHost {
  _FakeHost(this._draft);
  Company _draft;

  @override
  Company? get draft => _draft;

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
  Map<String, List<String>> get fieldErrors => const {};
  @override
  Future<void> load() async {}
  @override
  void reset() {}
  @override
  Future<Object?> save() async => null;

  @override
  void updateCompany(Company Function(Company) edit) {
    _draft = edit(_draft);
    notifyListeners();
  }
}

Future<_FakeHost> _pumpRow(WidgetTester tester) async {
  final host = _FakeHost(const Company());
  await tester.pumpWidget(
    ChangeNotifierProvider<_FakeHost>.value(
      value: host,
      child: MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CustomFieldRow<_FakeHost>(prefix: 'client', slot: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets(
    'denies a pipe typed into the label so the value cannot corrupt',
    (tester) async {
      final host = await _pumpRow(tester);
      // '|' is the stored delimiter — typing it must be stripped at the input.
      await tester.enterText(find.byType(TextField).first, 'PO|x');
      await tester.pump();
      expect(host.draft!.customFields['client1'], 'POx|single_line_text');
    },
  );
}
