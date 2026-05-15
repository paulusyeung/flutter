import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

/// Loading spinner footer appended below the last row of a paginated list
/// while the next page is in flight. 20×20 spinner with vertical padding so
/// the strip doesn't crowd the last data row.
class EntityListLoadingFooter extends StatelessWidget {
  const EntityListLoadingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// "End of list" sentinel rendered below the last row once the VM has
/// confirmed `!hasMore`. Tells the user they've reached the bottom —
/// without it a long scroll just stops with no explanation. Includes a
/// "Showing N" count below the sentinel so the user knows how many rows
/// are loaded — doubly useful when the slide-over pane covers part of
/// the table.
class EntityListEndOfListFooter extends StatelessWidget {
  const EntityListEndOfListFooter({super.key, this.count, this.total});

  /// Number of rows currently loaded into the list.
  final int? count;

  /// Total rows the server says exist (when known). When null we render
  /// "Showing N"; when set we render "Showing N of total".
  final int? total;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('end_of_list'), style: style),
            if (count != null) ...[
              const SizedBox(height: 4),
              Text(
                total != null
                    ? context.tr('showing_n_of_total', {
                        'n': '$count',
                        'total': '$total',
                      })
                    : context.tr('showing_n', {'n': '$count'}),
                style: style,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
