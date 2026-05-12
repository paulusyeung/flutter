import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/ui/features/settings/widgets/biometric_toggle_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../../_localization_helper.dart';
import '../../../../_support/fake_biometric_service.dart';

/// Minimal AuthRepository stand-in: only the bits the toggle tile reads
/// (session ValueListenable) and writes (setBiometricEnabled). Other members
/// throw — accidental reuse is loud.
class _FakeAuth implements AuthRepository {
  _FakeAuth(AuthSession initial) : _session = ValueNotifier(initial);

  final ValueNotifier<AuthSession?> _session;
  final List<bool> setCalls = [];

  @override
  ValueListenable<AuthSession?> get session => _session;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    setCalls.add(enabled);
    final s = _session.value;
    if (s == null) return;
    _session.value = s.copyWith(biometricEnabled: enabled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeServices implements Services {
  _FakeServices({required this.auth, required this.biometric});

  @override
  final AuthRepository auth;

  @override
  final BiometricService biometric;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

AuthSession _seedSession({bool biometricEnabled = false}) => AuthSession(
  baseUrl: 'https://test',
  isHosted: false,
  accountId: 'acct_1',
  companies: const [],
  currentCompanyId: '',
  biometricEnabled: biometricEnabled,
);

Widget _host({required Services services}) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  home: Provider<Services>.value(
    value: services,
    child: const Scaffold(body: BiometricToggleTile()),
  ),
);

void main() {
  testWidgets('hidden when biometric is not available', (tester) async {
    final biometric = FakeBiometricService()..available = false;
    final services = _FakeServices(
      auth: _FakeAuth(_seedSession()),
      biometric: biometric,
    );

    await tester.pumpWidget(_host(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('visible and OFF by default when available', (tester) async {
    final biometric = FakeBiometricService();
    final services = _FakeServices(
      auth: _FakeAuth(_seedSession()),
      biometric: biometric,
    );

    await tester.pumpWidget(_host(services: services));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
  });

  testWidgets('enable: prompts biometric, persists on success', (tester) async {
    final biometric = FakeBiometricService()..outcomes.add(true);
    final auth = _FakeAuth(_seedSession());
    final services = _FakeServices(auth: auth, biometric: biometric);

    await tester.pumpWidget(_host(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(biometric.reasons.length, 1);
    expect(auth.setCalls, [true]);
    expect(auth.session.value!.biometricEnabled, isTrue);
  });

  testWidgets('enable cancelled: does NOT persist', (tester) async {
    final biometric = FakeBiometricService()..outcomes.add(false);
    final auth = _FakeAuth(_seedSession());
    final services = _FakeServices(auth: auth, biometric: biometric);

    await tester.pumpWidget(_host(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(biometric.reasons.length, 1);
    expect(auth.setCalls, isEmpty, reason: 'cancelled prompt must not persist');
    expect(auth.session.value!.biometricEnabled, isFalse);
  });

  testWidgets('disable: no prompt, persists immediately', (tester) async {
    final biometric = FakeBiometricService();
    final auth = _FakeAuth(_seedSession(biometricEnabled: true));
    final services = _FakeServices(auth: auth, biometric: biometric);

    await tester.pumpWidget(_host(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      biometric.reasons,
      isEmpty,
      reason: 'disabling should not prompt for biometric',
    );
    expect(auth.setCalls, [false]);
    expect(auth.session.value!.biometricEnabled, isFalse);
  });
}
