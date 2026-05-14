import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Detail VM for a company gateway. No entity-specific derived state today,
/// so this is a typedef on the generic base — promote to a real subclass if
/// future cards need computed views over the gateway.
typedef CompanyGatewayDetailViewModel = GenericDetailViewModel<CompanyGateway>;
