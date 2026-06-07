/// Driver for `integration_test/screenshots_test.dart`.
///
/// Unlike the plain `test_driver/integration_test.dart` (used by CI and
/// `tools/run_integration_local.sh`), this one supplies an `onScreenshot`
/// handler so `binding.takeScreenshot(name)` calls are persisted to disk as
/// `samples/screenshots/<name>.png`. Paths resolve relative to the
/// `flutter drive` working directory (the repo root).
///
/// Invoked by `tools/capture_screenshots.sh`.
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final file = File('samples/screenshots/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
);
