import 'package:flutter/widgets.dart';

/// Publishes the detail screen's page [ScrollController] to descendants so an
/// embedded related-entity list (rendered inside a detail tab) can drive its
/// page-by-page pagination off the *page* scroll instead of its own viewport.
///
/// Background: each entity detail screen builds one
/// `SingleChildScrollView` in its `bodyBuilder`. Embedded lists used to be
/// fixed-height boxes with their own scrollbar; they now shrink-wrap and grow
/// with the page (single scrollbar, React-like). With no inner scroll, the
/// embedded `EntityListScreenScaffold` can't watch its own controller for the
/// near-bottom "load next page" signal — it reads this scope instead.
///
/// Mirrors the `FormatterScope` pattern (`maybeOf` + `updateShouldNotify`).
/// `EntityDetailScaffold` owns the controller and wraps the resolved body in
/// one of these; non-embedded screens never read it.
class DetailScrollScope extends InheritedWidget {
  const DetailScrollScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DetailScrollScope>()
      ?.controller;

  @override
  bool updateShouldNotify(DetailScrollScope oldWidget) =>
      !identical(oldWidget.controller, controller);
}
