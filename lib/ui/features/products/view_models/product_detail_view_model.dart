import 'package:admin/data/models/domain/product.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only Product detail screen. No entity-specific derived
/// state today — alias to [GenericDetailViewModel] directly. Promote to a
/// concrete subclass only when a future tab/KPI needs computed values that
/// don't fit on the domain model.
typedef ProductDetailViewModel = GenericDetailViewModel<Product>;
