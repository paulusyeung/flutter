import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';

/// Build the bulk-action SnackBar copy from a multi-part localization
/// template. Pure helper — used by [EntityListScreenScaffold] and by any
/// custom screen that calls `GenericListViewModel.applyBulkAction(...)`
/// directly.
///
/// `singleKey` is the single-row variant ("Archived client"). `pluralKey`
/// is the success template ("Archived :count clients" / ":value clients
/// archived"). The helper substitutes both `:count` and `:value` from
/// `result.ok` so each locale string can pick whichever placeholder it
/// prefers. `nothingKey` is the "nothing matched" fallback.
///
/// Skipped + failed counts are appended via the shared `count_skipped` /
/// `count_failed` keys, joined with ` · `.
String formatBulkMessage(
  BuildContext context, {
  required String singleKey,
  required String pluralKey,
  required String nothingKey,
  required ({int ok, int skipped, int failed}) result,
}) {
  final parts = <String>[];
  if (result.ok > 0) {
    final base = result.ok == 1
        ? context.tr(singleKey)
        : context.tr(pluralKey, {
            'count': result.ok.toString(),
            'value': result.ok.toString(),
          });
    parts.add(base);
  }
  if (result.skipped > 0) {
    parts.add(
      context.tr('count_skipped', {'count': result.skipped.toString()}),
    );
  }
  if (result.failed > 0) {
    parts.add(context.tr('count_failed', {'count': result.failed.toString()}));
  }
  if (parts.isEmpty) return context.tr(nothingKey);
  return parts.join(' · ');
}
