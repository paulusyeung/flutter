import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/payment_link_repository.dart';
import 'package:admin/data/services/subscriptions_api.dart';
import 'package:admin/ui/features/payment_links/view_models/payment_link_edit_view_model.dart';
import 'package:admin/ui/features/payment_links/widgets/edit/payment_link_settings_tab.dart';
import 'package:drift/native.dart';

import '../../../_localization_helper.dart';

/// Regression coverage for the pre-launch Payment Links review:
///  * the Auto Bill dropdown rendered "Off" twice (the empty option was
///    mislabeled with the `off` key) — it must now appear once;
///  * the editable Price field was removed (neither React nor admin-portal
///    exposes it) — "Price" survives only as the section title.
class _FakeSubscriptionsApi implements SubscriptionsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, PaymentLinkEditViewModel vm) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(body: PaymentLinkSettingsTab(vm: vm)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  PaymentLinkEditViewModel makeVm() => PaymentLinkEditViewModel(
    repo: PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi()),
    companyId: 'co',
  );

  testWidgets(
    'Auto Bill dropdown renders each option once — no duplicate "Off"',
    (tester) async {
      await _pump(tester, makeVm());

      // Tap the dropdown field itself — tapping the floating label text can
      // land outside the gesture region.
      await tester.tap(
        find.ancestor(
          of: find.text('Auto Bill'),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await tester.pumpAndSettle();

      // The empty option is now blank, so "Off" comes only from the explicit
      // 'off' entry (was duplicated before the fix).
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Always'), findsOneWidget);
      expect(find.text('Opt-Out'), findsOneWidget);
      expect(find.text('Opt-In'), findsOneWidget);
    },
  );

  testWidgets('Price input field is removed (only the section title remains)', (
    tester,
  ) async {
    await _pump(tester, makeVm());

    // "Price" survives only as the FormSection title; the promo fields stay.
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Promo code'), findsOneWidget);
  });
}
