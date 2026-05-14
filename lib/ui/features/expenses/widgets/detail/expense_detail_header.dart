import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Uses the expense
/// number (falling back to `no_name_fallback`) as the display name and
/// shows the vendor id as the optional `#<number>` slot — quick visual
/// cue without resolving the vendor row up here.
class ExpenseDetailHeader extends StatelessWidget {
  const ExpenseDetailHeader({super.key, required this.expense, this.formatter});

  final Expense expense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Expense>(
      entity: expense,
      formatter: formatter,
      project: (context, e) => EntityHeaderFields(
        seedForAvatar: e.id,
        displayName: e.number.isEmpty
            ? context.tr('no_name_fallback')
            : '#${e.number}',
        number: e.vendorId.isEmpty ? null : e.vendorId,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        isDeleted: e.isDeleted,
        isArchived: e.archivedAt != null,
        isDirty: e.isDirty,
      ),
    );
  }
}
