import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/localization/custom_labels_screen.dart';

import '../../../../../../_localization_helper.dart';

/// Minimal cascade host with empty translations — the Custom Labels body then
/// renders just the "Add" row + empty state, which is all this test needs.
class _StubHost extends SettingsDraftHost {
  @override
  Map<String, List<String>> get fieldErrors => const {};
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

/// The body stores `context.read<Services>()` but only calls into it on a
/// button tap (the country dialog), never during render — so a throwing fake
/// is fine for layout tests.
class _FakeServices implements Services {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _host() => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: MultiProvider(
    providers: [
      Provider<Services>.value(value: _FakeServices()),
      ChangeNotifierProvider<SettingsDraftHost>.value(value: _StubHost()),
    ],
    child: const Scaffold(body: LocalizationCustomLabelsBody()),
  ),
);

void main() {
  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
  }

  testWidgets('wide: Add row shows full icon+label buttons', (tester) async {
    await pumpAt(tester, 1200);
    expect(tester.takeException(), isNull);
    expect(find.text('Add Custom'), findsOneWidget);
    expect(find.text('Add Country'), findsOneWidget);
  });

  testWidgets('narrow: Add row collapses to icon-only, dropdown stays usable', (
    tester,
  ) async {
    await pumpAt(tester, 360);
    // Below the wide breakpoint the two actions collapse to icons (labels move
    // to tooltips) so the dropdown keeps a usable width and long localized
    // labels can't overflow the row.
    expect(tester.takeException(), isNull);
    expect(find.text('Add Custom'), findsNothing);
    expect(find.text('Add Country'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.public_outlined), findsOneWidget);
    // Regression guard: with the old always-icon+label layout the Expanded
    // dropdown was squeezed to a ~10px sliver here. Icon-only buttons (~48px
    // each) leave it ~176px.
    expect(
      tester.getSize(find.byType(SearchableDropdownField<String>)).width,
      greaterThan(120),
    );
  });
}
