import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/bodies/custom_designs_body.dart';

import '../../../../_localization_helper.dart';

/// Custom designs are a Pro feature. These tests lock in the gating added for
/// launch: a free (hosted, unpaid) account sees the upgrade banner, cannot
/// reach "Edit a copy", and the "+ New design" button no longer opens the
/// create chooser — while a Pro account is unaffected. See `custom_designs_body.dart`.

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._session);
  final ValueNotifier<AuthSession?> _session;
  @override
  ValueListenable<AuthSession?> get session => _session;
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeDesignRepo implements DesignRepository {
  _FakeDesignRepo(this._designs);
  final List<Design> _designs;
  @override
  Stream<List<Design>> watchAll({required String companyId}) =>
      Stream.value(_designs);
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeServices implements Services {
  _FakeServices({required this.auth, required this.designs});
  @override
  final AuthRepository auth;
  @override
  final DesignRepository designs;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// A hosted, unpaid account is the only case that's actually gated — a
/// self-hosted (`isHosted: false`) account always has feature access.
AuthSession _session({required String plan, required bool isHosted}) =>
    AuthSession(
      baseUrl: 'https://example.test',
      isHosted: isHosted,
      accountId: 'acct',
      companies: [
        AuthCompany(
          id: 'co-A',
          name: 'Co A',
          displayName: 'Co A',
          permissions: '',
          isAdmin: true,
          isOwner: true,
        ),
      ],
      currentCompanyId: 'co-A',
      plan: plan,
    );

Design _customDesign() => Design(
  id: 'c1',
  name: 'My Design',
  isCustom: true,
  isActive: true,
  isTemplate: false,
  isFree: false,
  entities: const ['invoice'],
  template: const DesignTemplate(),
  updatedAt: DateTime.utc(2026),
  createdAt: DateTime.utc(2026),
  archivedAt: null,
  isDeleted: false,
);

Services _services({required bool pro, List<Design>? designs}) => _FakeServices(
  // Pro = self-hosted (always has access); free = hosted + empty plan.
  auth: _FakeAuth(
    ValueNotifier(
      pro
          ? _session(plan: 'pro', isHosted: false)
          : _session(plan: '', isHosted: true),
    ),
  ),
  designs: _FakeDesignRepo(designs ?? [_customDesign()]),
);

Widget _host(Services services, {Widget body = const CustomDesignsBody()}) =>
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Provider<Services>.value(
        value: services,
        child: Scaffold(body: body),
      ),
    );

void main() {
  testWidgets(
    'free account → upgrade banner shows and the tile title ellipsizes',
    (tester) async {
      await tester.pumpWidget(_host(_services(pro: false)));
      await tester.pumpAndSettle();

      // The PlanGateBanner renders its lock icon for a gated account.
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // 2a polish: the custom-design tile title is clipped to a single line.
      final title = tester.widget<Text>(find.text('My Design'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('pro account → no upgrade banner', (tester) async {
    await tester.pumpWidget(_host(_services(pro: true)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('My Design'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'free account → custom-row menu hides "Edit a copy" (export only)',
    (tester) async {
      await tester.pumpWidget(_host(_services(pro: false)));
      await tester.pumpAndSettle();

      // Only the custom row carries a menu (built-in catalog rows have no
      // loaded design, so they render no PopupMenuButton).
      final menu = find.byType(PopupMenuButton<String>);
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // "Edit a copy" (a create-a-new-design action) is gone; Export remains.
      expect(find.byType(PopupMenuItem<String>), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pro account → custom-row menu shows both "Edit a copy" and Export',
    (tester) async {
      await tester.pumpWidget(_host(_services(pro: true)));
      await tester.pumpAndSettle();

      final menu = find.byType(PopupMenuButton<String>);
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('pro account → "+ New design" opens the create chooser', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _services(pro: true),
        body: const Center(child: CustomDesignsNewDesignButton()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Pro users reach the create chooser (visual / HTML / import). A free
    // user instead routes to the upgrade flow — not exercised here because
    // that path leaves the screen for the store/portal.
    expect(find.byType(SimpleDialog), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
