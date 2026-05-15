import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// VM for Settings → E-Invoice. Pure subclass of [SettingsDraftViewModel];
/// the base owns dirty tracking, save, reset, and the override toggle for
/// every cascadeable field rendered on the page.
class EInvoiceViewModel extends SettingsDraftViewModel {
  EInvoiceViewModel({required super.repo, required super.companyId});
}
