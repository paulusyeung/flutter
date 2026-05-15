import 'package:admin/data/models/domain/user.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only User detail screen. No entity-specific derived
/// state today — alias [GenericDetailViewModel] directly. Promote to a
/// concrete subclass when the detail screen grows derived values
/// (e.g. activity counts).
typedef UserDetailViewModel = GenericDetailViewModel<User>;
