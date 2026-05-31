import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/wysiwyg_canvas.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

import '../../../../../../_localization_helper.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  locale: const Locale('en'),
  theme: buildInTheme(InTheme.light),
  home: Scaffold(body: SizedBox(width: 1200, height: 900, child: child)),
);

void main() {
  late AppDatabase db;
  late DesignRepository repo;
  const companyId = 'co1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DesignRepository(db: db, api: _FakeDesignsApi());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 16 — grid show/hide', () {
    testWidgets('grid renders when showGrid is true', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      final notifier = ValueNotifier<bool>(true);
      addTearDown(notifier.dispose);
      await tester.pumpWidget(_wrap(
        WysiwygCanvas(vm: vm, showGrid: notifier),
      ));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('canvas-grid-guides')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('canvas-grid-guides')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('grid disappears when showGrid flips to false',
        (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      final notifier = ValueNotifier<bool>(true);
      addTearDown(notifier.dispose);
      await tester.pumpWidget(_wrap(
        WysiwygCanvas(vm: vm, showGrid: notifier),
      ));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('canvas-grid-guides')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      notifier.value = false;
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('canvas-grid-guides')),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('legacy callers without showGrid still see the grid',
        (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      await tester.pumpWidget(_wrap(WysiwygCanvas(vm: vm)));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('canvas-grid-guides')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });
}
