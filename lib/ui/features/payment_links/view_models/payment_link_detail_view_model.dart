import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only Payment Link detail screen. No
/// entity-specific derived state — alias to [GenericDetailViewModel]
/// directly. Mirrors [ExpenseCategoryDetailViewModel].
typedef PaymentLinkDetailViewModel = GenericDetailViewModel<PaymentLink>;
