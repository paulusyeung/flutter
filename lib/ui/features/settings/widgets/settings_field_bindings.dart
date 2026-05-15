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

  // Taxes — defaults edited from Settings → Tax Settings. The
  // `tax_name1/2/3` + `tax_rate1/2/3` pairs are written atomically when the
  // tax-rate picker selects a row (the picker calls `updateSettings(...)`
  // directly with both keys). These bindings exist so the override
  // checkbox at client/group scope can clear them via `setOverride`.
  'tax_name1': (
    read: (s) => s.taxName1,
    write: (s, v) => s.copyWith(taxName1: v),
  ),
  'tax_rate1': (
    read: (s) => s.taxRate1?.toString(),
    write: (s, v) => s.copyWith(taxRate1: _parseDouble(v)),
  ),
  'tax_name2': (
    read: (s) => s.taxName2,
    write: (s, v) => s.copyWith(taxName2: v),
  ),
  'tax_rate2': (
    read: (s) => s.taxRate2?.toString(),
    write: (s, v) => s.copyWith(taxRate2: _parseDouble(v)),
  ),
  'tax_name3': (
    read: (s) => s.taxName3,
    write: (s, v) => s.copyWith(taxName3: v),
  ),
  'tax_rate3': (
    read: (s) => s.taxRate3?.toString(),
    write: (s, v) => s.copyWith(taxRate3: _parseDouble(v)),
  ),
  'inclusive_taxes': (
    read: (s) => s.inclusiveTaxes?.toString(),
    write: (s, v) => s.copyWith(inclusiveTaxes: _parseBool(v)),
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

  // Tasks
  'default_task_rate': (
    read: (s) => s.defaultTaskRate?.toString(),
    write: (s, v) => s.copyWith(defaultTaskRate: _parseDouble(v)),
  ),
  'show_task_item_description': (
    read: (s) => s.showTaskItemDescription?.toString(),
    write: (s, v) => s.copyWith(showTaskItemDescription: _parseBool(v)),
  ),
  'allow_billable_task_items': (
    read: (s) => s.allowBillableTaskItems?.toString(),
    write: (s, v) => s.copyWith(allowBillableTaskItems: _parseBool(v)),
  ),
  'task_round_up': (
    read: (s) => s.taskRoundUp?.toString(),
    write: (s, v) => s.copyWith(taskRoundUp: _parseBool(v)),
  ),
  // `task_round_to_nearest` is `double?` on the wire but always represents
  // an integer number of seconds. Reading as `.toInt().toString()` keeps
  // the int-only OverridableNumberField display + dropdown comparison
  // working — `.toString()` on a `double` produces "900.0" which
  // `int.tryParse` rejects, leaving the custom-seconds field empty.
  'task_round_to_nearest': (
    read: (s) => s.taskRoundToNearest?.toInt().toString(),
    write: (s, v) => s.copyWith(taskRoundToNearest: _parseDouble(v)),
  ),
  'enable_client_portal_tasks': (
    read: (s) => s.enableClientPortalTasks?.toString(),
    write: (s, v) => s.copyWith(enableClientPortalTasks: _parseBool(v)),
  ),
  'show_all_tasks_client_portal': (
    read: (s) => s.showAllTasksClientPortal,
    write: (s, v) => s.copyWith(showAllTasksClientPortal: v),
  ),

  // Workflow — edited from Settings → Workflow Settings. The two top-level
  // company toggles on that page (`stop_on_unpaid_recurring`,
  // `use_quote_terms_on_conversion`) live on `Company`, not `CompanySettings`,
  // and aren't registered here.
  'auto_email_invoice': (
    read: (s) => s.autoEmailInvoice?.toString(),
    write: (s, v) => s.copyWith(autoEmailInvoice: _parseBool(v)),
  ),
  'auto_archive_invoice': (
    read: (s) => s.autoArchiveInvoice?.toString(),
    write: (s, v) => s.copyWith(autoArchiveInvoice: _parseBool(v)),
  ),
  'auto_archive_invoice_cancelled': (
    read: (s) => s.autoArchiveInvoiceCancelled?.toString(),
    write: (s, v) => s.copyWith(autoArchiveInvoiceCancelled: _parseBool(v)),
  ),
  'auto_convert_quote': (
    read: (s) => s.autoConvertQuote?.toString(),
    write: (s, v) => s.copyWith(autoConvertQuote: _parseBool(v)),
  ),
  'auto_archive_quote': (
    read: (s) => s.autoArchiveQuote?.toString(),
    write: (s, v) => s.copyWith(autoArchiveQuote: _parseBool(v)),
  ),
  'lock_invoices': (
    read: (s) => s.lockInvoices,
    write: (s, v) => s.copyWith(lockInvoices: v),
  ),

  // Invoice Design — design selectors. Stored on the server as
  // `*_design_id` strings; empty / null clears the field. The optional
  // pickers (statement / delivery_note / payment_receipt / payment_refund)
  // accept null to mean "use default".
  'invoice_design_id': (
    read: (s) => s.invoiceDesignId,
    write: (s, v) => s.copyWith(invoiceDesignId: v),
  ),
  'quote_design_id': (
    read: (s) => s.quoteDesignId,
    write: (s, v) => s.copyWith(quoteDesignId: v),
  ),
  'credit_design_id': (
    read: (s) => s.creditDesignId,
    write: (s, v) => s.copyWith(creditDesignId: v),
  ),
  'purchase_order_design_id': (
    read: (s) => s.purchaseOrderDesignId,
    write: (s, v) => s.copyWith(purchaseOrderDesignId: v),
  ),
  'delivery_note_design_id': (
    read: (s) => s.deliveryNoteDesignId,
    write: (s, v) => s.copyWith(deliveryNoteDesignId: v),
  ),
  'statement_design_id': (
    read: (s) => s.statementDesignId,
    write: (s, v) => s.copyWith(statementDesignId: v),
  ),
  'payment_receipt_design_id': (
    read: (s) => s.paymentReceiptDesignId,
    write: (s, v) => s.copyWith(paymentReceiptDesignId: v),
  ),
  'payment_refund_design_id': (
    read: (s) => s.paymentRefundDesignId,
    write: (s, v) => s.copyWith(paymentRefundDesignId: v),
  ),

  // Invoice Design — page layout / typography
  'page_size': (
    read: (s) => s.pageSize,
    write: (s, v) => s.copyWith(pageSize: v),
  ),
  'page_layout': (
    read: (s) => s.pageLayout,
    write: (s, v) => s.copyWith(pageLayout: v),
  ),
  // `font_size` is an int on the wire. Bindings serialize as `String?` so the
  // VM's setOverride / OverridableDropdownField (which stringifies values)
  // round-trip through `int.tryParse`. Empty / unparseable → null.
  'font_size': (
    read: (s) => s.fontSize?.toString(),
    write: (s, v) => s.copyWith(fontSize: v == null ? null : int.tryParse(v)),
  ),
  // `company_logo_size` stores either "<n>%" or "<n>px" — the unit segmented
  // control owns serialization; the binding is a transparent passthrough.
  'company_logo_size': (
    read: (s) => s.companyLogoSize,
    write: (s, v) => s.copyWith(companyLogoSize: v),
  ),
  'primary_font': (
    read: (s) => s.primaryFont,
    write: (s, v) => s.copyWith(primaryFont: v),
  ),
  'secondary_font': (
    read: (s) => s.secondaryFont,
    write: (s, v) => s.copyWith(secondaryFont: v),
  ),
  'primary_color': (
    read: (s) => s.primaryColor,
    write: (s, v) => s.copyWith(primaryColor: v),
  ),
  'secondary_color': (
    read: (s) => s.secondaryColor,
    write: (s, v) => s.copyWith(secondaryColor: v),
  ),

  // Invoice Design — display / pagination toggles
  'show_paid_stamp': (
    read: (s) => s.showPaidStamp?.toString(),
    write: (s, v) => s.copyWith(showPaidStamp: _parseBool(v)),
  ),
  'show_shipping_address': (
    read: (s) => s.showShippingAddress?.toString(),
    write: (s, v) => s.copyWith(showShippingAddress: _parseBool(v)),
  ),
  'embed_documents': (
    read: (s) => s.embedDocuments?.toString(),
    write: (s, v) => s.copyWith(embedDocuments: _parseBool(v)),
  ),
  'hide_empty_columns_on_pdf': (
    read: (s) => s.hideEmptyColumnsOnPdf?.toString(),
    write: (s, v) => s.copyWith(hideEmptyColumnsOnPdf: _parseBool(v)),
  ),
  'page_numbering': (
    read: (s) => s.pageNumbering?.toString(),
    write: (s, v) => s.copyWith(pageNumbering: _parseBool(v)),
  ),
  'page_numbering_alignment': (
    read: (s) => s.pageNumberingAlignment,
    write: (s, v) => s.copyWith(pageNumberingAlignment: v),
  ),
  'sync_invoice_quote_columns': (
    read: (s) => s.syncInvoiceQuoteColumns?.toString(),
    write: (s, v) => s.copyWith(syncInvoiceQuoteColumns: _parseBool(v)),
  ),

  // Generated Numbers — global. `counter_padding` and
  // `reset_counter_frequency_id` are `int?` on the wire; we round-trip via
  // `String?` so the dropdown's stringified value (and `setOverride`) stays
  // consistent. `shared_*` are `bool?` encoded as `'true'`/`'false'` per the
  // bool-binding convention at the top of this file.
  'counter_padding': (
    read: (s) => s.counterPadding?.toString(),
    write: (s, v) =>
        s.copyWith(counterPadding: v == null ? null : int.tryParse(v)),
  ),
  'counter_number_applied': (
    read: (s) => s.counterNumberApplied,
    write: (s, v) => s.copyWith(counterNumberApplied: v),
  ),
  'reset_counter_frequency_id': (
    read: (s) => s.resetCounterFrequencyId?.toString(),
    write: (s, v) =>
        s.copyWith(resetCounterFrequencyId: v == null ? null : int.tryParse(v)),
  ),
  'reset_counter_date': (
    read: (s) => s.resetCounterDate,
    write: (s, v) => s.copyWith(resetCounterDate: v),
  ),
  'recurring_number_prefix': (
    read: (s) => s.recurringNumberPrefix,
    write: (s, v) => s.copyWith(recurringNumberPrefix: v),
  ),
  'shared_invoice_quote_counter': (
    read: (s) => s.sharedInvoiceQuoteCounter?.toString(),
    write: (s, v) => s.copyWith(sharedInvoiceQuoteCounter: _parseBool(v)),
  ),
  'shared_invoice_credit_counter': (
    read: (s) => s.sharedInvoiceCreditCounter?.toString(),
    write: (s, v) => s.copyWith(sharedInvoiceCreditCounter: _parseBool(v)),
  ),

  // Generated Numbers — per-entity pattern + counter. Pattern is `String?`;
  // counter is `int?` round-tripped via `String?` (same shape as
  // `counter_padding` above).
  'client_number_pattern': (
    read: (s) => s.clientNumberPattern,
    write: (s, v) => s.copyWith(clientNumberPattern: v),
  ),
  'client_number_counter': (
    read: (s) => s.clientNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(clientNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'invoice_number_pattern': (
    read: (s) => s.invoiceNumberPattern,
    write: (s, v) => s.copyWith(invoiceNumberPattern: v),
  ),
  'invoice_number_counter': (
    read: (s) => s.invoiceNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(invoiceNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'recurring_invoice_number_pattern': (
    read: (s) => s.recurringInvoiceNumberPattern,
    write: (s, v) => s.copyWith(recurringInvoiceNumberPattern: v),
  ),
  'recurring_invoice_number_counter': (
    read: (s) => s.recurringInvoiceNumberCounter?.toString(),
    write: (s, v) => s.copyWith(
      recurringInvoiceNumberCounter: v == null ? null : int.tryParse(v),
    ),
  ),
  'payment_number_pattern': (
    read: (s) => s.paymentNumberPattern,
    write: (s, v) => s.copyWith(paymentNumberPattern: v),
  ),
  'payment_number_counter': (
    read: (s) => s.paymentNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(paymentNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'quote_number_pattern': (
    read: (s) => s.quoteNumberPattern,
    write: (s, v) => s.copyWith(quoteNumberPattern: v),
  ),
  'quote_number_counter': (
    read: (s) => s.quoteNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(quoteNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'credit_number_pattern': (
    read: (s) => s.creditNumberPattern,
    write: (s, v) => s.copyWith(creditNumberPattern: v),
  ),
  'credit_number_counter': (
    read: (s) => s.creditNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(creditNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'project_number_pattern': (
    read: (s) => s.projectNumberPattern,
    write: (s, v) => s.copyWith(projectNumberPattern: v),
  ),
  'project_number_counter': (
    read: (s) => s.projectNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(projectNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'task_number_pattern': (
    read: (s) => s.taskNumberPattern,
    write: (s, v) => s.copyWith(taskNumberPattern: v),
  ),
  'task_number_counter': (
    read: (s) => s.taskNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(taskNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'vendor_number_pattern': (
    read: (s) => s.vendorNumberPattern,
    write: (s, v) => s.copyWith(vendorNumberPattern: v),
  ),
  'vendor_number_counter': (
    read: (s) => s.vendorNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(vendorNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'purchase_order_number_pattern': (
    read: (s) => s.purchaseOrderNumberPattern,
    write: (s, v) => s.copyWith(purchaseOrderNumberPattern: v),
  ),
  'purchase_order_number_counter': (
    read: (s) => s.purchaseOrderNumberCounter?.toString(),
    write: (s, v) => s.copyWith(
      purchaseOrderNumberCounter: v == null ? null : int.tryParse(v),
    ),
  ),
  'expense_number_pattern': (
    read: (s) => s.expenseNumberPattern,
    write: (s, v) => s.copyWith(expenseNumberPattern: v),
  ),
  'expense_number_counter': (
    read: (s) => s.expenseNumberCounter?.toString(),
    write: (s, v) =>
        s.copyWith(expenseNumberCounter: v == null ? null : int.tryParse(v)),
  ),
  'recurring_expense_number_pattern': (
    read: (s) => s.recurringExpenseNumberPattern,
    write: (s, v) => s.copyWith(recurringExpenseNumberPattern: v),
  ),
  'recurring_expense_number_counter': (
    read: (s) => s.recurringExpenseNumberCounter?.toString(),
    write: (s, v) => s.copyWith(
      recurringExpenseNumberCounter: v == null ? null : int.tryParse(v),
    ),
  ),

  // Client Portal — every cascade-aware row on the five-tab Client Portal
  // screen. Top-level Company fields (subdomain, portal_domain, portal_mode,
  // client_registration_fields) live on `Company` and aren't registered here;
  // their editors write through `host.updateCompany(...)` instead. Boolean
  // bindings encode through `_parseBool` for the OverridableSwitchField
  // wire-string convention. Each row uses `?.toString()` on read so an unset
  // value surfaces as `null` (the "no override" signal) rather than the
  // literal string `"null"`.
  'enable_client_portal': (
    read: (s) => s.enableClientPortal?.toString(),
    write: (s, v) => s.copyWith(enableClientPortal: _parseBool(v)),
  ),
  'enable_client_portal_dashboard': (
    read: (s) => s.enableClientPortalDashboard?.toString(),
    write: (s, v) => s.copyWith(enableClientPortalDashboard: _parseBool(v)),
  ),
  'enable_client_portal_password': (
    read: (s) => s.enableClientPortalPassword?.toString(),
    write: (s, v) => s.copyWith(enableClientPortalPassword: _parseBool(v)),
  ),
  'client_portal_terms': (
    read: (s) => s.clientPortalTerms,
    write: (s, v) => s.copyWith(clientPortalTerms: v),
  ),
  'client_portal_privacy_policy': (
    read: (s) => s.clientPortalPrivacyPolicy,
    write: (s, v) => s.copyWith(clientPortalPrivacyPolicy: v),
  ),
  'client_portal_enable_uploads': (
    read: (s) => s.clientPortalEnableUploads?.toString(),
    write: (s, v) => s.copyWith(clientPortalEnableUploads: _parseBool(v)),
  ),
  'vendor_portal_enable_uploads': (
    read: (s) => s.vendorPortalEnableUploads?.toString(),
    write: (s, v) => s.copyWith(vendorPortalEnableUploads: _parseBool(v)),
  ),
  'accept_client_input_quote_approval': (
    read: (s) => s.acceptClientInputQuoteApproval?.toString(),
    write: (s, v) => s.copyWith(acceptClientInputQuoteApproval: _parseBool(v)),
  ),
  'show_pdfhtml_on_mobile': (
    read: (s) => s.showPdfhtmlOnMobile?.toString(),
    write: (s, v) => s.copyWith(showPdfhtmlOnMobile: _parseBool(v)),
  ),
  'preference_product_notes_for_html_view': (
    read: (s) => s.preferenceProductNotesForHtmlView?.toString(),
    write: (s, v) =>
        s.copyWith(preferenceProductNotesForHtmlView: _parseBool(v)),
  ),
  'enable_client_profile_update': (
    read: (s) => s.enableClientProfileUpdate?.toString(),
    write: (s, v) => s.copyWith(enableClientProfileUpdate: _parseBool(v)),
  ),
  'show_accept_invoice_terms': (
    read: (s) => s.showAcceptInvoiceTerms?.toString(),
    write: (s, v) => s.copyWith(showAcceptInvoiceTerms: _parseBool(v)),
  ),
  'show_accept_quote_terms': (
    read: (s) => s.showAcceptQuoteTerms?.toString(),
    write: (s, v) => s.copyWith(showAcceptQuoteTerms: _parseBool(v)),
  ),
  'require_invoice_signature': (
    read: (s) => s.requireInvoiceSignature?.toString(),
    write: (s, v) => s.copyWith(requireInvoiceSignature: _parseBool(v)),
  ),
  'require_quote_signature': (
    read: (s) => s.requireQuoteSignature?.toString(),
    write: (s, v) => s.copyWith(requireQuoteSignature: _parseBool(v)),
  ),
  'require_purchase_order_signature': (
    read: (s) => s.requirePurchaseOrderSignature?.toString(),
    write: (s, v) => s.copyWith(requirePurchaseOrderSignature: _parseBool(v)),
  ),
  'signature_on_pdf': (
    read: (s) => s.signatureOnPdf?.toString(),
    write: (s, v) => s.copyWith(signatureOnPdf: _parseBool(v)),
  ),
  'client_can_register': (
    read: (s) => s.clientCanRegister?.toString(),
    write: (s, v) => s.copyWith(clientCanRegister: _parseBool(v)),
  ),
  'custom_message_dashboard': (
    read: (s) => s.customMessageDashboard,
    write: (s, v) => s.copyWith(customMessageDashboard: v),
  ),
  'custom_message_unpaid_invoice': (
    read: (s) => s.customMessageUnpaidInvoice,
    write: (s, v) => s.copyWith(customMessageUnpaidInvoice: v),
  ),
  'custom_message_paid_invoice': (
    read: (s) => s.customMessagePaidInvoice,
    write: (s, v) => s.copyWith(customMessagePaidInvoice: v),
  ),
  'custom_message_unapproved_quote': (
    read: (s) => s.customMessageUnapprovedQuote,
    write: (s, v) => s.copyWith(customMessageUnapprovedQuote: v),
  ),
  'portal_custom_head': (
    read: (s) => s.portalCustomHead,
    write: (s, v) => s.copyWith(portalCustomHead: v),
  ),
  'portal_custom_footer': (
    read: (s) => s.portalCustomFooter,
    write: (s, v) => s.copyWith(portalCustomFooter: v),
  ),
  'portal_custom_css': (
    read: (s) => s.portalCustomCss,
    write: (s, v) => s.copyWith(portalCustomCss: v),
  ),
  'portal_custom_js': (
    read: (s) => s.portalCustomJs,
    write: (s, v) => s.copyWith(portalCustomJs: v),
  ),

  // Email Settings — every cascade-aware row on the Email Settings screen.
  // The seven top-level SMTP fields (`smtp_host`, …) live on `Company` and
  // aren't registered here; the SMTP card writes them via
  // `host.updateCompany(...)`. String bindings are passthroughs; bool
  // bindings (`show_email_footer` and the three attachment toggles) use the
  // `_parseBool` wire-string convention. `entity_send_time` is `int?` on
  // the wire, round-tripped via `String?` the same way `counter_padding`
  // does it.
  'email_sending_method': (
    read: (s) => s.emailSendingMethod,
    write: (s, v) => s.copyWith(emailSendingMethod: v),
  ),
  'gmail_sending_user_id': (
    read: (s) => s.gmailSendingUserId,
    write: (s, v) => s.copyWith(gmailSendingUserId: v),
  ),
  'email_from_name': (
    read: (s) => s.emailFromName,
    write: (s, v) => s.copyWith(emailFromName: v),
  ),
  'custom_sending_email': (
    read: (s) => s.customSendingEmail,
    write: (s, v) => s.copyWith(customSendingEmail: v),
  ),
  'reply_to_email': (
    read: (s) => s.replyToEmail,
    write: (s, v) => s.copyWith(replyToEmail: v),
  ),
  'reply_to_name': (
    read: (s) => s.replyToName,
    write: (s, v) => s.copyWith(replyToName: v),
  ),
  'bcc_email': (
    read: (s) => s.bccEmail,
    write: (s, v) => s.copyWith(bccEmail: v),
  ),
  'entity_send_time': (
    read: (s) => s.entitySendTime?.toString(),
    write: (s, v) =>
        s.copyWith(entitySendTime: v == null ? null : int.tryParse(v)),
  ),
  'email_style': (
    read: (s) => s.emailStyle,
    write: (s, v) => s.copyWith(emailStyle: v),
  ),
  'email_alignment': (
    read: (s) => s.emailAlignment,
    write: (s, v) => s.copyWith(emailAlignment: v),
  ),
  'email_style_custom': (
    read: (s) => s.emailStyleCustom,
    write: (s, v) => s.copyWith(emailStyleCustom: v),
  ),
  'email_signature': (
    read: (s) => s.emailSignature,
    write: (s, v) => s.copyWith(emailSignature: v),
  ),
  'show_email_footer': (
    read: (s) => s.showEmailFooter?.toString(),
    write: (s, v) => s.copyWith(showEmailFooter: _parseBool(v)),
  ),
  'pdf_email_attachment': (
    read: (s) => s.pdfEmailAttachment?.toString(),
    write: (s, v) => s.copyWith(pdfEmailAttachment: _parseBool(v)),
  ),
  'document_email_attachment': (
    read: (s) => s.documentEmailAttachment?.toString(),
    write: (s, v) => s.copyWith(documentEmailAttachment: _parseBool(v)),
  ),
  'ubl_email_attachment': (
    read: (s) => s.ublEmailAttachment?.toString(),
    write: (s, v) => s.copyWith(ublEmailAttachment: _parseBool(v)),
  ),
  'enable_email_markup': (
    read: (s) => s.enableEmailMarkup?.toString(),
    write: (s, v) => s.copyWith(enableEmailMarkup: _parseBool(v)),
  ),
  'postmark_secret': (
    read: (s) => s.postmarkSecret,
    write: (s, v) => s.copyWith(postmarkSecret: v),
  ),
  'mailgun_secret': (
    read: (s) => s.mailgunSecret,
    write: (s, v) => s.copyWith(mailgunSecret: v),
  ),
  'mailgun_domain': (
    read: (s) => s.mailgunDomain,
    write: (s, v) => s.copyWith(mailgunDomain: v),
  ),
  'mailgun_endpoint': (
    read: (s) => s.mailgunEndpoint,
    write: (s, v) => s.copyWith(mailgunEndpoint: v),
  ),
  'brevo_secret': (
    read: (s) => s.brevoSecret,
    write: (s, v) => s.copyWith(brevoSecret: v),
  ),
  'ses_secret_key': (
    read: (s) => s.sesSecretKey,
    write: (s, v) => s.copyWith(sesSecretKey: v),
  ),
  'ses_access_key': (
    read: (s) => s.sesAccessKey,
    write: (s, v) => s.copyWith(sesAccessKey: v),
  ),
  'ses_region': (
    read: (s) => s.sesRegion,
    write: (s, v) => s.copyWith(sesRegion: v),
  ),
  'ses_topic_arn': (
    read: (s) => s.sesTopicArn,
    write: (s, v) => s.copyWith(sesTopicArn: v),
  ),
  'ses_from_address': (
    read: (s) => s.sesFromAddress,
    write: (s, v) => s.copyWith(sesFromAddress: v),
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
