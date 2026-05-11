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
    required this.label,
    required this.cellBuilder,
    this.width,
    this.align = ColumnAlign.start,
  });

  final String id;
  final String label;
  final double? width;
  final ColumnAlign align;
  final Widget Function(T entity, BuildContext context) cellBuilder;

  bool get isFlex => width == null;
}
