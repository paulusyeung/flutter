import 'package:admin/data/models/domain/project.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Project detail VM is a typedef on the generic base — no entity-specific
/// derived state today. Promote to a real subclass when a Project KPI strip
/// / cards-grid / tabs ship (mirror `ClientDetailViewModel`).
typedef ProjectDetailViewModel = GenericDetailViewModel<Project>;
