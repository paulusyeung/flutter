import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: all transient notifications go through `Notify.*` (rendered by the
/// global `ToastHost`), never `ScaffoldMessenger`'s SnackBar API. A raw
/// `showSnackBar` renders a bottom-anchored bar that bypasses the toast host —
/// wrong placement on desktop and inconsistent with every other toast.
///
/// Capturing a `ScaffoldMessenger` for the `messenger:` back-compat param is
/// still fine; only the `*SnackBar(` *methods* are banned.
void main() {
  test('lib/ does not call ScaffoldMessenger SnackBar methods', () {
    final pattern = RegExp(
      r'\.(showSnackBar|hideCurrentSnackBar|removeCurrentSnackBar)\(',
    );
    final offenders = <String>[];
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      for (final match in pattern.allMatches(content)) {
        final lineStart = content.lastIndexOf('\n', match.start) + 1;
        final lineEnd = content.indexOf('\n', match.end);
        final line = content
            .substring(lineStart, lineEnd == -1 ? content.length : lineEnd)
            .trim();
        offenders.add('${entity.path}:  $line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use Notify.success/error/warning/info (the global ToastHost) '
          'instead of ScaffoldMessenger SnackBars. Found:\n  '
          '${offenders.join('\n  ')}',
    );
  });
}
