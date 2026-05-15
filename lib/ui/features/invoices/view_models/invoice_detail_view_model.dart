import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Invoice detail VM is a typedef on the generic base for M1 — no
/// entity-specific derived state yet. Promote to a real subclass when
/// the detail screen grows KPI cards / totals widgets that need computed
/// state (mirror `ClientDetailViewModel`).
typedef InvoiceDetailViewModel = GenericDetailViewModel<Invoice>;
