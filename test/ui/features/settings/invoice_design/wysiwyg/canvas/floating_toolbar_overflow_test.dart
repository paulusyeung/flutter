import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/wysiwyg_canvas.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

import '../../../../../../_localization_helper.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BlockSpec _specByType(String type) =>
    kBlockLibrary.firstWhere((s) => s.type == type);

Widget _wrap(WysiwygDesignViewModel vm) => MaterialApp(
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      locale: const Locale('en'),
      theme: buildInTheme(InTheme.light),
      home: Scaffold(body: WysiwygCanvas(vm: vm)),
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

  // Regression for the diagnostics-log error "A RenderFlex overflowed by 8.5
  // pixels on the right", which recurred on the WYSIWYG designer (including
  // the most recent session). Selecting / rendering a narrow block hit two
  // separate fixed-width Rows in the canvas:
  //   - text w=2/w=3: the floating selection toolbar (duplicate / lock /
  //     delete) is ~92px wide — wider than the block — and used to be
  //     constrained to `width: blockWidth` (this was the 8.5px overflow at
  //     w=3 on the real canvas).
  //   - spacer w=1: the block header strip's leading icon + gap (16px) is
  //     wider than a 1-column sliver.
  // Both Rows now size to fit / drop content, so no block width overflows.
  const cases = <({String type, int w})>[
    (type: 'text', w: 2),
    (type: 'text', w: 3),
    (type: 'spacer', w: 1),
  ];

  for (final c in cases) {
    testWidgets(
      'narrow ${c.type} block (w=${c.w}) renders without RenderFlex overflow',
      (tester) async {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_specByType(c.type));
        final block = vm.blocks.single;
        vm.updateBlock(
          block.copyWith(
            gridPosition: GridPosition(x: 0, y: 0, w: c.w, h: 2),
          ),
        );
        // addBlock selects the new block; updateBlock keeps the selection,
        // so both the header strip and the floating toolbar render for it.
        expect(vm.selectedBlockId, block.id);

        await tester.pumpWidget(_wrap(vm));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a narrow (${c.type} w=${c.w}) block must not '
              'RenderFlex-overflow on the canvas',
        );
      },
    );
  }

  testWidgets(
    'Phase 20a: narrow block at x=0 keeps the floating toolbar inside '
    'the canvas left edge (no negative-left paint)',
    (tester) async {
      // Fixed surface so cellWidth math is deterministic. 800 / 12 ≈ 66 px
      // per cell — a 1-cell block at x=0 yields blockRight ≈ 66, which
      // before the clamp would push the ~96 px toolbar's left edge to
      // roughly -30 px (off-canvas left).
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final block = vm.blocks.single;
      vm.updateBlock(
        block.copyWith(
          gridPosition: const GridPosition(x: 0, y: 0, w: 1, h: 2),
        ),
      );
      expect(vm.selectedBlockId, block.id);

      await tester.pumpWidget(_wrap(vm));
      await tester.pump();

      // No layout exception fired.
      expect(tester.takeException(), isNull);

      // The Material (the toolbar wrapper) should be fully inside the
      // canvas's left edge. Find the Material with the accent color
      // (the floating toolbar) and check its on-screen bounds.
      final accentMaterial = find.byWidgetPredicate(
        (w) {
          if (w is! Material) return false;
          // The toolbar uses tokens.accent; other Materials in the canvas
          // are surface-coloured. Heuristic: pick the smallest one near
          // the top of the canvas.
          return w.elevation == 2;
        },
      );
      expect(accentMaterial, findsOneWidget,
          reason: 'expected exactly one floating toolbar Material');
      final rect = tester.getRect(accentMaterial);
      expect(rect.left, greaterThanOrEqualTo(0),
          reason: 'toolbar left edge must stay inside the canvas');
    },
  );
}
