import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/data/db/app_database.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('diagnostics_log_test_');
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<DiagnosticsLog> openLog({int rotateThresholdBytes = 512 * 1024}) {
    return DiagnosticsLog.open(
      directoryOverride: tmp,
      rotateThresholdBytes: rotateThresholdBytes,
    );
  }

  test('creates the file at the resolved path with a SESSION banner', () async {
    final diag = await openLog();
    addTearDown(diag.close);
    final file = File(diag.path);
    expect(await file.exists(), isTrue);
    final body = await file.readAsString();
    expect(body, contains('=== SESSION '));
  });

  test('recordError appends an ERROR line and indented stack', () async {
    final diag = await openLog();
    addTearDown(diag.close);
    diag.recordError(
      StateError('boom'),
      StackTrace.fromString('#0 frameA\n#1 frameB'),
      context: 'unitTest',
    );
    await diag.flush();
    final body = await File(diag.path).readAsString();
    expect(body, contains('ERROR '));
    expect(body, contains('[unitTest]'));
    expect(body, contains('Bad state: boom'));
    expect(body, contains('  #0 frameA'));
    expect(body, contains('  #1 frameB'));
  });

  test('recordLog includes level, logger name, and redacts secrets', () async {
    final diag = await openLog();
    addTearDown(diag.close);
    final record = LogRecord(
      Level.WARNING,
      'oops "password":"hunter2" trailing',
      'unit.test.logger',
    );
    diag.recordLog(record);
    await diag.flush();
    final body = await File(diag.path).readAsString();
    expect(body, contains('WARNING'));
    expect(body, contains('[unit.test.logger]'));
    expect(body, contains('"password":"<redacted>"'));
    expect(body, isNot(contains('hunter2')));
  });

  test(
    'collapses a storm of identical errors into one entry + tally',
    () async {
      final diag = await openLog();
      addTearDown(diag.close);
      for (var i = 0; i < 5; i++) {
        diag.recordError(
          StateError('same'),
          StackTrace.fromString('#0 frameA'),
          context: 'storm',
        );
      }
      await diag.flush(); // flushing emits the trailing repeat tally
      final body = await File(diag.path).readAsString();
      // The head is written exactly once; the other four are collapsed.
      expect('Bad state: same'.allMatches(body).length, 1);
      expect(body, contains('repeated 4 more time(s)'));
    },
  );

  test('a different error flushes the pending repeat tally', () async {
    final diag = await openLog();
    addTearDown(diag.close);
    diag.recordError(StateError('a'), null, context: 'c');
    diag.recordError(StateError('a'), null, context: 'c'); // repeat
    diag.recordError(StateError('b'), null, context: 'c'); // distinct → flush
    await diag.flush();
    final body = await File(diag.path).readAsString();
    expect(body, contains('repeated 1 more time(s)'));
    expect(body, contains('Bad state: b'));
  });

  test(
    'recordFlutterError logs the relevant error-causing widget hint',
    () async {
      final diag = await openLog();
      addTearDown(diag.close);
      diag.recordFlutterError(
        FlutterErrorDetails(
          exception: StateError('layout boom'),
          stack: StackTrace.fromString('#0 frameX'),
          library: 'rendering library',
          context: ErrorDescription('during performLayout()'),
          informationCollector: () => [
            ErrorDescription(
              'The relevant error-causing widget was: FilledButton',
            ),
            DiagnosticsProperty<String>(
              'created by',
              'package:admin/ui/core/list/entity_sort_filter_sheet.dart:97',
            ),
          ],
        ),
      );
      await diag.flush();
      final body = await File(diag.path).readAsString();
      expect(body, contains('Bad state: layout boom'));
      expect(body, contains('[during performLayout()]'));
      expect(
        body,
        contains('The relevant error-causing widget was: FilledButton'),
      );
      expect(
        body,
        contains('package:admin/ui/core/list/entity_sort_filter_sheet.dart:97'),
      );
    },
  );

  test('rotates to .1 backup when threshold exceeded', () async {
    // Tiny threshold so a handful of records trigger rotation.
    final diag = await openLog(rotateThresholdBytes: 256);
    addTearDown(diag.close);
    final filler = 'x' * 80;
    for (var i = 0; i < 20; i++) {
      diag.recordError(filler, null, context: 'fill$i');
    }
    // Give rotation's microtask a chance to land.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await diag.flush();
    final backup = File('${diag.path}.1');
    expect(await backup.exists(), isTrue);
  });

  test(
    'rotation pre-flight at open: existing oversized file is moved aside',
    () async {
      final filePath = '${tmp.path}/claude-diagnostics.log';
      await File(filePath).writeAsString('x' * 1024);
      final diag = await openLog(rotateThresholdBytes: 256);
      addTearDown(diag.close);
      final backup = File('$filePath.1');
      expect(await backup.exists(), isTrue);
      expect(await backup.length(), 1024);
      // Fresh file should now start with the session banner only.
      expect(await File(filePath).readAsString(), contains('=== SESSION '));
    },
  );

  test('appendOutboxSnapshot writes only stale rows for the company', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final parkedAt = now + Duration(days: 365).inMilliseconds;
    final justSoon = now + Duration(hours: 1).inMilliseconds; // not stale

    Future<int> enqueue({
      required String state,
      required int nextAttempt,
      String companyId = 'co',
      String entityId = 'e',
      String error = 'e',
      int? statusCode,
    }) {
      return db.outboxDao.enqueue(
        OutboxCompanion.insert(
          companyId: companyId,
          entityType: 'client',
          entityId: entityId,
          mutationKind: 'update',
          payload: jsonEncode({'x': 1}),
          idempotencyKey: 'k$entityId',
          nextAttemptAt: nextAttempt,
          createdAt: now,
          state: Value(state),
          lastError: Value(error),
          lastStatusCode: Value(statusCode),
        ),
      );
    }

    final dead = await enqueue(
      state: 'dead',
      nextAttempt: 0,
      entityId: 'dead',
      statusCode: 422,
    );
    final inFlight = await enqueue(
      state: 'in_flight',
      nextAttempt: 0,
      entityId: 'flight',
    );
    final parked = await enqueue(
      state: 'pending',
      nextAttempt: parkedAt,
      entityId: 'parked',
      statusCode: 409,
    );
    // Fresh pending row — NOT stale.
    await enqueue(state: 'pending', nextAttempt: justSoon, entityId: 'fresh');
    // Different company — must not leak.
    await enqueue(
      state: 'dead',
      nextAttempt: 0,
      entityId: 'other',
      companyId: 'other-co',
    );

    final diag = await openLog();
    addTearDown(diag.close);
    final count = await diag.appendOutboxSnapshot(db: db, companyId: 'co');
    expect(count, 3);

    final body = await File(diag.path).readAsString();
    expect(body, contains('=== OUTBOX SNAPSHOT '));
    expect(body, contains('id=$dead'));
    expect(body, contains('id=$inFlight'));
    expect(body, contains('id=$parked'));
    expect(body, isNot(contains('entity=client/fresh')));
    expect(body, isNot(contains('entity=client/other')));
    expect(body, contains('=== END SNAPSHOT n=3 ==='));
  });

  group('isKnownBenignFrameworkNoise', () {
    final raStack = StackTrace.fromString(
      '#2      OverlayPortalController.hide (package:flutter/src/widgets/overlay.dart:1681:14)\n'
      '#3      _RawAutocompleteState._updateOptionsViewVisibility (package:flutter/src/widgets/autocomplete.dart:440:30)\n'
      '#4      _RawAutocompleteState._onFocusChange (package:flutter/src/widgets/autocomplete.dart:430:7)',
    );

    test('true for the real RawAutocomplete focus-loss signature', () {
      expect(
        isKnownBenignFrameworkNoise(
          "'package:flutter/src/widgets/overlay.dart': Failed assertion: "
          "line 1681 pos 14: '_zOrderIndex != null': is not true.",
          raStack,
        ),
        isTrue,
      );
    });

    test('false when the message matches but the stack is unrelated', () {
      // A genuine OverlayPortal misuse elsewhere must still be logged.
      expect(
        isKnownBenignFrameworkNoise(
          "Failed assertion: line 1681 pos 14: '_zOrderIndex != null': "
          'is not true.',
          StackTrace.fromString(
            '#2 OverlayPortalController.hide (overlay.dart:1681)\n'
            '#3 MyCustomOverlayThing.dismiss (package:admin/ui/foo.dart:12)',
          ),
        ),
        isFalse,
      );
    });

    final printingRasterStack = StackTrace.fromString(
      '#0      List._setIndexed (dart:core-patch/growable_array.dart:281:49)\n'
      '#1      List.[]= (dart:core-patch/growable_array.dart:276:5)\n'
      '#2      PdfPreviewRaster._raster (package:printing/src/preview/raster.dart:185:16)',
    );

    test('true for the printing rasterizer range-empty signature', () {
      expect(
        isKnownBenignFrameworkNoise(
          RangeError('Invalid value: Valid value range is empty: 0'),
          printingRasterStack,
        ),
        isTrue,
      );
    });

    test('false for a range-empty error from outside the rasterizer', () {
      // A genuine zero-length-list range error elsewhere must still surface.
      expect(
        isKnownBenignFrameworkNoise(
          RangeError('Invalid value: Valid value range is empty: 0'),
          StackTrace.fromString(
            '#1 List.[]= (dart:core-patch/growable_array.dart:276:5)\n'
            '#2 MyChartPainter.paint (package:admin/ui/foo.dart:42)',
          ),
        ),
        isFalse,
      );
    });

    test('false for an unrelated error', () {
      expect(
        isKnownBenignFrameworkNoise(RangeError('index out of range'), raStack),
        isFalse,
      );
    });

    test('false when stack is null', () {
      expect(
        isKnownBenignFrameworkNoise(
          "'_zOrderIndex != null': is not true.",
          null,
        ),
        isFalse,
      );
    });
  });
}
