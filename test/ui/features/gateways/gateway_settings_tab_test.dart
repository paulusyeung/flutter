import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/models/value/gateway.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';
import 'package:admin/ui/features/gateways/widgets/edit/gateway_settings_tab.dart';

import '../../../_localization_helper.dart';

/// GatewaySettingsTab only reads `Services.statics`; everything else throws so
/// an incidental dependency surfaces loudly instead of silently passing.
class _FakeServices implements Services {
  _FakeServices(this.statics);
  @override
  final StaticsRepository statics;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeStaticsService implements StaticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// The edit VM stores the repo but never calls it during render, so a
/// noSuchMethod stand-in is enough to construct the tab.
class _FakeGatewayRepo implements CompanyGatewayRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Gateway _gatewayWithTokenBilling() => Gateway(
  id: 'k_test',
  name: 'Test Gateway',
  fields: '{}',
  defaultGatewayTypeId: '1',
  sortOrder: 0,
  isOffsite: false,
  isVisible: true,
  siteUrl: '',
  options: const {
    '1': GatewayOptions(supportTokenBilling: true, supportRefunds: false),
  },
);

void main() {
  late AppDatabase db;
  late StaticsRepository statics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    statics = StaticsRepository(db: db, service: _FakeStaticsService());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'renders without asserting when token_billing is outside the known options',
    (tester) async {
      // Seed the draft directly (bypassing fromApi) with a value outside the
      // four auto-bill options — this exercises the *widget-level* guard on
      // the dropdown. The unguarded code tripped Flutter's "exactly one item"
      // assertion here.
      final vm = CompanyGatewayEditViewModel(
        repo: _FakeGatewayRepo(),
        companyId: 'co-1',
        existing: const CompanyGateway(
          id: 'g1',
          gatewayKey: 'k_test',
          tokenBilling: 'opt_out',
          feesAndLimits: {'1': FeesAndLimits(isEnabled: true)},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildInTheme(InTheme.light),
          localizationsDelegates: kTestLocalizationsDelegates,
          supportedLocales: kTestSupportedLocales,
          home: Provider<Services>.value(
            value: _FakeServices(statics),
            child: Scaffold(
              body: GatewaySettingsTab(
                vm: vm,
                gateway: _gatewayWithTokenBilling(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    },
  );

  testWidgets('does not render card-brand checkboxes (removed for parity)', (
    tester,
  ) async {
    // Credit-card type ('1') enabled — this is exactly what used to surface the
    // Visa/Mastercard/… brand checkboxes. They were removed (React +
    // admin-portal omit them), so the tab should now contain no checkboxes.
    final vm = CompanyGatewayEditViewModel(
      repo: _FakeGatewayRepo(),
      companyId: 'co-1',
      existing: const CompanyGateway(
        id: 'g1',
        gatewayKey: 'k_test',
        tokenBilling: 'always',
        feesAndLimits: {'1': FeesAndLimits(isEnabled: true)},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Provider<Services>.value(
          value: _FakeServices(statics),
          child: Scaffold(
            body: GatewaySettingsTab(
              vm: vm,
              gateway: _gatewayWithTokenBilling(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CheckboxListTile), findsNothing);
  });
}
