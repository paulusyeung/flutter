import 'package:flutter/widgets.dart';

import 'package:admin/utils/formatting.dart';

/// Provides the active-company [Formatter] to descendant cell renderers so
/// list-table money cells can format through the per-client→company
/// currency cascade without widening `ColumnDefinition.cellBuilder`'s
/// `(entity, context)` signature across every entity's list tile.
///
/// Mirrors the `FormSaveScope` pattern (`maybeOf` + `updateShouldNotify`).
/// The list scaffold wraps its body in one of these when it renders money
/// (`wantsFormatter`); `cellMoney` reads it via [maybeOf] and falls back
/// to locale formatting when absent (non-financial screens / formatter
/// still loading on a cold start).
class FormatterScope extends InheritedWidget {
  const FormatterScope({
    super.key,
    required this.formatter,
    required super.child,
  });

  final Formatter formatter;

  static Formatter? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FormatterScope>()
      ?.formatter;

  @override
  bool updateShouldNotify(FormatterScope oldWidget) =>
      !identical(oldWidget.formatter, formatter);
}
