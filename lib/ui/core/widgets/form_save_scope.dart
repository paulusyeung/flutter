import 'package:flutter/widgets.dart';

/// Provides the surrounding form's save callback to descendant fields so a
/// single-line `TextField` can submit the form when the user presses Enter.
///
/// Wrap an edit/settings screen body in `FormSaveScope` and reusable field
/// widgets (e.g. `OverridableTextField`) pick up the callback through their
/// `onSubmitted` automatically — no prop drilling. Multi-line fields should
/// keep Enter for newlines, so they ignore the scope.
class FormSaveScope extends InheritedWidget {
  const FormSaveScope({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    required super.child,
  });

  final VoidCallback onSubmit;

  /// When false, [trySubmit] is a no-op. Mirror the screen's `canSave` flag
  /// so Enter doesn't fire saves while the form is busy or invalid.
  final bool enabled;

  static FormSaveScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormSaveScope>();

  void trySubmit() {
    if (enabled) onSubmit();
  }

  @override
  bool updateShouldNotify(FormSaveScope oldWidget) =>
      oldWidget.onSubmit != onSubmit || oldWidget.enabled != enabled;
}
