import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Client Portal settings page.
///
/// One-line subclass of [SettingsDraftViewModel] — load / watch / dirty /
/// save / override plumbing all lives on the base. The client-scoped path
/// uses [ClientSettingsDraftViewModel] (the cascade shell swaps it in
/// automatically) so the page body stays scope-agnostic.
class ClientPortalViewModel extends SettingsDraftViewModel {
  ClientPortalViewModel({required super.repo, required super.companyId});
}
