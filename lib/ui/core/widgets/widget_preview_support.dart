import 'package:flutter/material.dart' show Brightness;
import 'package:flutter/widget_previews.dart';

import 'package:admin/app/theme.dart';

/// Theme callback shared by every `@Preview` in `lib/ui/core/widgets/`. Wires
/// the same `buildInTheme(...)` the app uses so previews carry the `InTheme`
/// extension and design tokens, not the Material defaults.
PreviewThemeData appPreviewTheme() {
  return PreviewThemeData(
    materialLight: buildInTheme(Brightness.light),
    materialDark: buildInTheme(Brightness.dark),
  );
}
