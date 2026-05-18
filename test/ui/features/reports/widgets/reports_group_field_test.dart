import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';
import 'package:admin/ui/features/reports/widgets/reports_body.dart';

import '../../../../_localization_helper.dart';

class _FakeReportsRepo implements ReportsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NullStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch({
    bool includeStatic = true,
    bool? includeData,
  }) async =>
      const <String, dynamic>{};

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeAuth implements AuthRepository {
  final ValueNotifier<AuthSession?> _session = ValueNotifier(null);
  @override
  ValueListenable<AuthSession?> get session => _session;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeServices implements Services {
  _FakeServices(this.auth);
  @override
  final AuthRepository auth;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Reports settings panel builds without crashing when a group is set '
    'but no preview has run (regression: GroupBy dropdown assertion)',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final statics = StaticsRepository(db: db, service: _NullStaticsService());

      // No navStateDao → no persistence Timer. setReport + setGroup put the
      // VM in the exact state hydration produces on a cold restart: a group
      // selected with `run.preview == null`. Before the fix this tripped
      // DropdownButtonFormField's "exactly one matching item" assertion
      // when the (now always-rendered, disabled) GroupBy field built with a
      // group id that isn't among its items (no preview → no columns).
      final vm = ReportsViewModel(repo: _FakeReportsRepo(), statics: statics);
      vm.setReport('contact'); // minimal filter fields, no entity streams
      vm.setGroup('contact.created_at');
      expect(vm.group, 'contact.created_at');
      expect(vm.run.preview, isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildInTheme(InTheme.light),
          localizationsDelegates: kTestLocalizationsDelegates,
          supportedLocales: kTestSupportedLocales,
          home: MultiProvider(
            providers: [
              Provider<Services>.value(value: _FakeServices(_FakeAuth())),
              ChangeNotifierProvider<ReportsViewModel>.value(value: vm),
            ],
            child: const Scaffold(body: ReportsBody(formatter: null)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // GroupBy fell back to the "No grouping" item (disabled, no preview).
      expect(find.text('No grouping'), findsOneWidget);
    },
  );
}
