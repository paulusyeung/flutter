// Pins the Referral Program screen's UX-polish behavior: the hosted gate, the
// value-prop copy, the copyable URL row, and the per-plan stats strip. The
// highest-value guard here is the FIXED tier order (free → pro → enterprise,
// default 0) — the screen must NOT render in raw `referralMeta` map order,
// which historically arrived alphabetically (enterprise first).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/referral_program_screen.dart';

import '../../../../../../_localization_helper.dart';

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
  _FakeServices({required this.auth});
  @override
  final AuthRepository auth;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

AuthSession _session({
  required bool isHosted,
  String code = '',
  Map<String, int> meta = const <String, int>{},
}) => AuthSession(
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
  referralCode: code,
  referralMeta: meta,
);

Services _services(AuthSession session) =>
    _FakeServices(auth: _FakeAuth(ValueNotifier(session)));

Widget _host(Services services) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: Provider<Services>.value(
    value: services,
    child: const Scaffold(body: AccountManagementReferralProgramScreen()),
  ),
);

void main() {
  testWidgets(
    'self-hosted → explanatory empty state with a Learn more action',
    (tester) async {
      await tester.pumpWidget(_host(_services(_session(isHosted: false))));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text(
          'The referral program is only available on the '
          'hosted Invoice Ninja platform.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Learn more'), findsOneWidget);
    },
  );

  testWidgets('hosted + no referrals → all three tiers render at 0, with the '
      'value-prop copy', (tester) async {
    await tester.pumpWidget(_host(_services(_session(isHosted: true))));
    await tester.pumpAndSettle();

    expect(find.text('Earn money by sharing our app online'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Enterprise'), findsOneWidget);
    // Always-show defaulting to 0 (not hidden when empty).
    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('hosted → tiles render in fixed free→pro→enterprise order '
      'regardless of server map order, with correct counts', (tester) async {
    // Narrow surface → tiles stack vertically, so dy ordering is deterministic.
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Deliberately out of order (alphabetical, as the server sends it).
    await tester.pumpWidget(
      _host(
        _services(
          _session(
            isHosted: true,
            meta: const {'enterprise': 1, 'free': 12, 'pro': 3},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double labelY(String s) => tester.getTopLeft(find.text(s)).dy;
    double countY(String s) => tester.getTopLeft(find.text(s)).dy;

    // Labels in canonical order.
    expect(labelY('Free') < labelY('Pro'), isTrue);
    expect(labelY('Pro') < labelY('Enterprise'), isTrue);

    // Counts map to the right tier: Free=12 (top), Pro=3, Enterprise=1 (bottom).
    expect(countY('12') < countY('3'), isTrue);
    expect(countY('3') < countY('1'), isTrue);
  });

  testWidgets(
    'hosted → an unknown server tier is appended after the core three',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(
          _services(
            _session(
              isHosted: true,
              meta: const {'free': 1, 'pro': 1, 'enterprise': 1, 'galaxy': 7},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unknown key has no translation → raw key shown, and its count renders.
      expect(find.text('galaxy'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      // Appended below the canonical Enterprise tile.
      final enterpriseY = tester.getTopLeft(find.text('Enterprise')).dy;
      final galaxyY = tester.getTopLeft(find.text('galaxy')).dy;
      expect(galaxyY > enterpriseY, isTrue);
    },
  );

  testWidgets('hosted → URL row wires the referral URL with copy + open '
      'affordances', (tester) async {
    // The screen's job is wiring the right URL into the shared PortalUrlDisplay
    // (copy + open behaviour is that widget's own concern). Reading the
    // clipboard back here is intentionally avoided: Clipboard.getData never
    // completes in the fake-async test zone (platform-channel replies land in
    // the real zone), which hangs the test.
    const code = 'ABC123';

    await tester.pumpWidget(
      _host(_services(_session(isHosted: true, code: code))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('rc=$code'), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });
}
