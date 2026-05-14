import 'package:admin/data/models/domain/company_settings.dart';

/// Pure projection closures for a single overridable `CompanySettings` field.
///
/// `read` pulls the current value off a settings snapshot; `write` returns
/// a new snapshot with the value applied (or cleared when the value is null).
/// Bindings have no VM dependency on purpose — the same closures power
/// [OverridableTextField] / [OverridableMarkdownField] onChange paths and the
/// `setOverride` toggle on the base settings VM, so any settings page that
/// edits `company.settings.*` plugs in by adding entries here.
///
/// Bool-valued fields encode `true`/`false` as `'true'`/`'false'` strings (and
/// `null` for unset) — see e.g. the `military_time` binding below. The
/// `OverridableSwitchField` widget translates between the wire-string and a
/// Dart bool transparently; callers binding to bool fields by hand pass the
/// encoded string into `setOverride` / `updateSettings` the same way.
typedef SettingsRead = String? Function(CompanySettings settings);
typedef SettingsWrite =
    CompanySettings Function(CompanySettings settings, String? value);

typedef SettingsBinding = ({SettingsRead read, SettingsWrite write});

/// Parse the string-encoded form of a bool binding back to `bool?`. Tolerates
/// `'TRUE'` / `'True'` / `'1'` / `'0'` etc. — anything obviously truthy is
/// `true`; `null` stays `null`; anything else is `false`. The only writer
/// today is `OverridableSwitchField` (which stringifies a Dart bool), so this
/// is belt-and-braces against future call sites that don't match the exact
/// `'true'`/`'false'` convention.
bool? _parseBool(String? v) {
  if (v == null) return null;
  final s = v.trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

/// Parse the string-encoded form of a double binding (e.g. the minimum-payment
/// amount fields under Online Payments). Empty / null inputs clear the field
/// (`null` on the wire). Accepts either `"10.50"` or `"10,50"` so a locale
/// that sets `useCommaAsDecimalPlace` doesn't have to thread the setting
/// through every binding — `double.tryParse` is attempted first, and only
/// falls back to the comma→dot rewrite when that fails (preserving values
/// like `"1,000.50"` that already use the dot form). A malformed input
/// returns `null` rather than throwing, matching the lenient behavior of
/// the legacy admin-portal Money field.
double? _parseDouble(String? v) {
  if (v == null) return null;
  final s = v.trim();
  if (s.isEmpty) return null;
  final dotParse = double.tryParse(s);
  if (dotParse != null) return dotParse;
  if (s.contains(',')) {
    return double.tryParse(s.replaceAll(',', '.'));
  }
  return null;
}

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
  'timezone_id': (
    read: (s) => s.timezoneId,
    write: (s, v) => s.copyWith(timezoneId: v),
  ),
  'date_format_id': (
    read: (s) => s.dateFormatId,
    write: (s, v) => s.copyWith(dateFormatId: v),
  ),
  'first_month_of_year': (
    read: (s) => s.firstMonthOfYear,
    write: (s, v) => s.copyWith(firstMonthOfYear: v),
  ),
  'show_currency_code': (
    read: (s) => s.showCurrencyCode?.toString(),
    write: (s, v) => s.copyWith(showCurrencyCode: _parseBool(v)),
  ),
  'military_time': (
    read: (s) => s.militaryTime?.toString(),
    write: (s, v) => s.copyWith(militaryTime: _parseBool(v)),
  ),
  'enable_rappen_rounding': (
    read: (s) => s.enableRappenRounding?.toString(),
    write: (s, v) => s.copyWith(enableRappenRounding: _parseBool(v)),
  ),
  'use_comma_as_decimal_place': (
    read: (s) => s.useCommaAsDecimalPlace?.toString(),
    write: (s, v) => s.copyWith(useCommaAsDecimalPlace: _parseBool(v)),
  ),
  'payment_terms': (
    read: (s) => s.paymentTerms,
    write: (s, v) => s.copyWith(paymentTerms: v),
  ),

  // Online Payments
  'auto_bill_standard_invoices': (
    read: (s) => s.autoBillStandardInvoices?.toString(),
    write: (s, v) => s.copyWith(autoBillStandardInvoices: _parseBool(v)),
  ),
  'auto_bill': (
    read: (s) => s.autoBill,
    write: (s, v) => s.copyWith(autoBill: v),
  ),
  'auto_bill_date': (
    read: (s) => s.autoBillDate,
    write: (s, v) => s.copyWith(autoBillDate: v),
  ),
  'use_credits_payment': (
    read: (s) => s.useCreditsPayment,
    write: (s, v) => s.copyWith(useCreditsPayment: v),
  ),
  'use_unapplied_payment': (
    read: (s) => s.useUnappliedPayment,
    write: (s, v) => s.copyWith(useUnappliedPayment: v),
  ),
  'client_initiated_payments': (
    read: (s) => s.clientInitiatedPayments?.toString(),
    write: (s, v) => s.copyWith(clientInitiatedPayments: _parseBool(v)),
  ),
  'client_initiated_payments_minimum': (
    read: (s) => s.clientInitiatedPaymentsMinimum?.toString(),
    write: (s, v) =>
        s.copyWith(clientInitiatedPaymentsMinimum: _parseDouble(v)),
  ),
  'client_portal_allow_over_payment': (
    read: (s) => s.clientPortalAllowOverPayment?.toString(),
    write: (s, v) => s.copyWith(clientPortalAllowOverPayment: _parseBool(v)),
  ),
  'client_portal_allow_under_payment': (
    read: (s) => s.clientPortalAllowUnderPayment?.toString(),
    write: (s, v) => s.copyWith(clientPortalAllowUnderPayment: _parseBool(v)),
  ),
  'client_portal_under_payment_minimum': (
    read: (s) => s.clientPortalUnderPaymentMinimum?.toString(),
    write: (s, v) =>
        s.copyWith(clientPortalUnderPaymentMinimum: _parseDouble(v)),
  ),
  // `payment_flow` stores 'smooth' or 'default' on the wire but renders as a
  // toggle. Read maps 'smooth' → 'true', anything else (incl. null) → 'false'
  // when set; null stays null so the override checkbox detects "not set".
  // Write reverses: 'true' → 'smooth', else → 'default'.
  'payment_flow': (
    read: (s) {
      final v = s.paymentFlow;
      if (v == null) return null;
      return (v == 'smooth').toString();
    },
    write: (s, v) {
      if (v == null) return s.copyWith(paymentFlow: null);
      return s.copyWith(
        paymentFlow: _parseBool(v) == true ? 'smooth' : 'default',
      );
    },
  ),
  'unlock_invoice_documents_after_payment': (
    read: (s) => s.unlockInvoiceDocumentsAfterPayment?.toString(),
    write: (s, v) =>
        s.copyWith(unlockInvoiceDocumentsAfterPayment: _parseBool(v)),
  ),
  'valid_until': (
    read: (s) => s.validUntil,
    write: (s, v) => s.copyWith(validUntil: v),
  ),
  'payment_type_id': (
    read: (s) => s.paymentTypeId,
    write: (s, v) => s.copyWith(paymentTypeId: v),
  ),
  'default_expense_payment_type_id': (
    read: (s) => s.defaultExpensePaymentTypeId,
    write: (s, v) => s.copyWith(defaultExpensePaymentTypeId: v),
  ),
  'client_online_payment_notification': (
    read: (s) => s.clientOnlinePaymentNotification?.toString(),
    write: (s, v) => s.copyWith(clientOnlinePaymentNotification: _parseBool(v)),
  ),
  'client_manual_payment_notification': (
    read: (s) => s.clientManualPaymentNotification?.toString(),
    write: (s, v) => s.copyWith(clientManualPaymentNotification: _parseBool(v)),
  ),
  'send_email_on_mark_paid': (
    read: (s) => s.sendEmailOnMarkPaid?.toString(),
    write: (s, v) => s.copyWith(sendEmailOnMarkPaid: _parseBool(v)),
  ),
  'payment_email_all_contacts': (
    read: (s) => s.paymentEmailAllContacts?.toString(),
    write: (s, v) => s.copyWith(paymentEmailAllContacts: _parseBool(v)),
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
