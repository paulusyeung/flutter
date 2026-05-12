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
/// without it a long scroll just stops with no explanation.
class EntityListEndOfListFooter extends StatelessWidget {
  const EntityListEndOfListFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          context.tr('end_of_list'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
