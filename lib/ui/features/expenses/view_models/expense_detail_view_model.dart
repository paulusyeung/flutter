import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Expense detail VM is a typedef on the generic base — no entity-specific
/// derived state yet. Promote to a real subclass once the detail screen
/// grows cards that need computed state (mirror `ClientDetailViewModel`).
typedef ExpenseDetailViewModel = GenericDetailViewModel<Expense>;
