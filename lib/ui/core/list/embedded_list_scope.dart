import 'package:flutter/widgets.dart';

/// Marks the subtree as an **embedded** entity list — one rendered inside a
/// detail screen tab (Client/Vendor/Bank-account), not a standalone list
/// screen. Row tiles and [EntityActionsPopupButton] read this to adopt the
/// Client-datatable look (vertical `⋮` menu + roomier row padding) so the
/// bottom-of-detail tables match the polished standalone Clients list.
///
/// Absent in standalone list screens, so [of] returns `false` there and
/// those rows are left exactly as-is (per-context divergence is intended).
///
/// Mirrors the `FormatterScope` / `DetailScrollScope` pattern. Presence is
/// structurally constant for a given subtree, so [updateShouldNotify] is
/// always `false` — reading it registers a dependency that never forces an
/// extra rebuild.
class EmbeddedListScope extends InheritedWidget {
  const EmbeddedListScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EmbeddedListScope>() != null;

  @override
  bool updateShouldNotify(EmbeddedListScope oldWidget) => false;
}
