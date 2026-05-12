import 'package:admin/data/models/domain/company_settings.dart';

/// Pure projection closures for a single overridable `CompanySettings` field.
///
/// `read` pulls the current value off a settings snapshot; `write` returns
/// a new snapshot with the value applied (or cleared when the value is null).
/// Bindings have no VM dependency on purpose — the same closures power
/// [OverridableTextField] / [OverridableMarkdownField] onChange paths and the
/// `setOverride` toggle on the base settings VM, so any settings page that
/// edits `company.settings.*` plugs in by adding entries here.
typedef SettingsRead = String? Function(CompanySettings settings);
typedef SettingsWrite =
    CompanySettings Function(CompanySettings settings, String? value);

typedef SettingsBinding = ({SettingsRead read, SettingsWrite write});

/// Single source of truth mapping `apiKey` → the read/write projection. The
/// VM's `setOverride` looks up by key and applies `binding.write`; the
/// field widgets do the same on edit, so adding a new overridable field is
/// one entry here plus one call site.
final Map<String, SettingsBinding> _bindings = <String, SettingsBinding>{
  // Identification
  'name': (read: (s) => s.name, write: (s, v) => s.copyWith(name: v)),
  'id_number': (
    read: (s) => s.idNumber,
    write: (s, v) => s.copyWith(idNumber: v),
  ),
  'vat_number': (
    read: (s) => s.vatNumber,
    write: (s, v) => s.copyWith(vatNumber: v),
  ),
  'qr_iban': (read: (s) => s.qrIban, write: (s, v) => s.copyWith(qrIban: v)),
  'besr_id': (read: (s) => s.besrId, write: (s, v) => s.copyWith(besrId: v)),
  'classification': (
    read: (s) => s.classification,
    write: (s, v) => s.copyWith(classification: v),
  ),

  // Contact
  'website': (read: (s) => s.website, write: (s, v) => s.copyWith(website: v)),
  'email': (read: (s) => s.email, write: (s, v) => s.copyWith(email: v)),
  'phone': (read: (s) => s.phone, write: (s, v) => s.copyWith(phone: v)),

  // Custom values (company1..4 → custom_value1..4 on settings)
  'custom_value1': (
    read: (s) => s.customValue1,
    write: (s, v) => s.copyWith(customValue1: v),
  ),
  'custom_value2': (
    read: (s) => s.customValue2,
    write: (s, v) => s.copyWith(customValue2: v),
  ),
  'custom_value3': (
    read: (s) => s.customValue3,
    write: (s, v) => s.copyWith(customValue3: v),
  ),
  'custom_value4': (
    read: (s) => s.customValue4,
    write: (s, v) => s.copyWith(customValue4: v),
  ),

  // Address
  'address1': (
    read: (s) => s.address1,
    write: (s, v) => s.copyWith(address1: v),
  ),
  'address2': (
    read: (s) => s.address2,
    write: (s, v) => s.copyWith(address2: v),
  ),
  'city': (read: (s) => s.city, write: (s, v) => s.copyWith(city: v)),
  'state': (read: (s) => s.state, write: (s, v) => s.copyWith(state: v)),
  'postal_code': (
    read: (s) => s.postalCode,
    write: (s, v) => s.copyWith(postalCode: v),
  ),
  'country_id': (
    read: (s) => s.countryId,
    write: (s, v) => s.copyWith(countryId: v),
  ),

  // Logo
  'company_logo': (
    read: (s) => s.companyLogo,
    write: (s, v) => s.copyWith(companyLogo: v),
  ),

  // Localization
  'currency_id': (
    read: (s) => s.currencyId,
    write: (s, v) => s.copyWith(currencyId: v),
  ),
  'language_id': (
    read: (s) => s.languageId,
    write: (s, v) => s.copyWith(languageId: v),
  ),
  'payment_terms': (
    read: (s) => s.paymentTerms,
    write: (s, v) => s.copyWith(paymentTerms: v),
  ),

  // Defaults — terms & footers
  'invoice_terms': (
    read: (s) => s.invoiceTerms,
    write: (s, v) => s.copyWith(invoiceTerms: v),
  ),
  'invoice_footer': (
    read: (s) => s.invoiceFooter,
    write: (s, v) => s.copyWith(invoiceFooter: v),
  ),
  'quote_terms': (
    read: (s) => s.quoteTerms,
    write: (s, v) => s.copyWith(quoteTerms: v),
  ),
  'quote_footer': (
    read: (s) => s.quoteFooter,
    write: (s, v) => s.copyWith(quoteFooter: v),
  ),
  'credit_terms': (
    read: (s) => s.creditTerms,
    write: (s, v) => s.copyWith(creditTerms: v),
  ),
  'credit_footer': (
    read: (s) => s.creditFooter,
    write: (s, v) => s.copyWith(creditFooter: v),
  ),
  'purchase_order_terms': (
    read: (s) => s.purchaseOrderTerms,
    write: (s, v) => s.copyWith(purchaseOrderTerms: v),
  ),
  'purchase_order_footer': (
    read: (s) => s.purchaseOrderFooter,
    write: (s, v) => s.copyWith(purchaseOrderFooter: v),
  ),
};

/// All registered bindings. Used by [SettingsDraftViewModel.setOverride] when
/// it needs to look up the write closure by `apiKey`.
Map<String, SettingsBinding> settingsBindings() => _bindings;

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
