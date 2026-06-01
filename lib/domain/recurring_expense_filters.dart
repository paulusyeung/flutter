import 'package:admin/domain/recurring_expense_status.dart';

/// Stable ids for the 5 status chips above the Recurring Expenses list.
/// `null` represents "all" — the catch-all chip the user lands on by
/// default. Ordering here matches the chip strip's left-to-right order.
class RecurringExpenseStatusChip {
  const RecurringExpenseStatusChip({required this.id, required this.labelKey});

  /// One of the [kRecurringExpenseStatus*] constants, or `null` for the
  /// "all" chip.
  final String? id;

  /// Localization key used to render the chip label.
  final String labelKey;
}

const List<RecurringExpenseStatusChip> kRecurringExpenseStatusChips =
    <RecurringExpenseStatusChip>[
      RecurringExpenseStatusChip(id: null, labelKey: 'all'),
      RecurringExpenseStatusChip(
        id: kRecurringExpenseStatusDraft,
        labelKey: 'draft',
      ),
      RecurringExpenseStatusChip(
        id: kRecurringExpenseStatusActive,
        labelKey: 'active',
      ),
      RecurringExpenseStatusChip(
        id: kRecurringExpenseStatusPaused,
        labelKey: 'paused',
      ),
      RecurringExpenseStatusChip(
        id: kRecurringExpenseStatusCompleted,
        labelKey: 'completed',
      ),
      RecurringExpenseStatusChip(
        id: kRecurringExpenseStatusPending,
        labelKey: 'pending',
      ),
    ];
