import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/repositories/vendor_repository.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only Vendor detail screen.
///
/// Subscribes to [VendorRepository.watch] so anything that mutates the row
/// (a synced edit, a server refresh, an `applyDeleteResponse`) propagates
/// straight to the screen.
class VendorDetailViewModel extends GenericDetailViewModel<Vendor> {
  VendorDetailViewModel({
    required this.repo,
    required this.companyId,
    required this.id,
  }) {
    bindStream(repo.watch(companyId: companyId, id: id));
  }

  final VendorRepository repo;
  final String companyId;
  final String id;
}
