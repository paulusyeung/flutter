import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only ExpenseCategory detail screen. No entity-specific
/// derived state — alias to [GenericDetailViewModel] directly. Mirrors
/// [ProductDetailViewModel] / [TaskStatusDetailViewModel].
typedef ExpenseCategoryDetailViewModel =
    GenericDetailViewModel<ExpenseCategory>;
