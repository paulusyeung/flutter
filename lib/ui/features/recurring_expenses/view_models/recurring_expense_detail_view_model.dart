import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Recurring expense detail VM is a typedef on the generic base — no
/// entity-specific derived state yet. Promote to a real subclass once the
/// detail screen grows cards that need computed state.
typedef RecurringExpenseDetailViewModel =
    GenericDetailViewModel<RecurringExpense>;
