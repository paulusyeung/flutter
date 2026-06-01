import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BlockSpec _specByType(String type) =>
    kBlockLibrary.firstWhere((s) => s.type == type);

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

  group('selection / panel mode', () {
    test('starts unselected with Document Settings panel mode', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      expect(vm.selectedBlockId, isNull);
      expect(vm.panelMode, PropertyPanelMode.document);
    });

    test('addBlock selects the new block and switches to block mode', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      expect(vm.selectedBlockId, isNotNull);
      expect(vm.panelMode, PropertyPanelMode.block);
      expect(vm.selectedBlock?.type, 'logo');
    });

    test(
      'selectBlock(null) clears selection AND switches back to document mode',
      () {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_specByType('text'));
        expect(vm.panelMode, PropertyPanelMode.block);
        vm.selectBlock(null);
        expect(vm.selectedBlockId, isNull);
        expect(vm.panelMode, PropertyPanelMode.document);
      },
    );

    test('deleting the selected block clears the selection', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      final id = vm.selectedBlockId!;
      vm.deleteBlock(id);
      expect(vm.selectedBlockId, isNull);
      expect(vm.blocks, isEmpty);
    });

    test('deleting a NON-selected block keeps the current selection', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      final logoId = vm.selectedBlockId!;
      vm.addBlock(_specByType('text'));
      final textId = vm.selectedBlockId!;
      // Delete the unselected logo block.
      vm.deleteBlock(logoId);
      expect(vm.selectedBlockId, textId);
      expect(vm.blocks, hasLength(1));
    });
  });

  group('addBlockAt drop-coordinate placement', () {
    test('places the block at the requested grid coords when free', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlockAt(_specByType('logo'), 4, 3);
      final block = vm.blocks.single;
      expect(block.gridPosition.x, 4);
      expect(block.gridPosition.y, 3);
      expect(block.gridPosition.w, 4); // logo default
    });

    test('clamps x so the block fits within the 12-column grid', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      // text default width=6; x=10 would overflow → clamped to 12-6=6.
      vm.addBlockAt(_specByType('text'), 10, 0);
      expect(vm.blocks.single.gridPosition.x, 6);
    });

    test('pushes new block below an overlapping existing block', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      // text default 6×2 at (0,0).
      vm.addBlockAt(_specByType('text'), 0, 0);
      // Drop another text block at (0,0) — collides; should land at y=2.
      vm.addBlockAt(_specByType('text'), 0, 0);
      expect(vm.blocks, hasLength(2));
      expect(vm.blocks[0].gridPosition.y, 0);
      expect(vm.blocks[1].gridPosition.y, 2);
    });

    test('negative y is clamped to 0', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlockAt(_specByType('logo'), 0, -5);
      expect(vm.blocks.single.gridPosition.y, 0);
    });
  });

  group('duplicate / lock', () {
    test(
      'duplicateBlock creates a clone with a new id and same properties',
      () {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_specByType('text'));
        final src = vm.blocks.single;
        vm.duplicateBlock(src.id);
        expect(vm.blocks, hasLength(2));
        final clone = vm.blocks.last;
        expect(clone.id, isNot(src.id));
        expect(clone.id, startsWith('text-'));
        expect(clone.type, 'text');
        expect(clone.properties, src.properties);
        expect(vm.selectedBlockId, clone.id);
      },
    );

    test('duplicateBlock throws StateError for an unknown id (not silent)', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      expect(() => vm.duplicateBlock('nope'), throwsA(isA<StateError>()));
    });

    test('toggleLock flips locked', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      final id = vm.selectedBlockId!;
      expect(vm.blocks.single.locked, isFalse);
      vm.toggleLock(id);
      expect(vm.blocks.single.locked, isTrue);
      vm.toggleLock(id);
      expect(vm.blocks.single.locked, isFalse);
    });
  });

  group('DocumentSettings seeding from company.settings', () {
    test('uses CompanySettings when seeding a brand-new design', () {
      const cs = CompanySettingsApi(
        pageLayout: 'landscape',
        pageSize: 'Letter',
        fontSize: 14,
        primaryFont: 'Open Sans',
        secondaryFont: 'Lato',
        showPaidStamp: true,
        showShippingAddress: true,
        embedDocuments: true,
        hideEmptyColumnsOnPdf: true,
        pageNumbering: true,
      );
      final vm = WysiwygDesignViewModel(
        repo: repo,
        companyId: companyId,
        companySettings: cs,
      );
      final ds = vm.documentSettings;
      expect(ds.pageLayout, 'landscape');
      expect(ds.pageSize, 'Letter');
      expect(ds.globalFontSize, 14);
      expect(ds.primaryFont, 'Open Sans');
      expect(ds.secondaryFont, 'Lato');
      expect(ds.showPaidStamp, isTrue);
      expect(ds.showShippingAddress, isTrue);
      expect(ds.embedDocuments, isTrue);
      expect(ds.hideEmptyColumns, isTrue);
      expect(ds.pageNumbering, isTrue);
    });

    test(
      'falls back to React-parity defaults when CompanySettings is null',
      () {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        final ds = vm.documentSettings;
        expect(ds.pageLayout, 'portrait');
        expect(ds.pageSize, 'A4');
        expect(ds.globalFontSize, 16);
        expect(ds.primaryFont, 'Roboto');
      },
    );

    test('handles partially-set CompanySettings (nulls fall through)', () {
      const cs = CompanySettingsApi(pageLayout: 'landscape');
      final vm = WysiwygDesignViewModel(
        repo: repo,
        companyId: companyId,
        companySettings: cs,
      );
      final ds = vm.documentSettings;
      expect(ds.pageLayout, 'landscape'); // from company
      expect(ds.pageSize, 'A4'); // default
      expect(ds.globalFontSize, 16); // default
    });
  });

  group('arrow-key nudging (Step 5a — VM contract)', () {
    // The screen wires Shortcuts → _NudgeIntent / _ResizeNudgeIntent →
    // recordHistorySnapshot + updateBlock. These tests exercise the same
    // VM-side contract (snapshot + update) the intents drive.
    test('moveBlock by one cell records once and preserves selection', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      final p = vm.blocks.single.gridPosition;
      vm.recordHistorySnapshot();
      vm.updateBlock(
        vm.blocks.single.copyWith(
          gridPosition: GridPosition(x: p.x + 1, y: p.y, w: p.w, h: p.h),
        ),
      );
      expect(vm.blocks.single.gridPosition.x, p.x + 1);
      expect(vm.selectedBlockId, id);
      // Undo restores the pre-nudge state.
      vm.undo();
      expect(vm.blocks.single.gridPosition.x, p.x);
    });

    test('Shift+arrow resize clamps via block_sizing min/max', () {
      // text block default width is 6, min width is 2. A huge negative
      // shrink should clamp to the type minimum.
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final block = vm.blocks.single;
      // Simulate Shift+ArrowLeft 10 times: dw=-1 each, clamped at min.
      var current = block;
      for (var i = 0; i < 10; i++) {
        final p = current.gridPosition;
        vm.updateBlock(
          current.copyWith(
            gridPosition: GridPosition(
              x: p.x,
              y: p.y,
              w: (p.w - 1).clamp(2, 12), // text min=2
              h: p.h,
            ),
          ),
        );
        current = vm.blocks.single;
      }
      expect(
        vm.blocks.single.gridPosition.w,
        2,
        reason: 'text min width is 2 per block_sizing',
      );
    });
  });

  group('selection preservation across drag-time mutations (Step 4.6)', () {
    // Regression for the bug where `_replaceBlocks(next)` (with a default
    // null newSelectionId) silently cleared the selection on every call,
    // killing the resize gesture after one frame.
    test('updateBlock preserves selectedBlockId', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      final current = vm.blocks.single;
      vm.updateBlock(
        current.copyWith(
          gridPosition: const GridPosition(x: 0, y: 0, w: 6, h: 3),
        ),
      );
      expect(vm.selectedBlockId, id, reason: 'updateBlock must NOT deselect');
      expect(vm.panelMode, PropertyPanelMode.block);
    });

    test('moveBlock preserves selectedBlockId', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      vm.moveBlock(id, const GridPosition(x: 0, y: 5, w: 6, h: 2));
      expect(vm.selectedBlockId, id);
    });

    test('toggleLock preserves selectedBlockId', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      vm.toggleLock(id);
      expect(vm.selectedBlockId, id);
    });

    test('fixOverlaps preserves selectedBlockId', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      vm.fixOverlaps();
      expect(vm.selectedBlockId, id);
    });

    test(
      'repeated updateBlock (simulated resize drag) keeps selection alive',
      () {
        // The original bug: each updateBlock frame nulled the selection,
        // un-rendering the resize handles and killing the gesture after
        // one cell. Simulate a 10-frame drag and assert selection survives
        // every frame.
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_specByType('text'));
        final id = vm.selectedBlockId!;
        final current = vm.blocks.single;
        vm.recordHistorySnapshot();
        for (var w = 6; w <= 12; w++) {
          vm.updateBlock(
            current.copyWith(
              gridPosition: GridPosition(x: 0, y: 0, w: w, h: 2),
            ),
          );
          expect(vm.selectedBlockId, id, reason: 'lost selection at w=$w');
        }
        expect(vm.blocks.single.gridPosition.w, 12);
      },
    );

    test('deleteBlock on the selected block clears the selection', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final id = vm.selectedBlockId!;
      vm.deleteBlock(id);
      expect(vm.selectedBlockId, isNull);
      expect(vm.panelMode, PropertyPanelMode.document);
    });

    test('deleteBlock on a NON-selected block keeps the selection', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      vm.addBlock(_specByType('logo'));
      // 'logo' is the currently-selected (most recently added) block.
      final logoId = vm.selectedBlockId!;
      final textId = vm.blocks.firstWhere((b) => b.type == 'text').id;
      vm.deleteBlock(textId);
      expect(vm.selectedBlockId, logoId);
    });
  });

  group('undo / redo', () {
    test('add → undo restores the prior empty blocks list', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      expect(vm.canUndo, isFalse);
      vm.addBlock(_specByType('logo'));
      expect(vm.blocks, hasLength(1));
      expect(vm.canUndo, isTrue);
      vm.undo();
      expect(vm.blocks, isEmpty);
      expect(vm.canRedo, isTrue);
    });

    test('add → add → undo → undo unwinds both mutations', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      vm.addBlock(_specByType('text'));
      expect(vm.blocks, hasLength(2));
      vm.undo();
      expect(vm.blocks, hasLength(1));
      expect(vm.blocks.first.type, 'logo');
      vm.undo();
      expect(vm.blocks, isEmpty);
    });

    test('redo fast-forwards through an undone mutation', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      vm.undo();
      expect(vm.blocks, isEmpty);
      vm.redo();
      expect(vm.blocks, hasLength(1));
      expect(vm.canRedo, isFalse);
    });

    test('new structural mutation after undo wipes the redo tail', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      vm.undo();
      expect(vm.canRedo, isTrue);
      vm.addBlock(_specByType('text')); // branch — redo tail wiped
      expect(vm.canRedo, isFalse);
    });

    test('updateBlock does NOT snapshot (matches React)', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      // Sanity: addBlock recorded once.
      final initialUndoDepth = vm.canUndo;
      expect(initialUndoDepth, isTrue);
      // Property-panel-style edit.
      final current = vm.blocks.single;
      final tweaked = current.copyWith(
        properties: {...current.properties, 'content': 'hello'},
      );
      vm.updateBlock(tweaked);
      // Undoing should revert to the EMPTY list (before addBlock), not to
      // the pre-content state — there was no extra snapshot.
      vm.undo();
      expect(vm.blocks, isEmpty);
    });

    test(
      'delete / duplicate / move / toggleLock / fixOverlaps all snapshot',
      () {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_specByType('logo'));
        vm.undo();
        expect(vm.canUndo, isFalse);

        // Add two blocks for the rest of the test.
        vm.addBlock(_specByType('logo'));
        vm.addBlock(_specByType('text'));
        final logoId = vm.blocks.first.id;
        final textId = vm.blocks.last.id;

        vm.deleteBlock(textId);
        vm.undo();
        expect(vm.blocks.map((b) => b.id), contains(textId));

        vm.duplicateBlock(logoId);
        vm.undo();
        expect(vm.blocks, hasLength(2));

        vm.moveBlock(logoId, const GridPosition(x: 0, y: 10, w: 4, h: 4));
        vm.undo();
        expect(
          vm.blocks.firstWhere((b) => b.id == logoId).gridPosition.y,
          isNot(10),
        );

        vm.toggleLock(logoId);
        vm.undo();
        expect(vm.blocks.firstWhere((b) => b.id == logoId).locked, isFalse);

        vm.fixOverlaps();
        expect(vm.canUndo, isTrue);
      },
    );

    test('resetToEmpty clears the history', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      vm.addBlock(_specByType('text'));
      expect(vm.canUndo, isTrue);
      vm.resetToEmpty();
      expect(vm.canUndo, isFalse);
      expect(vm.canRedo, isFalse);
    });
  });

  group('discard / reset', () {
    test('resetToEmpty clears blocks, selection, and re-seeds settings', () {
      const cs = CompanySettingsApi(pageSize: 'Letter');
      final vm = WysiwygDesignViewModel(
        repo: repo,
        companyId: companyId,
        companySettings: cs,
      );
      vm.addBlock(_specByType('logo'));
      vm.setName('Drafty');
      expect(vm.blocks, hasLength(1));
      expect(vm.isDirty, isTrue);
      vm.resetToEmpty(cs);
      expect(vm.blocks, isEmpty);
      expect(vm.selectedBlockId, isNull);
      expect(vm.draft.name, isEmpty);
      // Seed survived through the reset.
      expect(vm.documentSettings.pageSize, 'Letter');
    });
  });

  group('Phase 8k — importFromJson', () {
    test('round-trips a Design through export + import', () {
      // Build a non-trivial draft, export it, then import into a fresh
      // VM and assert the blocks + documentSettings come back intact.
      final source = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      source.addBlock(_specByType('logo'));
      source.addBlock(_specByType('total'));
      source.setDocumentSettings(
        source.documentSettings.copyWith(pageSize: 'Letter'),
      );
      final exported = source.draft.toApiJson(preserveTempId: false);
      final raw = const JsonEncoder().convert(exported);

      final target = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      final err = target.importFromJson(raw);
      expect(err, isNull);
      expect(target.blocks, hasLength(2));
      expect(target.blocks.map((b) => b.type).toList(), ['logo', 'total']);
      expect(target.documentSettings.pageSize, 'Letter');
    });

    test('returns "invalid_json" on malformed input', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      expect(vm.importFromJson('not json at all'), 'invalid_json');
      expect(vm.importFromJson('"just a string"'), 'invalid_json');
      expect(vm.importFromJson('[1, 2, 3]'), 'invalid_json');
    });

    test('clears selection + history on successful import', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('logo'));
      expect(vm.selectedBlockId, isNotNull);
      expect(vm.canUndo, isTrue);
      // Fresh import from a different design.
      final other = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      other.addBlock(_specByType('text'));
      final raw = const JsonEncoder().convert(
        other.draft.toApiJson(preserveTempId: false),
      );
      final err = vm.importFromJson(raw);
      expect(err, isNull);
      expect(vm.selectedBlockId, isNull);
      expect(vm.canUndo, isFalse);
      expect(vm.blocks.single.type, 'text');
    });
  });

  group('Phase 15d — performSave → repo round-trip', () {
    test(
      'create then watchById returns the same blocks + documentSettings',
      () async {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        // Build a non-trivial draft covering every important corner of the
        // schema: blocks list, GridPosition, properties (incl. Phase 8j
        // keepTogether), and DocumentSettings.
        vm.addBlock(_specByType('logo'));
        vm.addBlock(_specByType('total'));
        // Flip the keepTogether flag on the total block we just added.
        final totalBlock = vm.blocks.last;
        vm.updateBlock(
          totalBlock.copyWith(
            properties: {
              ...totalBlock.properties,
              'keepTogether': true,
              'align': 'right',
            },
          ),
        );
        vm.setDocumentSettings(
          vm.documentSettings.copyWith(
            pageSize: 'Letter',
            embedDocuments: true,
            hideEmptyColumns: true,
          ),
        );
        vm.setName('Round-trip test');

        // Save (create branch — vm.isCreate is true; this lands a `tmp_…`
        // row in Drift plus an outbox create row).
        final saved = await vm.performSave();
        expect(saved.entity.id, isNotEmpty);

        // Read back via the same repo. Use `watchAll` since the
        // create-path id is tmp_; we don't have a real server id yet.
        final all = await repo.watchAll(companyId: companyId).first;
        final fresh = all.firstWhere((d) => d.name == 'Round-trip test');

        // Blocks survived.
        expect(fresh.template.blocks, hasLength(2));
        expect(fresh.template.blocks.map((b) => b.type).toList(), [
          'logo',
          'total',
        ]);

        // The Phase 8j keepTogether boolean made it through the mapper
        // → Drift → row-rebuild cycle.
        final totalAfter = fresh.template.blocks.firstWhere(
          (b) => b.type == 'total',
        );
        expect(totalAfter.properties['keepTogether'], isTrue);
        expect(totalAfter.properties['align'], 'right');

        // GridPosition survived intact.
        expect(totalAfter.gridPosition.w, greaterThan(0));
        expect(totalAfter.gridPosition.h, greaterThan(0));

        // DocumentSettings round-tripped including the Phase 9c/9d flags.
        expect(fresh.template.documentSettings?.pageSize, 'Letter');
        expect(fresh.template.documentSettings?.embedDocuments, isTrue);
        expect(fresh.template.documentSettings?.hideEmptyColumns, isTrue);
      },
    );
  });
}
