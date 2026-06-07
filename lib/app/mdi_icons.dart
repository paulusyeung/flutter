import 'package:flutter/widgets.dart';

/// The few Material Design Icons glyphs we still use, backed by the vendored
/// `assets/fonts/MaterialDesignIcons.ttf` (declared under `flutter: fonts:` in
/// `pubspec.yaml`).
///
/// These are plain `const IconData` — NOT a subclass — on purpose. Flutter 3.44
/// made `IconData` a `final` class, which is exactly why the upstream
/// `material_design_icons_flutter` package (whose `_MdiIconData extends IconData`)
/// had to be removed and can't be re-added (see `.github/workflows/ci.yaml`).
/// As const instances with literal codepoints they also tree-shake to a tiny
/// glyph subset in release builds.
///
/// Add glyphs as needed — codepoints come from the package's `lib/icon_map.dart`.
/// No `fontPackage` is set: the font is a project asset, not a package asset.
abstract final class MdiIcons {
  static const String _family = 'Material Design Icons';

  /// Pencil-in-circle. The legacy admin-portal edit affordance.
  static const IconData circleEditOutline = IconData(
    0xf08d5,
    fontFamily: _family,
  );
}
