import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: an entity's API→companion projection must CLEAR `archived_at` on
/// restore, not leave it absent.
///
/// On restore the server echoes `archived_at: 0`. Writing `Value.absent()` for
/// that case omits the column from the partial `insertOnConflictUpdate`, so the
/// denormalized `archived_at` column keeps its stale archive timestamp — and the
/// active-list filter (`archived_at IS NULL`, see `entityStateFilter`) keeps
/// excluding the restored row. It then lingers in the Archived view while the
/// detail screen (which reads the payload) shows it as active: a split-brain that
/// does not self-heal across a fresh sync. The fix is `Value(null)`, which writes
/// an explicit NULL and clears the column.
///
/// This lint guards every current and future repository against the copy-paste
/// that reintroduces the bug. The behavioural proof lives in
/// `project_repository_test.dart` ("restore clears archived_at …"); this catches
/// the systemic regression the per-entity tests can't (most entities have no
/// archive→restore test). `user_repository` and the 2026 sweep all use
/// `Value(null)`.
void main() {
  test('repositories clear archived_at on restore — no `> 0 ? Value(...) : '
      'Value.absent()` on the API path', () {
    // Matches the API-companion anti-pattern: an `archivedAt:` projection that
    // is `... > 0 ? Value(...) : const Value.absent()` (absent on the
    // restore / `0` branch). The legitimate domain-companion form keys on
    // `== null`, so it never has `> 0` on the same line and is not matched.
    final antiPattern = RegExp(
      r'archivedAt:[^\n]*>\s*0[^\n]*Value\.absent\(\)',
    );
    final offenders = <String>[];
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      for (final match in antiPattern.allMatches(content)) {
        offenders.add('${entity.path}:  ${match.group(0)!.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'archived_at must be cleared with Value(null), not Value.absent(), '
          'on the API→companion (restore) path — otherwise a restored row '
          'stays stuck out of the active list. Use '
          '`a.archivedAt > 0 ? Value(a.archivedAt) : const Value(null)`. '
          'Found:\n  ${offenders.join('\n  ')}',
    );
  });
}
