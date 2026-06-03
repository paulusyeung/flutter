import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/edit/after_save_create_action.dart';

/// Tiny stand-ins so the helper can be exercised without a real entity/repo.
/// The helper's only entity contract is `idOf` / `withId`.
class _Doc {
  const _Doc(this.id);
  final String id;
}

enum _Act { navigates, inert }

/// Resolve a [BuildContext] from a pumped widget so the helper's
/// `context.mounted` guard has something real to read.
Future<BuildContext> _context(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  return tester.element(find.byType(SizedBox));
}

void main() {
  testWidgets('online success: resolves tmp→real id, dispatches against the '
      'resolved doc, and reports the navigating action as owning nav', (
    tester,
  ) async {
    final context = await _context(tester);
    String? dispatchedId;

    final navigated = await dispatchAfterSaveOnCreate<_Doc, _Act>(
      context,
      saved: const _Doc('tmp_abc'),
      idOf: (d) => d.id,
      withId: (d, id) => _Doc(id),
      resolveId: (id) async => 'real_99', // drained create wrote the remap
      action: _Act.navigates,
      navigatesOnCreate: (a) => a == _Act.navigates,
      dispatch: (_, resolved, _) async => dispatchedId = resolved.id,
    );

    expect(dispatchedId, 'real_99'); // dispatched with the real id
    expect(navigated, isTrue); // scaffold skips its detail redirect
  });

  testWidgets('offline / timeout: no remap ⇒ resolveId returns the tmp id, '
      'dispatch sees the unchanged doc, and nav is NOT claimed', (
    tester,
  ) async {
    final context = await _context(tester);
    String? dispatchedId;

    final navigated = await dispatchAfterSaveOnCreate<_Doc, _Act>(
      context,
      saved: const _Doc('tmp_abc'),
      idOf: (d) => d.id,
      withId: (d, id) => _Doc(id),
      resolveId: (id) async => id, // no remap yet
      action: _Act.navigates,
      navigatesOnCreate: (a) => a == _Act.navigates,
      dispatch: (_, resolved, _) async => dispatchedId = resolved.id,
    );

    expect(dispatchedId, 'tmp_abc'); // unchanged — dispatch will tmp-gate
    expect(navigated, isFalse); // fall back to the detail screen
  });

  testWidgets('non-navigating action: still resolves the id (so the action '
      'works on create) but never claims navigation', (tester) async {
    final context = await _context(tester);
    String? dispatchedId;

    final navigated = await dispatchAfterSaveOnCreate<_Doc, _Act>(
      context,
      saved: const _Doc('tmp_abc'),
      idOf: (d) => d.id,
      withId: (d, id) => _Doc(id),
      resolveId: (id) async => 'real_99',
      action: _Act.inert,
      navigatesOnCreate: (a) => a == _Act.navigates,
      dispatch: (_, resolved, _) async => dispatchedId = resolved.id,
    );

    expect(dispatchedId, 'real_99'); // resolved id flows through
    expect(navigated, isFalse); // not in the allow-list ⇒ detail redirect
  });
}
