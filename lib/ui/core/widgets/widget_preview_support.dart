import 'package:flutter/widget_previews.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';

/// Theme callback shared by every `@Preview` in `lib/ui/core/widgets/`. Wires
/// the same `buildInTheme(...)` the app uses so previews carry the `InTheme`
/// extension and design tokens, not the Material defaults.
PreviewThemeData appPreviewTheme() {
  return PreviewThemeData(
    materialLight: buildInTheme(InTheme.light),
    materialDark: buildInTheme(InTheme.dark),
  );
}
