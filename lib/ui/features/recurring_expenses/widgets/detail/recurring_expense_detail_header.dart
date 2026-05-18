import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Uses the recurring
/// expense number as the display name with the vendor id slotted as the
/// `#<number>` hint (parity with `ExpenseDetailHeader`).
class RecurringExpenseDetailHeader extends StatelessWidget {
  const RecurringExpenseDetailHeader({
    super.key,
    required this.recurringExpense,
    this.formatter,
  });

  final RecurringExpense recurringExpense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<RecurringExpense>(
      entity: recurringExpense,
      entityType: EntityType.recurringExpense,
      recordId: recurringExpense.id,
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
