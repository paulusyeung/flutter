import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only Client detail screen.
///
/// Subscribes to [ClientRepository.watch] so anything that mutates the row
/// (a synced edit, a server refresh, an `applyDeleteResponse`) propagates
/// straight to the screen.
class ClientDetailViewModel extends GenericDetailViewModel<Client> {
  ClientDetailViewModel({
    required this.repo,
    required this.companyId,
    required this.id,
  }) {
    bindStream(repo.watch(companyId: companyId, id: id));
  }

  final ClientRepository repo;
  final String companyId;
  final String id;

  /// Backwards-compatible alias for [item] — older call sites reference
  /// `vm.client`.
  Client? get client => item;
}
