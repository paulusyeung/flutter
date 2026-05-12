import 'package:flutter/material.dart';

/// How a column's contents align inside its allocated width.
enum ColumnAlign { start, end }

/// Declarative description of one column in a list view's table layout.
///
/// `id` is the wire identifier — must match the snake_case constants the
/// old admin-portal stores in `userCompany.settings.table_columns` (see
/// `admin-portal/lib/data/models/client_model.dart` `ClientFields.*`).
/// Renaming an id breaks compatibility with the existing app's saved
/// preferences, so don't.
///
/// `width` is fixed in logical pixels; if null, the column flexes (used by
/// the identity column only — there should be at most one flex column per
/// row to keep header/row alignment trivial).
class ColumnDefinition<T> {
  const ColumnDefinition({
    required this.id,
    required this.labelKey,
    required this.cellBuilder,
    this.valueBuilder,
    this.width,
    this.align = ColumnAlign.start,
  });

  final String id;
  // Localization key for the column header. Resolve via
  // `context.tr(column.labelKey)` at render time.
  final String labelKey;
  final double? width;
  final ColumnAlign align;
  final Widget Function(T entity, BuildContext context) cellBuilder;

  /// Canonical, copyable string for this cell (raw decimal for money, ISO
  /// for dates, untrimmed string for text). When null or returns an empty
  /// string the cell has nothing copy-worthy and the hover-copy affordance
  /// is suppressed.
  final String? Function(T entity)? valueBuilder;

  bool get isFlex => width == null;
}
