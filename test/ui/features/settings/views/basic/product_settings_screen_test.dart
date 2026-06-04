import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/basic/product_settings_screen.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

import '../../../../../_localization_helper.dart';

/// Stand-in [CompanyRepository] that emits a single [Company] on
/// `watchCompany` (mirrors the helper in `generated_numbers_shell_test.dart`).
class _StubCompanyRepo extends CompanyRepository {
  _StubCompanyRepo({
    required super.db,
    required super.api,
    required this.company,
  });

  final Company company;
  final _controllers = <String, StreamController<Company?>>{};

  @override
  Stream<Company?> watchCompany(String companyId) {
    final c = _controllers.putIfAbsent(
      companyId,
      StreamController<Company?>.broadcast,
    );
    Future.microtask(() {
      if (!c.isClosed) c.add(company);
    });
    return c.stream;
  }

  @override
  Future<void> refresh(String companyId) async {}
}

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._session);
  final ValueNotifier<AuthSession?> _session;
  @override
  ValueListenable<AuthSession?> get session => _session;
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeServices implements Services {
  _FakeServices({
    required this.auth,
    required this.company,
    required this.clients,
    required this.db,
    required this.settingsLevel,
    required this.unsavedChangesGuard,
  });
  @override
  final AuthRepository auth;
  @override
  final CompanyRepository company;
  @override
  final ClientRepository clients;
  @override
  final AppDatabase db;
  @override
  final SettingsLevelController settingsLevel;
  @override
  final UnsavedChangesGuard unsavedChangesGuard;

  // Product Settings never calls `formatterFor` (no money/date fields), but
  // keep the stub so an incidental call surfaces the production failure path
  // rather than a missing-stub crash.
  @override
  Future<Formatter> formatterFor(String companyId) =>
      Future.error(StateError('statics not stubbed in this test'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

AuthSession _session() => const AuthSession(
  baseUrl: 'https://example.test',
  isHosted: false,
  accountId: 'acct',
  companies: [],
  currentCompanyId: 'co-A',
  plan: 'pro',
);

Widget _host(Services services) {
  final router = GoRouter(
    initialLocation: '/settings/product_settings',
    routes: [
      GoRoute(
        path: '/settings/product_settings',
        builder: (_, _) => const ProductSettingsScreen(),
      ),
    ],
  );
  return MaterialApp.router(
    theme: buildInTheme(InTheme.light),
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    routerConfig: router,
    builder: (_, child) => MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider<SettingsLevelController>.value(
          value: services.settingsLevel,
        ),
      ],
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late ClientRepository clientRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clientRepo = ClientRepository(db: db, api: _FakeClientsApi());
  });

  tearDown(() async {
    await db.close();
  });

  Services makeServices(Company company) {
    return _FakeServices(
      auth: _FakeAuth(ValueNotifier(_session())),
      company: _StubCompanyRepo(
        db: db,
        api: _FakeCompaniesApi(),
        company: company,
      ),
      clients: clientRepo,
      db: db,
      settingsLevel: SettingsLevelController(),
      unsavedChangesGuard: UnsavedChangesGuard(),
    );
  }

  // Tall viewport so every card renders (SettingsFormShell's ListView builds
  // lazily — a 600px-tall default would leave the bottom card unrealized and
  // break the count assertions). `width` exercises the responsive breakpoint
  // (<600 = narrow / mobile).
  Future<void> pumpScreen(
    WidgetTester tester,
    Company company, {
    double width = 800,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(makeServices(company)));
    await tester.pump(); // drain the watchCompany microtask
    await tester.pumpAndSettle();
  }

  testWidgets('renders three cards and all 10 toggles; conditional fields '
      'hidden by default', (tester) async {
    await pumpScreen(tester, const Company(id: 'co-A'));

    // Three title-less grouping cards (Inventory / Display / Behavior).
    expect(find.byType(FormSection), findsNWidgets(3));
    // Ten always-visible toggles.
    expect(find.byType(SwitchListTile), findsNWidgets(10));

    // A representative label from each card renders.
    expect(find.text('Track Inventory'), findsOneWidget); // Inventory
    expect(find.text('Show Product Discount'), findsOneWidget); // Display
    expect(find.text('Convert Products'), findsOneWidget); // Behavior

    // Conditional children hidden while their parent toggle is off, and there
    // is no dropdown anywhere on the screen (convert-to is a radio now).
    expect(
      find.widgetWithText(TextField, 'Notification Threshold'),
      findsNothing,
    );
    expect(find.byType(RadioListTile<bool>), findsNothing);
    expect(find.byType(DropdownButtonFormField<bool>), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('toggling Stock Notifications reveals and hides the threshold '
      'field', (tester) async {
    await pumpScreen(tester, const Company(id: 'co-A'));
    expect(
      find.widgetWithText(TextField, 'Notification Threshold'),
      findsNothing,
    );

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Stock Notifications'),
    );
    await tester.pumpAndSettle();
    final threshold = find.widgetWithText(TextField, 'Notification Threshold');
    expect(threshold, findsOneWidget);

    // Single-line field wires Enter-to-save (textInputAction.done + onSubmitted).
    final field = tester.widget<TextField>(threshold);
    expect(field.textInputAction, TextInputAction.done);
    expect(field.onSubmitted, isNotNull);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Stock Notifications'),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'Notification Threshold'),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('toggling Convert Products reveals a radio group (not a '
      'dropdown) and selecting an option updates the group', (tester) async {
    await pumpScreen(tester, const Company(id: 'co-A'));
    expect(find.byType(RadioListTile<bool>), findsNothing);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Convert Products'));
    await tester.pumpAndSettle();

    // Two radio options, both visible; no dropdown.
    expect(find.byType(RadioListTile<bool>), findsNWidgets(2));
    expect(find.text('Client Currency'), findsOneWidget);
    expect(find.text('Company Currency'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<bool>), findsNothing);

    // Default convert_rate_to_client is false → Company Currency selected.
    RadioGroup<bool> group() =>
        tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>));
    expect(group().groupValue, isFalse);

    // Selecting Client Currency flows through the VM and updates the group.
    await tester.tap(
      find.widgetWithText(RadioListTile<bool>, 'Client Currency'),
    );
    await tester.pumpAndSettle();
    expect(group().groupValue, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mobile width (~390px): no overflow with every field visible', (
    tester,
  ) async {
    // Both conditional children visible so the full field set is laid out.
    await pumpScreen(
      tester,
      const Company(id: 'co-A', stockNotification: true, convertProducts: true),
      width: 390,
    );

    expect(find.byType(FormSection), findsNWidgets(3));
    expect(
      find.widgetWithText(TextField, 'Notification Threshold'),
      findsOneWidget,
    );
    expect(find.byType(RadioListTile<bool>), findsNWidgets(2));

    // No RenderFlex overflow (or any other layout exception) at narrow width.
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
