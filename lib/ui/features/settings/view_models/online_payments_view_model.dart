import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped draft for the Online Payments settings page. The screen
/// edits ~20 cascade-aware fields on `company.settings.*` plus two top-level
/// `Company.*` toggles (`enable_applying_payments`, `convert_payment_currency`),
/// all through the base class — there's no entity-specific derived state, so
/// this stays a one-line subclass.
class OnlinePaymentsViewModel extends SettingsDraftViewModel {
  OnlinePaymentsViewModel({required super.repo, required super.companyId});
}
