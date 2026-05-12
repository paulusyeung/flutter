import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';

/// Read/write projector that maps an apiKey to the corresponding field on
/// the `ApiSettings` draft owned by [CompanyDetailsViewModel]. Used by
/// [OverridableTextField] / [OverridableMarkdownField] so call sites only
/// pass the apiKey instead of repeating the same one-line closures.
typedef SettingsRead = String? Function(CompanyDetailsViewModel);
typedef SettingsWrite = void Function(CompanyDetailsViewModel, String);

typedef SettingsBinding = ({SettingsRead read, SettingsWrite write});

/// Single source of truth mapping `apiKey` → the read/write closures that
/// project the corresponding field on `vm.settings`. Adding a new
/// settings-bound text/markdown field is one entry here plus one call site;
/// the closures don't have to be duplicated at every call site any more.
final Map<String, SettingsBinding> _bindings = <String, SettingsBinding>{
  // Identification
  'name': (
    read: (vm) => vm.settings.name,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(name: v)),
  ),
  'id_number': (
    read: (vm) => vm.settings.idNumber,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(idNumber: v)),
  ),
  'vat_number': (
    read: (vm) => vm.settings.vatNumber,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(vatNumber: v)),
  ),
  'qr_iban': (
    read: (vm) => vm.settings.qrIban,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(qrIban: v)),
  ),
  'besr_id': (
    read: (vm) => vm.settings.besrId,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(besrId: v)),
  ),

  // Contact
  'website': (
    read: (vm) => vm.settings.website,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(website: v)),
  ),
  'email': (
    read: (vm) => vm.settings.email,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(email: v)),
  ),
  'phone': (
    read: (vm) => vm.settings.phone,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(phone: v)),
  ),

  // Custom values (company1..4 → custom_value1..4 on settings)
  'custom_value1': (
    read: (vm) => vm.settings.customValue1,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(customValue1: v)),
  ),
  'custom_value2': (
    read: (vm) => vm.settings.customValue2,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(customValue2: v)),
  ),
  'custom_value3': (
    read: (vm) => vm.settings.customValue3,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(customValue3: v)),
  ),
  'custom_value4': (
    read: (vm) => vm.settings.customValue4,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(customValue4: v)),
  ),

  // Address
  'address1': (
    read: (vm) => vm.settings.address1,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(address1: v)),
  ),
  'address2': (
    read: (vm) => vm.settings.address2,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(address2: v)),
  ),
  'city': (
    read: (vm) => vm.settings.city,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(city: v)),
  ),
  'state': (
    read: (vm) => vm.settings.state,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(state: v)),
  ),
  'postal_code': (
    read: (vm) => vm.settings.postalCode,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(postalCode: v)),
  ),

  // Defaults — terms & footers
  'invoice_terms': (
    read: (vm) => vm.settings.invoiceTerms,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(invoiceTerms: v)),
  ),
  'invoice_footer': (
    read: (vm) => vm.settings.invoiceFooter,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(invoiceFooter: v)),
  ),
  'quote_terms': (
    read: (vm) => vm.settings.quoteTerms,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(quoteTerms: v)),
  ),
  'quote_footer': (
    read: (vm) => vm.settings.quoteFooter,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(quoteFooter: v)),
  ),
  'credit_terms': (
    read: (vm) => vm.settings.creditTerms,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(creditTerms: v)),
  ),
  'credit_footer': (
    read: (vm) => vm.settings.creditFooter,
    write: (vm, v) => vm.updateSettings((s) => s.copyWith(creditFooter: v)),
  ),
  'purchase_order_terms': (
    read: (vm) => vm.settings.purchaseOrderTerms,
    write: (vm, v) =>
        vm.updateSettings((s) => s.copyWith(purchaseOrderTerms: v)),
  ),
  'purchase_order_footer': (
    read: (vm) => vm.settings.purchaseOrderFooter,
    write: (vm, v) =>
        vm.updateSettings((s) => s.copyWith(purchaseOrderFooter: v)),
  ),
};

/// Look up the binding for [apiKey]. Throws [StateError] when missing — that
/// catches typos at the call site instead of silently no-op'ing the field.
SettingsBinding settingsBindingOf(String apiKey) {
  final b = _bindings[apiKey];
  if (b == null) {
    throw StateError(
      'Unknown settings binding "$apiKey" — add it to settings_field_bindings.dart',
    );
  }
  return b;
}
