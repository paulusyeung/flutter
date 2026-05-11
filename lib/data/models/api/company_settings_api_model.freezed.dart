// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_settings_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CompanySettingsApi _$CompanySettingsApiFromJson(Map<String, dynamic> json) {
  return _CompanySettingsApi.fromJson(json);
}

/// @nodoc
mixin _$CompanySettingsApi {
  // ── Identity / brand ────────────────────────────────────────────────
  String? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'company_logo')
  String? get companyLogo => throw _privateConstructorUsedError;
  @JsonKey(name: 'company_logo_size')
  String? get companyLogoSize => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address1 => throw _privateConstructorUsedError;
  String? get address2 => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'postal_code')
  String? get postalCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_id')
  String? get countryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vat_number')
  String? get vatNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_number')
  String? get idNumber => throw _privateConstructorUsedError;
  String? get classification => throw _privateConstructorUsedError;
  @JsonKey(name: 'qr_iban')
  String? get qrIban => throw _privateConstructorUsedError;
  @JsonKey(name: 'besr_id')
  String? get besrId => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value1')
  String? get customValue1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value2')
  String? get customValue2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value3')
  String? get customValue3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_value4')
  String? get customValue4 => throw _privateConstructorUsedError; // ── Localization ────────────────────────────────────────────────────
  @JsonKey(name: 'timezone_id')
  String? get timezoneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_format_id')
  String? get dateFormatId => throw _privateConstructorUsedError;
  @JsonKey(name: 'language_id')
  String? get languageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'currency_id')
  String? get currencyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'military_time')
  bool? get militaryTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_currency_code')
  bool? get showCurrencyCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'use_comma_as_decimal_place')
  bool? get useCommaAsDecimalPlace => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_month_of_year')
  String? get firstMonthOfYear => throw _privateConstructorUsedError; // ── Defaults: terms & footers ───────────────────────────────────────
  @JsonKey(name: 'invoice_terms')
  String? get invoiceTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'invoice_footer')
  String? get invoiceFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_terms')
  String? get quoteTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_footer')
  String? get quoteFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_terms')
  String? get creditTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_footer')
  String? get creditFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_terms')
  String? get purchaseOrderTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_footer')
  String? get purchaseOrderFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_public_notes')
  String? get purchaseOrderPublicNotes => throw _privateConstructorUsedError;
  @JsonKey(name: 'invoice_labels')
  String? get invoiceLabels => throw _privateConstructorUsedError; // ── Design ids ──────────────────────────────────────────────────────
  @JsonKey(name: 'invoice_design_id')
  String? get invoiceDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_design_id')
  String? get quoteDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_design_id')
  String? get creditDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_design_id')
  String? get purchaseOrderDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'statement_design_id')
  String? get statementDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_note_design_id')
  String? get deliveryNoteDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_receipt_design_id')
  String? get paymentReceiptDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_refund_design_id')
  String? get paymentRefundDesignId => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_design_id')
  String? get portalDesignId => throw _privateConstructorUsedError; // ── Numbering & counters ────────────────────────────────────────────
  @JsonKey(name: 'invoice_number_pattern')
  String? get invoiceNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'invoice_number_counter')
  int? get invoiceNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_invoice_number_pattern')
  String? get recurringInvoiceNumberPattern =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_invoice_number_counter')
  int? get recurringInvoiceNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_number_pattern')
  String? get quoteNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_number_counter')
  int? get quoteNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_quote_number_pattern')
  String? get recurringQuoteNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_quote_number_counter')
  int? get recurringQuoteNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_number_pattern')
  String? get clientNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_number_counter')
  int? get clientNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_number_pattern')
  String? get creditNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_number_counter')
  int? get creditNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_number_pattern')
  String? get taskNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_number_counter')
  int? get taskNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'expense_number_pattern')
  String? get expenseNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'expense_number_counter')
  int? get expenseNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_expense_number_pattern')
  String? get recurringExpenseNumberPattern =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_expense_number_counter')
  int? get recurringExpenseNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'vendor_number_pattern')
  String? get vendorNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'vendor_number_counter')
  int? get vendorNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'ticket_number_pattern')
  String? get ticketNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'ticket_number_counter')
  int? get ticketNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_number_pattern')
  String? get paymentNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_number_counter')
  int? get paymentNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_number_pattern')
  String? get projectNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_number_counter')
  int? get projectNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_number_pattern')
  String? get purchaseOrderNumberPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_order_number_counter')
  int? get purchaseOrderNumberCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'shared_invoice_quote_counter')
  bool? get sharedInvoiceQuoteCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'shared_invoice_credit_counter')
  bool? get sharedInvoiceCreditCounter => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurring_number_prefix')
  String? get recurringNumberPrefix => throw _privateConstructorUsedError;
  @JsonKey(name: 'reset_counter_frequency_id')
  int? get resetCounterFrequencyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'reset_counter_date')
  String? get resetCounterDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'counter_padding')
  int? get counterPadding => throw _privateConstructorUsedError;
  @JsonKey(name: 'counter_number_applied')
  String? get counterNumberApplied => throw _privateConstructorUsedError;
  @JsonKey(name: 'quote_number_applied')
  String? get quoteNumberApplied => throw _privateConstructorUsedError; // ── Taxes ───────────────────────────────────────────────────────────
  @JsonKey(name: 'tax_name1')
  String? get taxName1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_rate1')
  double? get taxRate1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_name2')
  String? get taxName2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_rate2')
  double? get taxRate2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_name3')
  String? get taxName3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'tax_rate3')
  double? get taxRate3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'invoice_taxes')
  int? get invoiceTaxes => throw _privateConstructorUsedError;
  @JsonKey(name: 'inclusive_taxes')
  bool? get inclusiveTaxes => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_rappen_rounding')
  bool? get enableRappenRounding => throw _privateConstructorUsedError; // ── Email config ────────────────────────────────────────────────────
  @JsonKey(name: 'email_sending_method')
  String? get emailSendingMethod => throw _privateConstructorUsedError;
  @JsonKey(name: 'gmail_sending_user_id')
  String? get gmailSendingUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'reply_to_email')
  String? get replyToEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'reply_to_name')
  String? get replyToName => throw _privateConstructorUsedError;
  @JsonKey(name: 'bcc_email')
  String? get bccEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_from_name')
  String? get emailFromName => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_sending_email')
  String? get customSendingEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_style')
  String? get emailStyle => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_style_custom')
  String? get emailStyleCustom => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_signature')
  String? get emailSignature => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_email_markup')
  bool? get enableEmailMarkup => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_email_footer')
  bool? get showEmailFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'pdf_email_attachment')
  bool? get pdfEmailAttachment => throw _privateConstructorUsedError;
  @JsonKey(name: 'ubl_email_attachment')
  bool? get ublEmailAttachment => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_email_attachment')
  bool? get documentEmailAttachment => throw _privateConstructorUsedError;
  @JsonKey(name: 'send_email_on_mark_paid')
  bool? get sendEmailOnMarkPaid => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_email_all_contacts')
  bool? get paymentEmailAllContacts => throw _privateConstructorUsedError; // Mail service secrets
  @JsonKey(name: 'postmark_secret')
  String? get postmarkSecret => throw _privateConstructorUsedError;
  @JsonKey(name: 'mailgun_secret')
  String? get mailgunSecret => throw _privateConstructorUsedError;
  @JsonKey(name: 'mailgun_domain')
  String? get mailgunDomain => throw _privateConstructorUsedError;
  @JsonKey(name: 'mailgun_endpoint')
  String? get mailgunEndpoint => throw _privateConstructorUsedError;
  @JsonKey(name: 'brevo_secret')
  String? get brevoSecret => throw _privateConstructorUsedError;
  @JsonKey(name: 'ses_secret_key')
  String? get sesSecretKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'ses_access_key')
  String? get sesAccessKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'ses_region')
  String? get sesRegion => throw _privateConstructorUsedError;
  @JsonKey(name: 'ses_topic_arn')
  String? get sesTopicArn => throw _privateConstructorUsedError;
  @JsonKey(name: 'ses_from_address')
  String? get sesFromAddress => throw _privateConstructorUsedError; // Email subjects (per entity)
  @JsonKey(name: 'email_subject_invoice')
  String? get emailSubjectInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_quote')
  String? get emailSubjectQuote => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_credit')
  String? get emailSubjectCredit => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_payment')
  String? get emailSubjectPayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_payment_partial')
  String? get emailSubjectPaymentPartial => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_statement')
  String? get emailSubjectStatement => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_purchase_order')
  String? get emailSubjectPurchaseOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_reminder1')
  String? get emailSubjectReminder1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_reminder2')
  String? get emailSubjectReminder2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_reminder3')
  String? get emailSubjectReminder3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_reminder_endless')
  String? get emailSubjectReminderEndless => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_custom1')
  String? get emailSubjectCustom1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_custom2')
  String? get emailSubjectCustom2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_subject_custom3')
  String? get emailSubjectCustom3 => throw _privateConstructorUsedError; // Email templates (per entity)
  @JsonKey(name: 'email_template_invoice')
  String? get emailTemplateInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_quote')
  String? get emailTemplateQuote => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_credit')
  String? get emailTemplateCredit => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_payment')
  String? get emailTemplatePayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_payment_partial')
  String? get emailTemplatePaymentPartial => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_statement')
  String? get emailTemplateStatement => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_purchase_order')
  String? get emailTemplatePurchaseOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_reminder1')
  String? get emailTemplateReminder1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_reminder2')
  String? get emailTemplateReminder2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_reminder3')
  String? get emailTemplateReminder3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_reminder_endless')
  String? get emailTemplateReminderEndless =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_custom1')
  String? get emailTemplateCustom1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_custom2')
  String? get emailTemplateCustom2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_template_custom3')
  String? get emailTemplateCustom3 => throw _privateConstructorUsedError; // ── Reminders ───────────────────────────────────────────────────────
  @JsonKey(name: 'send_reminders')
  bool? get sendReminders => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_reminder1')
  bool? get enableReminder1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_reminder2')
  bool? get enableReminder2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_reminder3')
  bool? get enableReminder3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_reminder_endless')
  bool? get enableReminderEndless => throw _privateConstructorUsedError;
  @JsonKey(name: 'num_days_reminder1')
  int? get numDaysReminder1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'num_days_reminder2')
  int? get numDaysReminder2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'num_days_reminder3')
  int? get numDaysReminder3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'schedule_reminder1')
  String? get scheduleReminder1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'schedule_reminder2')
  String? get scheduleReminder2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'schedule_reminder3')
  String? get scheduleReminder3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_send_time')
  int? get reminderSendTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_amount1')
  double? get lateFeeAmount1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_amount2')
  double? get lateFeeAmount2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_amount3')
  double? get lateFeeAmount3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_percent1')
  double? get lateFeePercent1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_percent2')
  double? get lateFeePercent2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_percent3')
  double? get lateFeePercent3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'endless_reminder_frequency_id')
  String? get endlessReminderFrequencyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_endless_amount')
  double? get lateFeeEndlessAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'late_fee_endless_percent')
  double? get lateFeeEndlessPercent => throw _privateConstructorUsedError; // ── Invoice / quote behavior ───────────────────────────────────────
  @JsonKey(name: 'auto_archive_invoice')
  bool? get autoArchiveInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_archive_invoice_cancelled')
  bool? get autoArchiveInvoiceCancelled => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_archive_quote')
  bool? get autoArchiveQuote => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_convert_quote')
  bool? get autoConvertQuote => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_email_invoice')
  bool? get autoEmailInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_bill_standard_invoices')
  bool? get autoBillStandardInvoices => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_bill')
  String? get autoBill => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_bill_date')
  String? get autoBillDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'lock_invoices')
  String? get lockInvoices => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_send_time')
  int? get entitySendTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_accept_invoice_terms')
  bool? get showAcceptInvoiceTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_accept_quote_terms')
  bool? get showAcceptQuoteTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'require_invoice_signature')
  bool? get requireInvoiceSignature => throw _privateConstructorUsedError;
  @JsonKey(name: 'require_quote_signature')
  bool? get requireQuoteSignature => throw _privateConstructorUsedError;
  @JsonKey(name: 'require_purchase_order_signature')
  bool? get requirePurchaseOrderSignature => throw _privateConstructorUsedError;
  @JsonKey(name: 'signature_on_pdf')
  bool? get signatureOnPdf => throw _privateConstructorUsedError;
  @JsonKey(name: 'accept_client_input_quote_approval')
  bool? get acceptClientInputQuoteApproval =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'sync_invoice_quote_columns')
  bool? get syncInvoiceQuoteColumns => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_shipping_address')
  bool? get showShippingAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_paid_stamp')
  bool? get showPaidStamp => throw _privateConstructorUsedError; // ── PDF / page layout ──────────────────────────────────────────────
  @JsonKey(name: 'page_size')
  String? get pageSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_layout')
  String? get pageLayout => throw _privateConstructorUsedError;
  @JsonKey(name: 'font_size')
  int? get fontSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_font')
  String? get primaryFont => throw _privateConstructorUsedError;
  @JsonKey(name: 'secondary_font')
  String? get secondaryFont => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_color')
  String? get primaryColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_numbering')
  bool? get pageNumbering => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_numbering_alignment')
  String? get pageNumberingAlignment => throw _privateConstructorUsedError;
  @JsonKey(name: 'hide_paid_to_date')
  bool? get hidePaidToDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'hide_empty_columns_on_pdf')
  bool? get hideEmptyColumnsOnPdf => throw _privateConstructorUsedError;
  @JsonKey(name: 'embed_documents')
  bool? get embedDocuments => throw _privateConstructorUsedError;
  @JsonKey(name: 'all_pages_header')
  bool? get allPagesHeader => throw _privateConstructorUsedError;
  @JsonKey(name: 'all_pages_footer')
  bool? get allPagesFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'pdf_variables')
  Map<String, List<String>>? get pdfVariables =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'show_pdfhtml_on_mobile')
  bool? get showPdfhtmlOnMobile => throw _privateConstructorUsedError; // ── Portal ─────────────────────────────────────────────────────────
  @JsonKey(name: 'enable_client_portal')
  bool? get enableClientPortal => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_client_portal_dashboard')
  bool? get enableClientPortalDashboard => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_client_portal_tasks')
  bool? get enableClientPortalTasks => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_all_tasks_client_portal')
  String? get showAllTasksClientPortal => throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_client_portal_password')
  bool? get enableClientPortalPassword => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_terms')
  String? get clientPortalTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_privacy_policy')
  String? get clientPortalPrivacyPolicy => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_enable_uploads')
  bool? get clientPortalEnableUploads => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_allow_under_payment')
  bool? get clientPortalAllowUnderPayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_under_payment_minimum')
  double? get clientPortalUnderPaymentMinimum =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'client_portal_allow_over_payment')
  bool? get clientPortalAllowOverPayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_custom_head')
  String? get portalCustomHead => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_custom_css')
  String? get portalCustomCss => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_custom_footer')
  String? get portalCustomFooter => throw _privateConstructorUsedError;
  @JsonKey(name: 'portal_custom_js')
  String? get portalCustomJs => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_can_register')
  bool? get clientCanRegister => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_initiated_payments')
  bool? get clientInitiatedPayments => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_initiated_payments_minimum')
  double? get clientInitiatedPaymentsMinimum =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'enable_client_profile_update')
  bool? get enableClientProfileUpdate => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_online_payment_notification')
  bool? get clientOnlinePaymentNotification =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'client_manual_payment_notification')
  bool? get clientManualPaymentNotification =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'vendor_portal_enable_uploads')
  bool? get vendorPortalEnableUploads => throw _privateConstructorUsedError;
  @JsonKey(name: 'use_credits_payment')
  String? get useCreditsPayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'use_unapplied_payment')
  String? get useUnappliedPayment => throw _privateConstructorUsedError; // ── Payments / billing ─────────────────────────────────────────────
  @JsonKey(name: 'payment_terms')
  String? get paymentTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'valid_until')
  String? get validUntil => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_type_id')
  String? get paymentTypeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_expense_payment_type_id')
  String? get defaultExpensePaymentTypeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'company_gateway_ids')
  String? get companyGatewayIds => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_flow')
  String? get paymentFlow => throw _privateConstructorUsedError;
  @JsonKey(name: 'unlock_invoice_documents_after_payment')
  bool? get unlockInvoiceDocumentsAfterPayment =>
      throw _privateConstructorUsedError; // ── Tasks ──────────────────────────────────────────────────────────
  @JsonKey(name: 'show_task_item_description')
  bool? get showTaskItemDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'allow_billable_task_items')
  bool? get allowBillableTaskItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_task_rate')
  double? get defaultTaskRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_round_up')
  bool? get taskRoundUp => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_round_to_nearest')
  double? get taskRoundToNearest => throw _privateConstructorUsedError; // ── e-Invoice ──────────────────────────────────────────────────────
  @JsonKey(name: 'enable_e_invoice')
  bool? get enableEInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'e_invoice_type')
  String? get eInvoiceType => throw _privateConstructorUsedError;
  @JsonKey(name: 'e_quote_type')
  String? get eQuoteType => throw _privateConstructorUsedError;
  @JsonKey(name: 'merge_e_invoice_to_pdf')
  bool? get mergeEInvoiceToPdf => throw _privateConstructorUsedError;
  @JsonKey(name: 'skip_automatic_email_with_peppol')
  bool? get skipAutomaticEmailWithPeppol => throw _privateConstructorUsedError;
  @JsonKey(name: 'e_invoice_forward_email')
  String? get eInvoiceForwardEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'e_expense_forward_email')
  String? get eExpenseForwardEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'preference_product_notes_for_html_view')
  bool? get preferenceProductNotesForHtmlView =>
      throw _privateConstructorUsedError; // ── Dashboard / messages ───────────────────────────────────────────
  @JsonKey(name: 'custom_message_dashboard')
  String? get customMessageDashboard => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_message_unpaid_invoice')
  String? get customMessageUnpaidInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_message_paid_invoice')
  String? get customMessagePaidInvoice => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_message_unapproved_quote')
  String? get customMessageUnapprovedQuote =>
      throw _privateConstructorUsedError; // ── Misc ───────────────────────────────────────────────────────────
  List<dynamic>? get translations => throw _privateConstructorUsedError;

  /// Serializes this CompanySettingsApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanySettingsApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanySettingsApiCopyWith<CompanySettingsApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanySettingsApiCopyWith<$Res> {
  factory $CompanySettingsApiCopyWith(
    CompanySettingsApi value,
    $Res Function(CompanySettingsApi) then,
  ) = _$CompanySettingsApiCopyWithImpl<$Res, CompanySettingsApi>;
  @useResult
  $Res call({
    String? id,
    String? name,
    @JsonKey(name: 'company_logo') String? companyLogo,
    @JsonKey(name: 'company_logo_size') String? companyLogoSize,
    String? website,
    String? phone,
    String? email,
    String? address1,
    String? address2,
    String? city,
    String? state,
    @JsonKey(name: 'postal_code') String? postalCode,
    @JsonKey(name: 'country_id') String? countryId,
    @JsonKey(name: 'vat_number') String? vatNumber,
    @JsonKey(name: 'id_number') String? idNumber,
    String? classification,
    @JsonKey(name: 'qr_iban') String? qrIban,
    @JsonKey(name: 'besr_id') String? besrId,
    @JsonKey(name: 'custom_value1') String? customValue1,
    @JsonKey(name: 'custom_value2') String? customValue2,
    @JsonKey(name: 'custom_value3') String? customValue3,
    @JsonKey(name: 'custom_value4') String? customValue4,
    @JsonKey(name: 'timezone_id') String? timezoneId,
    @JsonKey(name: 'date_format_id') String? dateFormatId,
    @JsonKey(name: 'language_id') String? languageId,
    @JsonKey(name: 'currency_id') String? currencyId,
    @JsonKey(name: 'military_time') bool? militaryTime,
    @JsonKey(name: 'show_currency_code') bool? showCurrencyCode,
    @JsonKey(name: 'use_comma_as_decimal_place') bool? useCommaAsDecimalPlace,
    @JsonKey(name: 'first_month_of_year') String? firstMonthOfYear,
    @JsonKey(name: 'invoice_terms') String? invoiceTerms,
    @JsonKey(name: 'invoice_footer') String? invoiceFooter,
    @JsonKey(name: 'quote_terms') String? quoteTerms,
    @JsonKey(name: 'quote_footer') String? quoteFooter,
    @JsonKey(name: 'credit_terms') String? creditTerms,
    @JsonKey(name: 'credit_footer') String? creditFooter,
    @JsonKey(name: 'purchase_order_terms') String? purchaseOrderTerms,
    @JsonKey(name: 'purchase_order_footer') String? purchaseOrderFooter,
    @JsonKey(name: 'purchase_order_public_notes')
    String? purchaseOrderPublicNotes,
    @JsonKey(name: 'invoice_labels') String? invoiceLabels,
    @JsonKey(name: 'invoice_design_id') String? invoiceDesignId,
    @JsonKey(name: 'quote_design_id') String? quoteDesignId,
    @JsonKey(name: 'credit_design_id') String? creditDesignId,
    @JsonKey(name: 'purchase_order_design_id') String? purchaseOrderDesignId,
    @JsonKey(name: 'statement_design_id') String? statementDesignId,
    @JsonKey(name: 'delivery_note_design_id') String? deliveryNoteDesignId,
    @JsonKey(name: 'payment_receipt_design_id') String? paymentReceiptDesignId,
    @JsonKey(name: 'payment_refund_design_id') String? paymentRefundDesignId,
    @JsonKey(name: 'portal_design_id') String? portalDesignId,
    @JsonKey(name: 'invoice_number_pattern') String? invoiceNumberPattern,
    @JsonKey(name: 'invoice_number_counter') int? invoiceNumberCounter,
    @JsonKey(name: 'recurring_invoice_number_pattern')
    String? recurringInvoiceNumberPattern,
    @JsonKey(name: 'recurring_invoice_number_counter')
    int? recurringInvoiceNumberCounter,
    @JsonKey(name: 'quote_number_pattern') String? quoteNumberPattern,
    @JsonKey(name: 'quote_number_counter') int? quoteNumberCounter,
    @JsonKey(name: 'recurring_quote_number_pattern')
    String? recurringQuoteNumberPattern,
    @JsonKey(name: 'recurring_quote_number_counter')
    int? recurringQuoteNumberCounter,
    @JsonKey(name: 'client_number_pattern') String? clientNumberPattern,
    @JsonKey(name: 'client_number_counter') int? clientNumberCounter,
    @JsonKey(name: 'credit_number_pattern') String? creditNumberPattern,
    @JsonKey(name: 'credit_number_counter') int? creditNumberCounter,
    @JsonKey(name: 'task_number_pattern') String? taskNumberPattern,
    @JsonKey(name: 'task_number_counter') int? taskNumberCounter,
    @JsonKey(name: 'expense_number_pattern') String? expenseNumberPattern,
    @JsonKey(name: 'expense_number_counter') int? expenseNumberCounter,
    @JsonKey(name: 'recurring_expense_number_pattern')
    String? recurringExpenseNumberPattern,
    @JsonKey(name: 'recurring_expense_number_counter')
    int? recurringExpenseNumberCounter,
    @JsonKey(name: 'vendor_number_pattern') String? vendorNumberPattern,
    @JsonKey(name: 'vendor_number_counter') int? vendorNumberCounter,
    @JsonKey(name: 'ticket_number_pattern') String? ticketNumberPattern,
    @JsonKey(name: 'ticket_number_counter') int? ticketNumberCounter,
    @JsonKey(name: 'payment_number_pattern') String? paymentNumberPattern,
    @JsonKey(name: 'payment_number_counter') int? paymentNumberCounter,
    @JsonKey(name: 'project_number_pattern') String? projectNumberPattern,
    @JsonKey(name: 'project_number_counter') int? projectNumberCounter,
    @JsonKey(name: 'purchase_order_number_pattern')
    String? purchaseOrderNumberPattern,
    @JsonKey(name: 'purchase_order_number_counter')
    int? purchaseOrderNumberCounter,
    @JsonKey(name: 'shared_invoice_quote_counter')
    bool? sharedInvoiceQuoteCounter,
    @JsonKey(name: 'shared_invoice_credit_counter')
    bool? sharedInvoiceCreditCounter,
    @JsonKey(name: 'recurring_number_prefix') String? recurringNumberPrefix,
    @JsonKey(name: 'reset_counter_frequency_id') int? resetCounterFrequencyId,
    @JsonKey(name: 'reset_counter_date') String? resetCounterDate,
    @JsonKey(name: 'counter_padding') int? counterPadding,
    @JsonKey(name: 'counter_number_applied') String? counterNumberApplied,
    @JsonKey(name: 'quote_number_applied') String? quoteNumberApplied,
    @JsonKey(name: 'tax_name1') String? taxName1,
    @JsonKey(name: 'tax_rate1') double? taxRate1,
    @JsonKey(name: 'tax_name2') String? taxName2,
    @JsonKey(name: 'tax_rate2') double? taxRate2,
    @JsonKey(name: 'tax_name3') String? taxName3,
    @JsonKey(name: 'tax_rate3') double? taxRate3,
    @JsonKey(name: 'invoice_taxes') int? invoiceTaxes,
    @JsonKey(name: 'inclusive_taxes') bool? inclusiveTaxes,
    @JsonKey(name: 'enable_rappen_rounding') bool? enableRappenRounding,
    @JsonKey(name: 'email_sending_method') String? emailSendingMethod,
    @JsonKey(name: 'gmail_sending_user_id') String? gmailSendingUserId,
    @JsonKey(name: 'reply_to_email') String? replyToEmail,
    @JsonKey(name: 'reply_to_name') String? replyToName,
    @JsonKey(name: 'bcc_email') String? bccEmail,
    @JsonKey(name: 'email_from_name') String? emailFromName,
    @JsonKey(name: 'custom_sending_email') String? customSendingEmail,
    @JsonKey(name: 'email_style') String? emailStyle,
    @JsonKey(name: 'email_style_custom') String? emailStyleCustom,
    @JsonKey(name: 'email_signature') String? emailSignature,
    @JsonKey(name: 'enable_email_markup') bool? enableEmailMarkup,
    @JsonKey(name: 'show_email_footer') bool? showEmailFooter,
    @JsonKey(name: 'pdf_email_attachment') bool? pdfEmailAttachment,
    @JsonKey(name: 'ubl_email_attachment') bool? ublEmailAttachment,
    @JsonKey(name: 'document_email_attachment') bool? documentEmailAttachment,
    @JsonKey(name: 'send_email_on_mark_paid') bool? sendEmailOnMarkPaid,
    @JsonKey(name: 'payment_email_all_contacts') bool? paymentEmailAllContacts,
    @JsonKey(name: 'postmark_secret') String? postmarkSecret,
    @JsonKey(name: 'mailgun_secret') String? mailgunSecret,
    @JsonKey(name: 'mailgun_domain') String? mailgunDomain,
    @JsonKey(name: 'mailgun_endpoint') String? mailgunEndpoint,
    @JsonKey(name: 'brevo_secret') String? brevoSecret,
    @JsonKey(name: 'ses_secret_key') String? sesSecretKey,
    @JsonKey(name: 'ses_access_key') String? sesAccessKey,
    @JsonKey(name: 'ses_region') String? sesRegion,
    @JsonKey(name: 'ses_topic_arn') String? sesTopicArn,
    @JsonKey(name: 'ses_from_address') String? sesFromAddress,
    @JsonKey(name: 'email_subject_invoice') String? emailSubjectInvoice,
    @JsonKey(name: 'email_subject_quote') String? emailSubjectQuote,
    @JsonKey(name: 'email_subject_credit') String? emailSubjectCredit,
    @JsonKey(name: 'email_subject_payment') String? emailSubjectPayment,
    @JsonKey(name: 'email_subject_payment_partial')
    String? emailSubjectPaymentPartial,
    @JsonKey(name: 'email_subject_statement') String? emailSubjectStatement,
    @JsonKey(name: 'email_subject_purchase_order')
    String? emailSubjectPurchaseOrder,
    @JsonKey(name: 'email_subject_reminder1') String? emailSubjectReminder1,
    @JsonKey(name: 'email_subject_reminder2') String? emailSubjectReminder2,
    @JsonKey(name: 'email_subject_reminder3') String? emailSubjectReminder3,
    @JsonKey(name: 'email_subject_reminder_endless')
    String? emailSubjectReminderEndless,
    @JsonKey(name: 'email_subject_custom1') String? emailSubjectCustom1,
    @JsonKey(name: 'email_subject_custom2') String? emailSubjectCustom2,
    @JsonKey(name: 'email_subject_custom3') String? emailSubjectCustom3,
    @JsonKey(name: 'email_template_invoice') String? emailTemplateInvoice,
    @JsonKey(name: 'email_template_quote') String? emailTemplateQuote,
    @JsonKey(name: 'email_template_credit') String? emailTemplateCredit,
    @JsonKey(name: 'email_template_payment') String? emailTemplatePayment,
    @JsonKey(name: 'email_template_payment_partial')
    String? emailTemplatePaymentPartial,
    @JsonKey(name: 'email_template_statement') String? emailTemplateStatement,
    @JsonKey(name: 'email_template_purchase_order')
    String? emailTemplatePurchaseOrder,
    @JsonKey(name: 'email_template_reminder1') String? emailTemplateReminder1,
    @JsonKey(name: 'email_template_reminder2') String? emailTemplateReminder2,
    @JsonKey(name: 'email_template_reminder3') String? emailTemplateReminder3,
    @JsonKey(name: 'email_template_reminder_endless')
    String? emailTemplateReminderEndless,
    @JsonKey(name: 'email_template_custom1') String? emailTemplateCustom1,
    @JsonKey(name: 'email_template_custom2') String? emailTemplateCustom2,
    @JsonKey(name: 'email_template_custom3') String? emailTemplateCustom3,
    @JsonKey(name: 'send_reminders') bool? sendReminders,
    @JsonKey(name: 'enable_reminder1') bool? enableReminder1,
    @JsonKey(name: 'enable_reminder2') bool? enableReminder2,
    @JsonKey(name: 'enable_reminder3') bool? enableReminder3,
    @JsonKey(name: 'enable_reminder_endless') bool? enableReminderEndless,
    @JsonKey(name: 'num_days_reminder1') int? numDaysReminder1,
    @JsonKey(name: 'num_days_reminder2') int? numDaysReminder2,
    @JsonKey(name: 'num_days_reminder3') int? numDaysReminder3,
    @JsonKey(name: 'schedule_reminder1') String? scheduleReminder1,
    @JsonKey(name: 'schedule_reminder2') String? scheduleReminder2,
    @JsonKey(name: 'schedule_reminder3') String? scheduleReminder3,
    @JsonKey(name: 'reminder_send_time') int? reminderSendTime,
    @JsonKey(name: 'late_fee_amount1') double? lateFeeAmount1,
    @JsonKey(name: 'late_fee_amount2') double? lateFeeAmount2,
    @JsonKey(name: 'late_fee_amount3') double? lateFeeAmount3,
    @JsonKey(name: 'late_fee_percent1') double? lateFeePercent1,
    @JsonKey(name: 'late_fee_percent2') double? lateFeePercent2,
    @JsonKey(name: 'late_fee_percent3') double? lateFeePercent3,
    @JsonKey(name: 'endless_reminder_frequency_id')
    String? endlessReminderFrequencyId,
    @JsonKey(name: 'late_fee_endless_amount') double? lateFeeEndlessAmount,
    @JsonKey(name: 'late_fee_endless_percent') double? lateFeeEndlessPercent,
    @JsonKey(name: 'auto_archive_invoice') bool? autoArchiveInvoice,
    @JsonKey(name: 'auto_archive_invoice_cancelled')
    bool? autoArchiveInvoiceCancelled,
    @JsonKey(name: 'auto_archive_quote') bool? autoArchiveQuote,
    @JsonKey(name: 'auto_convert_quote') bool? autoConvertQuote,
    @JsonKey(name: 'auto_email_invoice') bool? autoEmailInvoice,
    @JsonKey(name: 'auto_bill_standard_invoices')
    bool? autoBillStandardInvoices,
    @JsonKey(name: 'auto_bill') String? autoBill,
    @JsonKey(name: 'auto_bill_date') String? autoBillDate,
    @JsonKey(name: 'lock_invoices') String? lockInvoices,
    @JsonKey(name: 'entity_send_time') int? entitySendTime,
    @JsonKey(name: 'show_accept_invoice_terms') bool? showAcceptInvoiceTerms,
    @JsonKey(name: 'show_accept_quote_terms') bool? showAcceptQuoteTerms,
    @JsonKey(name: 'require_invoice_signature') bool? requireInvoiceSignature,
    @JsonKey(name: 'require_quote_signature') bool? requireQuoteSignature,
    @JsonKey(name: 'require_purchase_order_signature')
    bool? requirePurchaseOrderSignature,
    @JsonKey(name: 'signature_on_pdf') bool? signatureOnPdf,
    @JsonKey(name: 'accept_client_input_quote_approval')
    bool? acceptClientInputQuoteApproval,
    @JsonKey(name: 'sync_invoice_quote_columns') bool? syncInvoiceQuoteColumns,
    @JsonKey(name: 'show_shipping_address') bool? showShippingAddress,
    @JsonKey(name: 'show_paid_stamp') bool? showPaidStamp,
    @JsonKey(name: 'page_size') String? pageSize,
    @JsonKey(name: 'page_layout') String? pageLayout,
    @JsonKey(name: 'font_size') int? fontSize,
    @JsonKey(name: 'primary_font') String? primaryFont,
    @JsonKey(name: 'secondary_font') String? secondaryFont,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'page_numbering') bool? pageNumbering,
    @JsonKey(name: 'page_numbering_alignment') String? pageNumberingAlignment,
    @JsonKey(name: 'hide_paid_to_date') bool? hidePaidToDate,
    @JsonKey(name: 'hide_empty_columns_on_pdf') bool? hideEmptyColumnsOnPdf,
    @JsonKey(name: 'embed_documents') bool? embedDocuments,
    @JsonKey(name: 'all_pages_header') bool? allPagesHeader,
    @JsonKey(name: 'all_pages_footer') bool? allPagesFooter,
    @JsonKey(name: 'pdf_variables') Map<String, List<String>>? pdfVariables,
    @JsonKey(name: 'show_pdfhtml_on_mobile') bool? showPdfhtmlOnMobile,
    @JsonKey(name: 'enable_client_portal') bool? enableClientPortal,
    @JsonKey(name: 'enable_client_portal_dashboard')
    bool? enableClientPortalDashboard,
    @JsonKey(name: 'enable_client_portal_tasks') bool? enableClientPortalTasks,
    @JsonKey(name: 'show_all_tasks_client_portal')
    String? showAllTasksClientPortal,
    @JsonKey(name: 'enable_client_portal_password')
    bool? enableClientPortalPassword,
    @JsonKey(name: 'client_portal_terms') String? clientPortalTerms,
    @JsonKey(name: 'client_portal_privacy_policy')
    String? clientPortalPrivacyPolicy,
    @JsonKey(name: 'client_portal_enable_uploads')
    bool? clientPortalEnableUploads,
    @JsonKey(name: 'client_portal_allow_under_payment')
    bool? clientPortalAllowUnderPayment,
    @JsonKey(name: 'client_portal_under_payment_minimum')
    double? clientPortalUnderPaymentMinimum,
    @JsonKey(name: 'client_portal_allow_over_payment')
    bool? clientPortalAllowOverPayment,
    @JsonKey(name: 'portal_custom_head') String? portalCustomHead,
    @JsonKey(name: 'portal_custom_css') String? portalCustomCss,
    @JsonKey(name: 'portal_custom_footer') String? portalCustomFooter,
    @JsonKey(name: 'portal_custom_js') String? portalCustomJs,
    @JsonKey(name: 'client_can_register') bool? clientCanRegister,
    @JsonKey(name: 'client_initiated_payments') bool? clientInitiatedPayments,
    @JsonKey(name: 'client_initiated_payments_minimum')
    double? clientInitiatedPaymentsMinimum,
    @JsonKey(name: 'enable_client_profile_update')
    bool? enableClientProfileUpdate,
    @JsonKey(name: 'client_online_payment_notification')
    bool? clientOnlinePaymentNotification,
    @JsonKey(name: 'client_manual_payment_notification')
    bool? clientManualPaymentNotification,
    @JsonKey(name: 'vendor_portal_enable_uploads')
    bool? vendorPortalEnableUploads,
    @JsonKey(name: 'use_credits_payment') String? useCreditsPayment,
    @JsonKey(name: 'use_unapplied_payment') String? useUnappliedPayment,
    @JsonKey(name: 'payment_terms') String? paymentTerms,
    @JsonKey(name: 'valid_until') String? validUntil,
    @JsonKey(name: 'payment_type_id') String? paymentTypeId,
    @JsonKey(name: 'default_expense_payment_type_id')
    String? defaultExpensePaymentTypeId,
    @JsonKey(name: 'company_gateway_ids') String? companyGatewayIds,
    @JsonKey(name: 'payment_flow') String? paymentFlow,
    @JsonKey(name: 'unlock_invoice_documents_after_payment')
    bool? unlockInvoiceDocumentsAfterPayment,
    @JsonKey(name: 'show_task_item_description') bool? showTaskItemDescription,
    @JsonKey(name: 'allow_billable_task_items') bool? allowBillableTaskItems,
    @JsonKey(name: 'default_task_rate') double? defaultTaskRate,
    @JsonKey(name: 'task_round_up') bool? taskRoundUp,
    @JsonKey(name: 'task_round_to_nearest') double? taskRoundToNearest,
    @JsonKey(name: 'enable_e_invoice') bool? enableEInvoice,
    @JsonKey(name: 'e_invoice_type') String? eInvoiceType,
    @JsonKey(name: 'e_quote_type') String? eQuoteType,
    @JsonKey(name: 'merge_e_invoice_to_pdf') bool? mergeEInvoiceToPdf,
    @JsonKey(name: 'skip_automatic_email_with_peppol')
    bool? skipAutomaticEmailWithPeppol,
    @JsonKey(name: 'e_invoice_forward_email') String? eInvoiceForwardEmail,
    @JsonKey(name: 'e_expense_forward_email') String? eExpenseForwardEmail,
    @JsonKey(name: 'preference_product_notes_for_html_view')
    bool? preferenceProductNotesForHtmlView,
    @JsonKey(name: 'custom_message_dashboard') String? customMessageDashboard,
    @JsonKey(name: 'custom_message_unpaid_invoice')
    String? customMessageUnpaidInvoice,
    @JsonKey(name: 'custom_message_paid_invoice')
    String? customMessagePaidInvoice,
    @JsonKey(name: 'custom_message_unapproved_quote')
    String? customMessageUnapprovedQuote,
    List<dynamic>? translations,
  });
}

/// @nodoc
class _$CompanySettingsApiCopyWithImpl<$Res, $Val extends CompanySettingsApi>
    implements $CompanySettingsApiCopyWith<$Res> {
  _$CompanySettingsApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanySettingsApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? companyLogo = freezed,
    Object? companyLogoSize = freezed,
    Object? website = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address1 = freezed,
    Object? address2 = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? postalCode = freezed,
    Object? countryId = freezed,
    Object? vatNumber = freezed,
    Object? idNumber = freezed,
    Object? classification = freezed,
    Object? qrIban = freezed,
    Object? besrId = freezed,
    Object? customValue1 = freezed,
    Object? customValue2 = freezed,
    Object? customValue3 = freezed,
    Object? customValue4 = freezed,
    Object? timezoneId = freezed,
    Object? dateFormatId = freezed,
    Object? languageId = freezed,
    Object? currencyId = freezed,
    Object? militaryTime = freezed,
    Object? showCurrencyCode = freezed,
    Object? useCommaAsDecimalPlace = freezed,
    Object? firstMonthOfYear = freezed,
    Object? invoiceTerms = freezed,
    Object? invoiceFooter = freezed,
    Object? quoteTerms = freezed,
    Object? quoteFooter = freezed,
    Object? creditTerms = freezed,
    Object? creditFooter = freezed,
    Object? purchaseOrderTerms = freezed,
    Object? purchaseOrderFooter = freezed,
    Object? purchaseOrderPublicNotes = freezed,
    Object? invoiceLabels = freezed,
    Object? invoiceDesignId = freezed,
    Object? quoteDesignId = freezed,
    Object? creditDesignId = freezed,
    Object? purchaseOrderDesignId = freezed,
    Object? statementDesignId = freezed,
    Object? deliveryNoteDesignId = freezed,
    Object? paymentReceiptDesignId = freezed,
    Object? paymentRefundDesignId = freezed,
    Object? portalDesignId = freezed,
    Object? invoiceNumberPattern = freezed,
    Object? invoiceNumberCounter = freezed,
    Object? recurringInvoiceNumberPattern = freezed,
    Object? recurringInvoiceNumberCounter = freezed,
    Object? quoteNumberPattern = freezed,
    Object? quoteNumberCounter = freezed,
    Object? recurringQuoteNumberPattern = freezed,
    Object? recurringQuoteNumberCounter = freezed,
    Object? clientNumberPattern = freezed,
    Object? clientNumberCounter = freezed,
    Object? creditNumberPattern = freezed,
    Object? creditNumberCounter = freezed,
    Object? taskNumberPattern = freezed,
    Object? taskNumberCounter = freezed,
    Object? expenseNumberPattern = freezed,
    Object? expenseNumberCounter = freezed,
    Object? recurringExpenseNumberPattern = freezed,
    Object? recurringExpenseNumberCounter = freezed,
    Object? vendorNumberPattern = freezed,
    Object? vendorNumberCounter = freezed,
    Object? ticketNumberPattern = freezed,
    Object? ticketNumberCounter = freezed,
    Object? paymentNumberPattern = freezed,
    Object? paymentNumberCounter = freezed,
    Object? projectNumberPattern = freezed,
    Object? projectNumberCounter = freezed,
    Object? purchaseOrderNumberPattern = freezed,
    Object? purchaseOrderNumberCounter = freezed,
    Object? sharedInvoiceQuoteCounter = freezed,
    Object? sharedInvoiceCreditCounter = freezed,
    Object? recurringNumberPrefix = freezed,
    Object? resetCounterFrequencyId = freezed,
    Object? resetCounterDate = freezed,
    Object? counterPadding = freezed,
    Object? counterNumberApplied = freezed,
    Object? quoteNumberApplied = freezed,
    Object? taxName1 = freezed,
    Object? taxRate1 = freezed,
    Object? taxName2 = freezed,
    Object? taxRate2 = freezed,
    Object? taxName3 = freezed,
    Object? taxRate3 = freezed,
    Object? invoiceTaxes = freezed,
    Object? inclusiveTaxes = freezed,
    Object? enableRappenRounding = freezed,
    Object? emailSendingMethod = freezed,
    Object? gmailSendingUserId = freezed,
    Object? replyToEmail = freezed,
    Object? replyToName = freezed,
    Object? bccEmail = freezed,
    Object? emailFromName = freezed,
    Object? customSendingEmail = freezed,
    Object? emailStyle = freezed,
    Object? emailStyleCustom = freezed,
    Object? emailSignature = freezed,
    Object? enableEmailMarkup = freezed,
    Object? showEmailFooter = freezed,
    Object? pdfEmailAttachment = freezed,
    Object? ublEmailAttachment = freezed,
    Object? documentEmailAttachment = freezed,
    Object? sendEmailOnMarkPaid = freezed,
    Object? paymentEmailAllContacts = freezed,
    Object? postmarkSecret = freezed,
    Object? mailgunSecret = freezed,
    Object? mailgunDomain = freezed,
    Object? mailgunEndpoint = freezed,
    Object? brevoSecret = freezed,
    Object? sesSecretKey = freezed,
    Object? sesAccessKey = freezed,
    Object? sesRegion = freezed,
    Object? sesTopicArn = freezed,
    Object? sesFromAddress = freezed,
    Object? emailSubjectInvoice = freezed,
    Object? emailSubjectQuote = freezed,
    Object? emailSubjectCredit = freezed,
    Object? emailSubjectPayment = freezed,
    Object? emailSubjectPaymentPartial = freezed,
    Object? emailSubjectStatement = freezed,
    Object? emailSubjectPurchaseOrder = freezed,
    Object? emailSubjectReminder1 = freezed,
    Object? emailSubjectReminder2 = freezed,
    Object? emailSubjectReminder3 = freezed,
    Object? emailSubjectReminderEndless = freezed,
    Object? emailSubjectCustom1 = freezed,
    Object? emailSubjectCustom2 = freezed,
    Object? emailSubjectCustom3 = freezed,
    Object? emailTemplateInvoice = freezed,
    Object? emailTemplateQuote = freezed,
    Object? emailTemplateCredit = freezed,
    Object? emailTemplatePayment = freezed,
    Object? emailTemplatePaymentPartial = freezed,
    Object? emailTemplateStatement = freezed,
    Object? emailTemplatePurchaseOrder = freezed,
    Object? emailTemplateReminder1 = freezed,
    Object? emailTemplateReminder2 = freezed,
    Object? emailTemplateReminder3 = freezed,
    Object? emailTemplateReminderEndless = freezed,
    Object? emailTemplateCustom1 = freezed,
    Object? emailTemplateCustom2 = freezed,
    Object? emailTemplateCustom3 = freezed,
    Object? sendReminders = freezed,
    Object? enableReminder1 = freezed,
    Object? enableReminder2 = freezed,
    Object? enableReminder3 = freezed,
    Object? enableReminderEndless = freezed,
    Object? numDaysReminder1 = freezed,
    Object? numDaysReminder2 = freezed,
    Object? numDaysReminder3 = freezed,
    Object? scheduleReminder1 = freezed,
    Object? scheduleReminder2 = freezed,
    Object? scheduleReminder3 = freezed,
    Object? reminderSendTime = freezed,
    Object? lateFeeAmount1 = freezed,
    Object? lateFeeAmount2 = freezed,
    Object? lateFeeAmount3 = freezed,
    Object? lateFeePercent1 = freezed,
    Object? lateFeePercent2 = freezed,
    Object? lateFeePercent3 = freezed,
    Object? endlessReminderFrequencyId = freezed,
    Object? lateFeeEndlessAmount = freezed,
    Object? lateFeeEndlessPercent = freezed,
    Object? autoArchiveInvoice = freezed,
    Object? autoArchiveInvoiceCancelled = freezed,
    Object? autoArchiveQuote = freezed,
    Object? autoConvertQuote = freezed,
    Object? autoEmailInvoice = freezed,
    Object? autoBillStandardInvoices = freezed,
    Object? autoBill = freezed,
    Object? autoBillDate = freezed,
    Object? lockInvoices = freezed,
    Object? entitySendTime = freezed,
    Object? showAcceptInvoiceTerms = freezed,
    Object? showAcceptQuoteTerms = freezed,
    Object? requireInvoiceSignature = freezed,
    Object? requireQuoteSignature = freezed,
    Object? requirePurchaseOrderSignature = freezed,
    Object? signatureOnPdf = freezed,
    Object? acceptClientInputQuoteApproval = freezed,
    Object? syncInvoiceQuoteColumns = freezed,
    Object? showShippingAddress = freezed,
    Object? showPaidStamp = freezed,
    Object? pageSize = freezed,
    Object? pageLayout = freezed,
    Object? fontSize = freezed,
    Object? primaryFont = freezed,
    Object? secondaryFont = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
    Object? pageNumbering = freezed,
    Object? pageNumberingAlignment = freezed,
    Object? hidePaidToDate = freezed,
    Object? hideEmptyColumnsOnPdf = freezed,
    Object? embedDocuments = freezed,
    Object? allPagesHeader = freezed,
    Object? allPagesFooter = freezed,
    Object? pdfVariables = freezed,
    Object? showPdfhtmlOnMobile = freezed,
    Object? enableClientPortal = freezed,
    Object? enableClientPortalDashboard = freezed,
    Object? enableClientPortalTasks = freezed,
    Object? showAllTasksClientPortal = freezed,
    Object? enableClientPortalPassword = freezed,
    Object? clientPortalTerms = freezed,
    Object? clientPortalPrivacyPolicy = freezed,
    Object? clientPortalEnableUploads = freezed,
    Object? clientPortalAllowUnderPayment = freezed,
    Object? clientPortalUnderPaymentMinimum = freezed,
    Object? clientPortalAllowOverPayment = freezed,
    Object? portalCustomHead = freezed,
    Object? portalCustomCss = freezed,
    Object? portalCustomFooter = freezed,
    Object? portalCustomJs = freezed,
    Object? clientCanRegister = freezed,
    Object? clientInitiatedPayments = freezed,
    Object? clientInitiatedPaymentsMinimum = freezed,
    Object? enableClientProfileUpdate = freezed,
    Object? clientOnlinePaymentNotification = freezed,
    Object? clientManualPaymentNotification = freezed,
    Object? vendorPortalEnableUploads = freezed,
    Object? useCreditsPayment = freezed,
    Object? useUnappliedPayment = freezed,
    Object? paymentTerms = freezed,
    Object? validUntil = freezed,
    Object? paymentTypeId = freezed,
    Object? defaultExpensePaymentTypeId = freezed,
    Object? companyGatewayIds = freezed,
    Object? paymentFlow = freezed,
    Object? unlockInvoiceDocumentsAfterPayment = freezed,
    Object? showTaskItemDescription = freezed,
    Object? allowBillableTaskItems = freezed,
    Object? defaultTaskRate = freezed,
    Object? taskRoundUp = freezed,
    Object? taskRoundToNearest = freezed,
    Object? enableEInvoice = freezed,
    Object? eInvoiceType = freezed,
    Object? eQuoteType = freezed,
    Object? mergeEInvoiceToPdf = freezed,
    Object? skipAutomaticEmailWithPeppol = freezed,
    Object? eInvoiceForwardEmail = freezed,
    Object? eExpenseForwardEmail = freezed,
    Object? preferenceProductNotesForHtmlView = freezed,
    Object? customMessageDashboard = freezed,
    Object? customMessageUnpaidInvoice = freezed,
    Object? customMessagePaidInvoice = freezed,
    Object? customMessageUnapprovedQuote = freezed,
    Object? translations = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            companyLogo: freezed == companyLogo
                ? _value.companyLogo
                : companyLogo // ignore: cast_nullable_to_non_nullable
                      as String?,
            companyLogoSize: freezed == companyLogoSize
                ? _value.companyLogoSize
                : companyLogoSize // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            address1: freezed == address1
                ? _value.address1
                : address1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            address2: freezed == address2
                ? _value.address2
                : address2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            state: freezed == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String?,
            postalCode: freezed == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            countryId: freezed == countryId
                ? _value.countryId
                : countryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            vatNumber: freezed == vatNumber
                ? _value.vatNumber
                : vatNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            idNumber: freezed == idNumber
                ? _value.idNumber
                : idNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            classification: freezed == classification
                ? _value.classification
                : classification // ignore: cast_nullable_to_non_nullable
                      as String?,
            qrIban: freezed == qrIban
                ? _value.qrIban
                : qrIban // ignore: cast_nullable_to_non_nullable
                      as String?,
            besrId: freezed == besrId
                ? _value.besrId
                : besrId // ignore: cast_nullable_to_non_nullable
                      as String?,
            customValue1: freezed == customValue1
                ? _value.customValue1
                : customValue1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            customValue2: freezed == customValue2
                ? _value.customValue2
                : customValue2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            customValue3: freezed == customValue3
                ? _value.customValue3
                : customValue3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            customValue4: freezed == customValue4
                ? _value.customValue4
                : customValue4 // ignore: cast_nullable_to_non_nullable
                      as String?,
            timezoneId: freezed == timezoneId
                ? _value.timezoneId
                : timezoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateFormatId: freezed == dateFormatId
                ? _value.dateFormatId
                : dateFormatId // ignore: cast_nullable_to_non_nullable
                      as String?,
            languageId: freezed == languageId
                ? _value.languageId
                : languageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currencyId: freezed == currencyId
                ? _value.currencyId
                : currencyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            militaryTime: freezed == militaryTime
                ? _value.militaryTime
                : militaryTime // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showCurrencyCode: freezed == showCurrencyCode
                ? _value.showCurrencyCode
                : showCurrencyCode // ignore: cast_nullable_to_non_nullable
                      as bool?,
            useCommaAsDecimalPlace: freezed == useCommaAsDecimalPlace
                ? _value.useCommaAsDecimalPlace
                : useCommaAsDecimalPlace // ignore: cast_nullable_to_non_nullable
                      as bool?,
            firstMonthOfYear: freezed == firstMonthOfYear
                ? _value.firstMonthOfYear
                : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceTerms: freezed == invoiceTerms
                ? _value.invoiceTerms
                : invoiceTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceFooter: freezed == invoiceFooter
                ? _value.invoiceFooter
                : invoiceFooter // ignore: cast_nullable_to_non_nullable
                      as String?,
            quoteTerms: freezed == quoteTerms
                ? _value.quoteTerms
                : quoteTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            quoteFooter: freezed == quoteFooter
                ? _value.quoteFooter
                : quoteFooter // ignore: cast_nullable_to_non_nullable
                      as String?,
            creditTerms: freezed == creditTerms
                ? _value.creditTerms
                : creditTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            creditFooter: freezed == creditFooter
                ? _value.creditFooter
                : creditFooter // ignore: cast_nullable_to_non_nullable
                      as String?,
            purchaseOrderTerms: freezed == purchaseOrderTerms
                ? _value.purchaseOrderTerms
                : purchaseOrderTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            purchaseOrderFooter: freezed == purchaseOrderFooter
                ? _value.purchaseOrderFooter
                : purchaseOrderFooter // ignore: cast_nullable_to_non_nullable
                      as String?,
            purchaseOrderPublicNotes: freezed == purchaseOrderPublicNotes
                ? _value.purchaseOrderPublicNotes
                : purchaseOrderPublicNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceLabels: freezed == invoiceLabels
                ? _value.invoiceLabels
                : invoiceLabels // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceDesignId: freezed == invoiceDesignId
                ? _value.invoiceDesignId
                : invoiceDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            quoteDesignId: freezed == quoteDesignId
                ? _value.quoteDesignId
                : quoteDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            creditDesignId: freezed == creditDesignId
                ? _value.creditDesignId
                : creditDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            purchaseOrderDesignId: freezed == purchaseOrderDesignId
                ? _value.purchaseOrderDesignId
                : purchaseOrderDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            statementDesignId: freezed == statementDesignId
                ? _value.statementDesignId
                : statementDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deliveryNoteDesignId: freezed == deliveryNoteDesignId
                ? _value.deliveryNoteDesignId
                : deliveryNoteDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentReceiptDesignId: freezed == paymentReceiptDesignId
                ? _value.paymentReceiptDesignId
                : paymentReceiptDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentRefundDesignId: freezed == paymentRefundDesignId
                ? _value.paymentRefundDesignId
                : paymentRefundDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            portalDesignId: freezed == portalDesignId
                ? _value.portalDesignId
                : portalDesignId // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceNumberPattern: freezed == invoiceNumberPattern
                ? _value.invoiceNumberPattern
                : invoiceNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceNumberCounter: freezed == invoiceNumberCounter
                ? _value.invoiceNumberCounter
                : invoiceNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurringInvoiceNumberPattern:
                freezed == recurringInvoiceNumberPattern
                ? _value.recurringInvoiceNumberPattern
                : recurringInvoiceNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurringInvoiceNumberCounter:
                freezed == recurringInvoiceNumberCounter
                ? _value.recurringInvoiceNumberCounter
                : recurringInvoiceNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            quoteNumberPattern: freezed == quoteNumberPattern
                ? _value.quoteNumberPattern
                : quoteNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            quoteNumberCounter: freezed == quoteNumberCounter
                ? _value.quoteNumberCounter
                : quoteNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurringQuoteNumberPattern: freezed == recurringQuoteNumberPattern
                ? _value.recurringQuoteNumberPattern
                : recurringQuoteNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurringQuoteNumberCounter: freezed == recurringQuoteNumberCounter
                ? _value.recurringQuoteNumberCounter
                : recurringQuoteNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            clientNumberPattern: freezed == clientNumberPattern
                ? _value.clientNumberPattern
                : clientNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientNumberCounter: freezed == clientNumberCounter
                ? _value.clientNumberCounter
                : clientNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            creditNumberPattern: freezed == creditNumberPattern
                ? _value.creditNumberPattern
                : creditNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            creditNumberCounter: freezed == creditNumberCounter
                ? _value.creditNumberCounter
                : creditNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            taskNumberPattern: freezed == taskNumberPattern
                ? _value.taskNumberPattern
                : taskNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            taskNumberCounter: freezed == taskNumberCounter
                ? _value.taskNumberCounter
                : taskNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            expenseNumberPattern: freezed == expenseNumberPattern
                ? _value.expenseNumberPattern
                : expenseNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            expenseNumberCounter: freezed == expenseNumberCounter
                ? _value.expenseNumberCounter
                : expenseNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurringExpenseNumberPattern:
                freezed == recurringExpenseNumberPattern
                ? _value.recurringExpenseNumberPattern
                : recurringExpenseNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurringExpenseNumberCounter:
                freezed == recurringExpenseNumberCounter
                ? _value.recurringExpenseNumberCounter
                : recurringExpenseNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            vendorNumberPattern: freezed == vendorNumberPattern
                ? _value.vendorNumberPattern
                : vendorNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            vendorNumberCounter: freezed == vendorNumberCounter
                ? _value.vendorNumberCounter
                : vendorNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            ticketNumberPattern: freezed == ticketNumberPattern
                ? _value.ticketNumberPattern
                : ticketNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            ticketNumberCounter: freezed == ticketNumberCounter
                ? _value.ticketNumberCounter
                : ticketNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            paymentNumberPattern: freezed == paymentNumberPattern
                ? _value.paymentNumberPattern
                : paymentNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentNumberCounter: freezed == paymentNumberCounter
                ? _value.paymentNumberCounter
                : paymentNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            projectNumberPattern: freezed == projectNumberPattern
                ? _value.projectNumberPattern
                : projectNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectNumberCounter: freezed == projectNumberCounter
                ? _value.projectNumberCounter
                : projectNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            purchaseOrderNumberPattern: freezed == purchaseOrderNumberPattern
                ? _value.purchaseOrderNumberPattern
                : purchaseOrderNumberPattern // ignore: cast_nullable_to_non_nullable
                      as String?,
            purchaseOrderNumberCounter: freezed == purchaseOrderNumberCounter
                ? _value.purchaseOrderNumberCounter
                : purchaseOrderNumberCounter // ignore: cast_nullable_to_non_nullable
                      as int?,
            sharedInvoiceQuoteCounter: freezed == sharedInvoiceQuoteCounter
                ? _value.sharedInvoiceQuoteCounter
                : sharedInvoiceQuoteCounter // ignore: cast_nullable_to_non_nullable
                      as bool?,
            sharedInvoiceCreditCounter: freezed == sharedInvoiceCreditCounter
                ? _value.sharedInvoiceCreditCounter
                : sharedInvoiceCreditCounter // ignore: cast_nullable_to_non_nullable
                      as bool?,
            recurringNumberPrefix: freezed == recurringNumberPrefix
                ? _value.recurringNumberPrefix
                : recurringNumberPrefix // ignore: cast_nullable_to_non_nullable
                      as String?,
            resetCounterFrequencyId: freezed == resetCounterFrequencyId
                ? _value.resetCounterFrequencyId
                : resetCounterFrequencyId // ignore: cast_nullable_to_non_nullable
                      as int?,
            resetCounterDate: freezed == resetCounterDate
                ? _value.resetCounterDate
                : resetCounterDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            counterPadding: freezed == counterPadding
                ? _value.counterPadding
                : counterPadding // ignore: cast_nullable_to_non_nullable
                      as int?,
            counterNumberApplied: freezed == counterNumberApplied
                ? _value.counterNumberApplied
                : counterNumberApplied // ignore: cast_nullable_to_non_nullable
                      as String?,
            quoteNumberApplied: freezed == quoteNumberApplied
                ? _value.quoteNumberApplied
                : quoteNumberApplied // ignore: cast_nullable_to_non_nullable
                      as String?,
            taxName1: freezed == taxName1
                ? _value.taxName1
                : taxName1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            taxRate1: freezed == taxRate1
                ? _value.taxRate1
                : taxRate1 // ignore: cast_nullable_to_non_nullable
                      as double?,
            taxName2: freezed == taxName2
                ? _value.taxName2
                : taxName2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            taxRate2: freezed == taxRate2
                ? _value.taxRate2
                : taxRate2 // ignore: cast_nullable_to_non_nullable
                      as double?,
            taxName3: freezed == taxName3
                ? _value.taxName3
                : taxName3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            taxRate3: freezed == taxRate3
                ? _value.taxRate3
                : taxRate3 // ignore: cast_nullable_to_non_nullable
                      as double?,
            invoiceTaxes: freezed == invoiceTaxes
                ? _value.invoiceTaxes
                : invoiceTaxes // ignore: cast_nullable_to_non_nullable
                      as int?,
            inclusiveTaxes: freezed == inclusiveTaxes
                ? _value.inclusiveTaxes
                : inclusiveTaxes // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableRappenRounding: freezed == enableRappenRounding
                ? _value.enableRappenRounding
                : enableRappenRounding // ignore: cast_nullable_to_non_nullable
                      as bool?,
            emailSendingMethod: freezed == emailSendingMethod
                ? _value.emailSendingMethod
                : emailSendingMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            gmailSendingUserId: freezed == gmailSendingUserId
                ? _value.gmailSendingUserId
                : gmailSendingUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            replyToEmail: freezed == replyToEmail
                ? _value.replyToEmail
                : replyToEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            replyToName: freezed == replyToName
                ? _value.replyToName
                : replyToName // ignore: cast_nullable_to_non_nullable
                      as String?,
            bccEmail: freezed == bccEmail
                ? _value.bccEmail
                : bccEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailFromName: freezed == emailFromName
                ? _value.emailFromName
                : emailFromName // ignore: cast_nullable_to_non_nullable
                      as String?,
            customSendingEmail: freezed == customSendingEmail
                ? _value.customSendingEmail
                : customSendingEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailStyle: freezed == emailStyle
                ? _value.emailStyle
                : emailStyle // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailStyleCustom: freezed == emailStyleCustom
                ? _value.emailStyleCustom
                : emailStyleCustom // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSignature: freezed == emailSignature
                ? _value.emailSignature
                : emailSignature // ignore: cast_nullable_to_non_nullable
                      as String?,
            enableEmailMarkup: freezed == enableEmailMarkup
                ? _value.enableEmailMarkup
                : enableEmailMarkup // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showEmailFooter: freezed == showEmailFooter
                ? _value.showEmailFooter
                : showEmailFooter // ignore: cast_nullable_to_non_nullable
                      as bool?,
            pdfEmailAttachment: freezed == pdfEmailAttachment
                ? _value.pdfEmailAttachment
                : pdfEmailAttachment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            ublEmailAttachment: freezed == ublEmailAttachment
                ? _value.ublEmailAttachment
                : ublEmailAttachment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            documentEmailAttachment: freezed == documentEmailAttachment
                ? _value.documentEmailAttachment
                : documentEmailAttachment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            sendEmailOnMarkPaid: freezed == sendEmailOnMarkPaid
                ? _value.sendEmailOnMarkPaid
                : sendEmailOnMarkPaid // ignore: cast_nullable_to_non_nullable
                      as bool?,
            paymentEmailAllContacts: freezed == paymentEmailAllContacts
                ? _value.paymentEmailAllContacts
                : paymentEmailAllContacts // ignore: cast_nullable_to_non_nullable
                      as bool?,
            postmarkSecret: freezed == postmarkSecret
                ? _value.postmarkSecret
                : postmarkSecret // ignore: cast_nullable_to_non_nullable
                      as String?,
            mailgunSecret: freezed == mailgunSecret
                ? _value.mailgunSecret
                : mailgunSecret // ignore: cast_nullable_to_non_nullable
                      as String?,
            mailgunDomain: freezed == mailgunDomain
                ? _value.mailgunDomain
                : mailgunDomain // ignore: cast_nullable_to_non_nullable
                      as String?,
            mailgunEndpoint: freezed == mailgunEndpoint
                ? _value.mailgunEndpoint
                : mailgunEndpoint // ignore: cast_nullable_to_non_nullable
                      as String?,
            brevoSecret: freezed == brevoSecret
                ? _value.brevoSecret
                : brevoSecret // ignore: cast_nullable_to_non_nullable
                      as String?,
            sesSecretKey: freezed == sesSecretKey
                ? _value.sesSecretKey
                : sesSecretKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            sesAccessKey: freezed == sesAccessKey
                ? _value.sesAccessKey
                : sesAccessKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            sesRegion: freezed == sesRegion
                ? _value.sesRegion
                : sesRegion // ignore: cast_nullable_to_non_nullable
                      as String?,
            sesTopicArn: freezed == sesTopicArn
                ? _value.sesTopicArn
                : sesTopicArn // ignore: cast_nullable_to_non_nullable
                      as String?,
            sesFromAddress: freezed == sesFromAddress
                ? _value.sesFromAddress
                : sesFromAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectInvoice: freezed == emailSubjectInvoice
                ? _value.emailSubjectInvoice
                : emailSubjectInvoice // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectQuote: freezed == emailSubjectQuote
                ? _value.emailSubjectQuote
                : emailSubjectQuote // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectCredit: freezed == emailSubjectCredit
                ? _value.emailSubjectCredit
                : emailSubjectCredit // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectPayment: freezed == emailSubjectPayment
                ? _value.emailSubjectPayment
                : emailSubjectPayment // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectPaymentPartial: freezed == emailSubjectPaymentPartial
                ? _value.emailSubjectPaymentPartial
                : emailSubjectPaymentPartial // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectStatement: freezed == emailSubjectStatement
                ? _value.emailSubjectStatement
                : emailSubjectStatement // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectPurchaseOrder: freezed == emailSubjectPurchaseOrder
                ? _value.emailSubjectPurchaseOrder
                : emailSubjectPurchaseOrder // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectReminder1: freezed == emailSubjectReminder1
                ? _value.emailSubjectReminder1
                : emailSubjectReminder1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectReminder2: freezed == emailSubjectReminder2
                ? _value.emailSubjectReminder2
                : emailSubjectReminder2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectReminder3: freezed == emailSubjectReminder3
                ? _value.emailSubjectReminder3
                : emailSubjectReminder3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectReminderEndless: freezed == emailSubjectReminderEndless
                ? _value.emailSubjectReminderEndless
                : emailSubjectReminderEndless // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectCustom1: freezed == emailSubjectCustom1
                ? _value.emailSubjectCustom1
                : emailSubjectCustom1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectCustom2: freezed == emailSubjectCustom2
                ? _value.emailSubjectCustom2
                : emailSubjectCustom2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailSubjectCustom3: freezed == emailSubjectCustom3
                ? _value.emailSubjectCustom3
                : emailSubjectCustom3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateInvoice: freezed == emailTemplateInvoice
                ? _value.emailTemplateInvoice
                : emailTemplateInvoice // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateQuote: freezed == emailTemplateQuote
                ? _value.emailTemplateQuote
                : emailTemplateQuote // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateCredit: freezed == emailTemplateCredit
                ? _value.emailTemplateCredit
                : emailTemplateCredit // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplatePayment: freezed == emailTemplatePayment
                ? _value.emailTemplatePayment
                : emailTemplatePayment // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplatePaymentPartial: freezed == emailTemplatePaymentPartial
                ? _value.emailTemplatePaymentPartial
                : emailTemplatePaymentPartial // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateStatement: freezed == emailTemplateStatement
                ? _value.emailTemplateStatement
                : emailTemplateStatement // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplatePurchaseOrder: freezed == emailTemplatePurchaseOrder
                ? _value.emailTemplatePurchaseOrder
                : emailTemplatePurchaseOrder // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateReminder1: freezed == emailTemplateReminder1
                ? _value.emailTemplateReminder1
                : emailTemplateReminder1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateReminder2: freezed == emailTemplateReminder2
                ? _value.emailTemplateReminder2
                : emailTemplateReminder2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateReminder3: freezed == emailTemplateReminder3
                ? _value.emailTemplateReminder3
                : emailTemplateReminder3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateReminderEndless:
                freezed == emailTemplateReminderEndless
                ? _value.emailTemplateReminderEndless
                : emailTemplateReminderEndless // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateCustom1: freezed == emailTemplateCustom1
                ? _value.emailTemplateCustom1
                : emailTemplateCustom1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateCustom2: freezed == emailTemplateCustom2
                ? _value.emailTemplateCustom2
                : emailTemplateCustom2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emailTemplateCustom3: freezed == emailTemplateCustom3
                ? _value.emailTemplateCustom3
                : emailTemplateCustom3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            sendReminders: freezed == sendReminders
                ? _value.sendReminders
                : sendReminders // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableReminder1: freezed == enableReminder1
                ? _value.enableReminder1
                : enableReminder1 // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableReminder2: freezed == enableReminder2
                ? _value.enableReminder2
                : enableReminder2 // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableReminder3: freezed == enableReminder3
                ? _value.enableReminder3
                : enableReminder3 // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableReminderEndless: freezed == enableReminderEndless
                ? _value.enableReminderEndless
                : enableReminderEndless // ignore: cast_nullable_to_non_nullable
                      as bool?,
            numDaysReminder1: freezed == numDaysReminder1
                ? _value.numDaysReminder1
                : numDaysReminder1 // ignore: cast_nullable_to_non_nullable
                      as int?,
            numDaysReminder2: freezed == numDaysReminder2
                ? _value.numDaysReminder2
                : numDaysReminder2 // ignore: cast_nullable_to_non_nullable
                      as int?,
            numDaysReminder3: freezed == numDaysReminder3
                ? _value.numDaysReminder3
                : numDaysReminder3 // ignore: cast_nullable_to_non_nullable
                      as int?,
            scheduleReminder1: freezed == scheduleReminder1
                ? _value.scheduleReminder1
                : scheduleReminder1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            scheduleReminder2: freezed == scheduleReminder2
                ? _value.scheduleReminder2
                : scheduleReminder2 // ignore: cast_nullable_to_non_nullable
                      as String?,
            scheduleReminder3: freezed == scheduleReminder3
                ? _value.scheduleReminder3
                : scheduleReminder3 // ignore: cast_nullable_to_non_nullable
                      as String?,
            reminderSendTime: freezed == reminderSendTime
                ? _value.reminderSendTime
                : reminderSendTime // ignore: cast_nullable_to_non_nullable
                      as int?,
            lateFeeAmount1: freezed == lateFeeAmount1
                ? _value.lateFeeAmount1
                : lateFeeAmount1 // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeeAmount2: freezed == lateFeeAmount2
                ? _value.lateFeeAmount2
                : lateFeeAmount2 // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeeAmount3: freezed == lateFeeAmount3
                ? _value.lateFeeAmount3
                : lateFeeAmount3 // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeePercent1: freezed == lateFeePercent1
                ? _value.lateFeePercent1
                : lateFeePercent1 // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeePercent2: freezed == lateFeePercent2
                ? _value.lateFeePercent2
                : lateFeePercent2 // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeePercent3: freezed == lateFeePercent3
                ? _value.lateFeePercent3
                : lateFeePercent3 // ignore: cast_nullable_to_non_nullable
                      as double?,
            endlessReminderFrequencyId: freezed == endlessReminderFrequencyId
                ? _value.endlessReminderFrequencyId
                : endlessReminderFrequencyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lateFeeEndlessAmount: freezed == lateFeeEndlessAmount
                ? _value.lateFeeEndlessAmount
                : lateFeeEndlessAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            lateFeeEndlessPercent: freezed == lateFeeEndlessPercent
                ? _value.lateFeeEndlessPercent
                : lateFeeEndlessPercent // ignore: cast_nullable_to_non_nullable
                      as double?,
            autoArchiveInvoice: freezed == autoArchiveInvoice
                ? _value.autoArchiveInvoice
                : autoArchiveInvoice // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoArchiveInvoiceCancelled: freezed == autoArchiveInvoiceCancelled
                ? _value.autoArchiveInvoiceCancelled
                : autoArchiveInvoiceCancelled // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoArchiveQuote: freezed == autoArchiveQuote
                ? _value.autoArchiveQuote
                : autoArchiveQuote // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoConvertQuote: freezed == autoConvertQuote
                ? _value.autoConvertQuote
                : autoConvertQuote // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoEmailInvoice: freezed == autoEmailInvoice
                ? _value.autoEmailInvoice
                : autoEmailInvoice // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoBillStandardInvoices: freezed == autoBillStandardInvoices
                ? _value.autoBillStandardInvoices
                : autoBillStandardInvoices // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoBill: freezed == autoBill
                ? _value.autoBill
                : autoBill // ignore: cast_nullable_to_non_nullable
                      as String?,
            autoBillDate: freezed == autoBillDate
                ? _value.autoBillDate
                : autoBillDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            lockInvoices: freezed == lockInvoices
                ? _value.lockInvoices
                : lockInvoices // ignore: cast_nullable_to_non_nullable
                      as String?,
            entitySendTime: freezed == entitySendTime
                ? _value.entitySendTime
                : entitySendTime // ignore: cast_nullable_to_non_nullable
                      as int?,
            showAcceptInvoiceTerms: freezed == showAcceptInvoiceTerms
                ? _value.showAcceptInvoiceTerms
                : showAcceptInvoiceTerms // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showAcceptQuoteTerms: freezed == showAcceptQuoteTerms
                ? _value.showAcceptQuoteTerms
                : showAcceptQuoteTerms // ignore: cast_nullable_to_non_nullable
                      as bool?,
            requireInvoiceSignature: freezed == requireInvoiceSignature
                ? _value.requireInvoiceSignature
                : requireInvoiceSignature // ignore: cast_nullable_to_non_nullable
                      as bool?,
            requireQuoteSignature: freezed == requireQuoteSignature
                ? _value.requireQuoteSignature
                : requireQuoteSignature // ignore: cast_nullable_to_non_nullable
                      as bool?,
            requirePurchaseOrderSignature:
                freezed == requirePurchaseOrderSignature
                ? _value.requirePurchaseOrderSignature
                : requirePurchaseOrderSignature // ignore: cast_nullable_to_non_nullable
                      as bool?,
            signatureOnPdf: freezed == signatureOnPdf
                ? _value.signatureOnPdf
                : signatureOnPdf // ignore: cast_nullable_to_non_nullable
                      as bool?,
            acceptClientInputQuoteApproval:
                freezed == acceptClientInputQuoteApproval
                ? _value.acceptClientInputQuoteApproval
                : acceptClientInputQuoteApproval // ignore: cast_nullable_to_non_nullable
                      as bool?,
            syncInvoiceQuoteColumns: freezed == syncInvoiceQuoteColumns
                ? _value.syncInvoiceQuoteColumns
                : syncInvoiceQuoteColumns // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showShippingAddress: freezed == showShippingAddress
                ? _value.showShippingAddress
                : showShippingAddress // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showPaidStamp: freezed == showPaidStamp
                ? _value.showPaidStamp
                : showPaidStamp // ignore: cast_nullable_to_non_nullable
                      as bool?,
            pageSize: freezed == pageSize
                ? _value.pageSize
                : pageSize // ignore: cast_nullable_to_non_nullable
                      as String?,
            pageLayout: freezed == pageLayout
                ? _value.pageLayout
                : pageLayout // ignore: cast_nullable_to_non_nullable
                      as String?,
            fontSize: freezed == fontSize
                ? _value.fontSize
                : fontSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            primaryFont: freezed == primaryFont
                ? _value.primaryFont
                : primaryFont // ignore: cast_nullable_to_non_nullable
                      as String?,
            secondaryFont: freezed == secondaryFont
                ? _value.secondaryFont
                : secondaryFont // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryColor: freezed == primaryColor
                ? _value.primaryColor
                : primaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            secondaryColor: freezed == secondaryColor
                ? _value.secondaryColor
                : secondaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            pageNumbering: freezed == pageNumbering
                ? _value.pageNumbering
                : pageNumbering // ignore: cast_nullable_to_non_nullable
                      as bool?,
            pageNumberingAlignment: freezed == pageNumberingAlignment
                ? _value.pageNumberingAlignment
                : pageNumberingAlignment // ignore: cast_nullable_to_non_nullable
                      as String?,
            hidePaidToDate: freezed == hidePaidToDate
                ? _value.hidePaidToDate
                : hidePaidToDate // ignore: cast_nullable_to_non_nullable
                      as bool?,
            hideEmptyColumnsOnPdf: freezed == hideEmptyColumnsOnPdf
                ? _value.hideEmptyColumnsOnPdf
                : hideEmptyColumnsOnPdf // ignore: cast_nullable_to_non_nullable
                      as bool?,
            embedDocuments: freezed == embedDocuments
                ? _value.embedDocuments
                : embedDocuments // ignore: cast_nullable_to_non_nullable
                      as bool?,
            allPagesHeader: freezed == allPagesHeader
                ? _value.allPagesHeader
                : allPagesHeader // ignore: cast_nullable_to_non_nullable
                      as bool?,
            allPagesFooter: freezed == allPagesFooter
                ? _value.allPagesFooter
                : allPagesFooter // ignore: cast_nullable_to_non_nullable
                      as bool?,
            pdfVariables: freezed == pdfVariables
                ? _value.pdfVariables
                : pdfVariables // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<String>>?,
            showPdfhtmlOnMobile: freezed == showPdfhtmlOnMobile
                ? _value.showPdfhtmlOnMobile
                : showPdfhtmlOnMobile // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableClientPortal: freezed == enableClientPortal
                ? _value.enableClientPortal
                : enableClientPortal // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableClientPortalDashboard: freezed == enableClientPortalDashboard
                ? _value.enableClientPortalDashboard
                : enableClientPortalDashboard // ignore: cast_nullable_to_non_nullable
                      as bool?,
            enableClientPortalTasks: freezed == enableClientPortalTasks
                ? _value.enableClientPortalTasks
                : enableClientPortalTasks // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showAllTasksClientPortal: freezed == showAllTasksClientPortal
                ? _value.showAllTasksClientPortal
                : showAllTasksClientPortal // ignore: cast_nullable_to_non_nullable
                      as String?,
            enableClientPortalPassword: freezed == enableClientPortalPassword
                ? _value.enableClientPortalPassword
                : enableClientPortalPassword // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientPortalTerms: freezed == clientPortalTerms
                ? _value.clientPortalTerms
                : clientPortalTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientPortalPrivacyPolicy: freezed == clientPortalPrivacyPolicy
                ? _value.clientPortalPrivacyPolicy
                : clientPortalPrivacyPolicy // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientPortalEnableUploads: freezed == clientPortalEnableUploads
                ? _value.clientPortalEnableUploads
                : clientPortalEnableUploads // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientPortalAllowUnderPayment:
                freezed == clientPortalAllowUnderPayment
                ? _value.clientPortalAllowUnderPayment
                : clientPortalAllowUnderPayment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientPortalUnderPaymentMinimum:
                freezed == clientPortalUnderPaymentMinimum
                ? _value.clientPortalUnderPaymentMinimum
                : clientPortalUnderPaymentMinimum // ignore: cast_nullable_to_non_nullable
                      as double?,
            clientPortalAllowOverPayment:
                freezed == clientPortalAllowOverPayment
                ? _value.clientPortalAllowOverPayment
                : clientPortalAllowOverPayment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            portalCustomHead: freezed == portalCustomHead
                ? _value.portalCustomHead
                : portalCustomHead // ignore: cast_nullable_to_non_nullable
                      as String?,
            portalCustomCss: freezed == portalCustomCss
                ? _value.portalCustomCss
                : portalCustomCss // ignore: cast_nullable_to_non_nullable
                      as String?,
            portalCustomFooter: freezed == portalCustomFooter
                ? _value.portalCustomFooter
                : portalCustomFooter // ignore: cast_nullable_to_non_nullable
                      as String?,
            portalCustomJs: freezed == portalCustomJs
                ? _value.portalCustomJs
                : portalCustomJs // ignore: cast_nullable_to_non_nullable
                      as String?,
            clientCanRegister: freezed == clientCanRegister
                ? _value.clientCanRegister
                : clientCanRegister // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientInitiatedPayments: freezed == clientInitiatedPayments
                ? _value.clientInitiatedPayments
                : clientInitiatedPayments // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientInitiatedPaymentsMinimum:
                freezed == clientInitiatedPaymentsMinimum
                ? _value.clientInitiatedPaymentsMinimum
                : clientInitiatedPaymentsMinimum // ignore: cast_nullable_to_non_nullable
                      as double?,
            enableClientProfileUpdate: freezed == enableClientProfileUpdate
                ? _value.enableClientProfileUpdate
                : enableClientProfileUpdate // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientOnlinePaymentNotification:
                freezed == clientOnlinePaymentNotification
                ? _value.clientOnlinePaymentNotification
                : clientOnlinePaymentNotification // ignore: cast_nullable_to_non_nullable
                      as bool?,
            clientManualPaymentNotification:
                freezed == clientManualPaymentNotification
                ? _value.clientManualPaymentNotification
                : clientManualPaymentNotification // ignore: cast_nullable_to_non_nullable
                      as bool?,
            vendorPortalEnableUploads: freezed == vendorPortalEnableUploads
                ? _value.vendorPortalEnableUploads
                : vendorPortalEnableUploads // ignore: cast_nullable_to_non_nullable
                      as bool?,
            useCreditsPayment: freezed == useCreditsPayment
                ? _value.useCreditsPayment
                : useCreditsPayment // ignore: cast_nullable_to_non_nullable
                      as String?,
            useUnappliedPayment: freezed == useUnappliedPayment
                ? _value.useUnappliedPayment
                : useUnappliedPayment // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentTerms: freezed == paymentTerms
                ? _value.paymentTerms
                : paymentTerms // ignore: cast_nullable_to_non_nullable
                      as String?,
            validUntil: freezed == validUntil
                ? _value.validUntil
                : validUntil // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentTypeId: freezed == paymentTypeId
                ? _value.paymentTypeId
                : paymentTypeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            defaultExpensePaymentTypeId: freezed == defaultExpensePaymentTypeId
                ? _value.defaultExpensePaymentTypeId
                : defaultExpensePaymentTypeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            companyGatewayIds: freezed == companyGatewayIds
                ? _value.companyGatewayIds
                : companyGatewayIds // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentFlow: freezed == paymentFlow
                ? _value.paymentFlow
                : paymentFlow // ignore: cast_nullable_to_non_nullable
                      as String?,
            unlockInvoiceDocumentsAfterPayment:
                freezed == unlockInvoiceDocumentsAfterPayment
                ? _value.unlockInvoiceDocumentsAfterPayment
                : unlockInvoiceDocumentsAfterPayment // ignore: cast_nullable_to_non_nullable
                      as bool?,
            showTaskItemDescription: freezed == showTaskItemDescription
                ? _value.showTaskItemDescription
                : showTaskItemDescription // ignore: cast_nullable_to_non_nullable
                      as bool?,
            allowBillableTaskItems: freezed == allowBillableTaskItems
                ? _value.allowBillableTaskItems
                : allowBillableTaskItems // ignore: cast_nullable_to_non_nullable
                      as bool?,
            defaultTaskRate: freezed == defaultTaskRate
                ? _value.defaultTaskRate
                : defaultTaskRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            taskRoundUp: freezed == taskRoundUp
                ? _value.taskRoundUp
                : taskRoundUp // ignore: cast_nullable_to_non_nullable
                      as bool?,
            taskRoundToNearest: freezed == taskRoundToNearest
                ? _value.taskRoundToNearest
                : taskRoundToNearest // ignore: cast_nullable_to_non_nullable
                      as double?,
            enableEInvoice: freezed == enableEInvoice
                ? _value.enableEInvoice
                : enableEInvoice // ignore: cast_nullable_to_non_nullable
                      as bool?,
            eInvoiceType: freezed == eInvoiceType
                ? _value.eInvoiceType
                : eInvoiceType // ignore: cast_nullable_to_non_nullable
                      as String?,
            eQuoteType: freezed == eQuoteType
                ? _value.eQuoteType
                : eQuoteType // ignore: cast_nullable_to_non_nullable
                      as String?,
            mergeEInvoiceToPdf: freezed == mergeEInvoiceToPdf
                ? _value.mergeEInvoiceToPdf
                : mergeEInvoiceToPdf // ignore: cast_nullable_to_non_nullable
                      as bool?,
            skipAutomaticEmailWithPeppol:
                freezed == skipAutomaticEmailWithPeppol
                ? _value.skipAutomaticEmailWithPeppol
                : skipAutomaticEmailWithPeppol // ignore: cast_nullable_to_non_nullable
                      as bool?,
            eInvoiceForwardEmail: freezed == eInvoiceForwardEmail
                ? _value.eInvoiceForwardEmail
                : eInvoiceForwardEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            eExpenseForwardEmail: freezed == eExpenseForwardEmail
                ? _value.eExpenseForwardEmail
                : eExpenseForwardEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            preferenceProductNotesForHtmlView:
                freezed == preferenceProductNotesForHtmlView
                ? _value.preferenceProductNotesForHtmlView
                : preferenceProductNotesForHtmlView // ignore: cast_nullable_to_non_nullable
                      as bool?,
            customMessageDashboard: freezed == customMessageDashboard
                ? _value.customMessageDashboard
                : customMessageDashboard // ignore: cast_nullable_to_non_nullable
                      as String?,
            customMessageUnpaidInvoice: freezed == customMessageUnpaidInvoice
                ? _value.customMessageUnpaidInvoice
                : customMessageUnpaidInvoice // ignore: cast_nullable_to_non_nullable
                      as String?,
            customMessagePaidInvoice: freezed == customMessagePaidInvoice
                ? _value.customMessagePaidInvoice
                : customMessagePaidInvoice // ignore: cast_nullable_to_non_nullable
                      as String?,
            customMessageUnapprovedQuote:
                freezed == customMessageUnapprovedQuote
                ? _value.customMessageUnapprovedQuote
                : customMessageUnapprovedQuote // ignore: cast_nullable_to_non_nullable
                      as String?,
            translations: freezed == translations
                ? _value.translations
                : translations // ignore: cast_nullable_to_non_nullable
                      as List<dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanySettingsApiImplCopyWith<$Res>
    implements $CompanySettingsApiCopyWith<$Res> {
  factory _$$CompanySettingsApiImplCopyWith(
    _$CompanySettingsApiImpl value,
    $Res Function(_$CompanySettingsApiImpl) then,
  ) = __$$CompanySettingsApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String? name,
    @JsonKey(name: 'company_logo') String? companyLogo,
    @JsonKey(name: 'company_logo_size') String? companyLogoSize,
    String? website,
    String? phone,
    String? email,
    String? address1,
    String? address2,
    String? city,
    String? state,
    @JsonKey(name: 'postal_code') String? postalCode,
    @JsonKey(name: 'country_id') String? countryId,
    @JsonKey(name: 'vat_number') String? vatNumber,
    @JsonKey(name: 'id_number') String? idNumber,
    String? classification,
    @JsonKey(name: 'qr_iban') String? qrIban,
    @JsonKey(name: 'besr_id') String? besrId,
    @JsonKey(name: 'custom_value1') String? customValue1,
    @JsonKey(name: 'custom_value2') String? customValue2,
    @JsonKey(name: 'custom_value3') String? customValue3,
    @JsonKey(name: 'custom_value4') String? customValue4,
    @JsonKey(name: 'timezone_id') String? timezoneId,
    @JsonKey(name: 'date_format_id') String? dateFormatId,
    @JsonKey(name: 'language_id') String? languageId,
    @JsonKey(name: 'currency_id') String? currencyId,
    @JsonKey(name: 'military_time') bool? militaryTime,
    @JsonKey(name: 'show_currency_code') bool? showCurrencyCode,
    @JsonKey(name: 'use_comma_as_decimal_place') bool? useCommaAsDecimalPlace,
    @JsonKey(name: 'first_month_of_year') String? firstMonthOfYear,
    @JsonKey(name: 'invoice_terms') String? invoiceTerms,
    @JsonKey(name: 'invoice_footer') String? invoiceFooter,
    @JsonKey(name: 'quote_terms') String? quoteTerms,
    @JsonKey(name: 'quote_footer') String? quoteFooter,
    @JsonKey(name: 'credit_terms') String? creditTerms,
    @JsonKey(name: 'credit_footer') String? creditFooter,
    @JsonKey(name: 'purchase_order_terms') String? purchaseOrderTerms,
    @JsonKey(name: 'purchase_order_footer') String? purchaseOrderFooter,
    @JsonKey(name: 'purchase_order_public_notes')
    String? purchaseOrderPublicNotes,
    @JsonKey(name: 'invoice_labels') String? invoiceLabels,
    @JsonKey(name: 'invoice_design_id') String? invoiceDesignId,
    @JsonKey(name: 'quote_design_id') String? quoteDesignId,
    @JsonKey(name: 'credit_design_id') String? creditDesignId,
    @JsonKey(name: 'purchase_order_design_id') String? purchaseOrderDesignId,
    @JsonKey(name: 'statement_design_id') String? statementDesignId,
    @JsonKey(name: 'delivery_note_design_id') String? deliveryNoteDesignId,
    @JsonKey(name: 'payment_receipt_design_id') String? paymentReceiptDesignId,
    @JsonKey(name: 'payment_refund_design_id') String? paymentRefundDesignId,
    @JsonKey(name: 'portal_design_id') String? portalDesignId,
    @JsonKey(name: 'invoice_number_pattern') String? invoiceNumberPattern,
    @JsonKey(name: 'invoice_number_counter') int? invoiceNumberCounter,
    @JsonKey(name: 'recurring_invoice_number_pattern')
    String? recurringInvoiceNumberPattern,
    @JsonKey(name: 'recurring_invoice_number_counter')
    int? recurringInvoiceNumberCounter,
    @JsonKey(name: 'quote_number_pattern') String? quoteNumberPattern,
    @JsonKey(name: 'quote_number_counter') int? quoteNumberCounter,
    @JsonKey(name: 'recurring_quote_number_pattern')
    String? recurringQuoteNumberPattern,
    @JsonKey(name: 'recurring_quote_number_counter')
    int? recurringQuoteNumberCounter,
    @JsonKey(name: 'client_number_pattern') String? clientNumberPattern,
    @JsonKey(name: 'client_number_counter') int? clientNumberCounter,
    @JsonKey(name: 'credit_number_pattern') String? creditNumberPattern,
    @JsonKey(name: 'credit_number_counter') int? creditNumberCounter,
    @JsonKey(name: 'task_number_pattern') String? taskNumberPattern,
    @JsonKey(name: 'task_number_counter') int? taskNumberCounter,
    @JsonKey(name: 'expense_number_pattern') String? expenseNumberPattern,
    @JsonKey(name: 'expense_number_counter') int? expenseNumberCounter,
    @JsonKey(name: 'recurring_expense_number_pattern')
    String? recurringExpenseNumberPattern,
    @JsonKey(name: 'recurring_expense_number_counter')
    int? recurringExpenseNumberCounter,
    @JsonKey(name: 'vendor_number_pattern') String? vendorNumberPattern,
    @JsonKey(name: 'vendor_number_counter') int? vendorNumberCounter,
    @JsonKey(name: 'ticket_number_pattern') String? ticketNumberPattern,
    @JsonKey(name: 'ticket_number_counter') int? ticketNumberCounter,
    @JsonKey(name: 'payment_number_pattern') String? paymentNumberPattern,
    @JsonKey(name: 'payment_number_counter') int? paymentNumberCounter,
    @JsonKey(name: 'project_number_pattern') String? projectNumberPattern,
    @JsonKey(name: 'project_number_counter') int? projectNumberCounter,
    @JsonKey(name: 'purchase_order_number_pattern')
    String? purchaseOrderNumberPattern,
    @JsonKey(name: 'purchase_order_number_counter')
    int? purchaseOrderNumberCounter,
    @JsonKey(name: 'shared_invoice_quote_counter')
    bool? sharedInvoiceQuoteCounter,
    @JsonKey(name: 'shared_invoice_credit_counter')
    bool? sharedInvoiceCreditCounter,
    @JsonKey(name: 'recurring_number_prefix') String? recurringNumberPrefix,
    @JsonKey(name: 'reset_counter_frequency_id') int? resetCounterFrequencyId,
    @JsonKey(name: 'reset_counter_date') String? resetCounterDate,
    @JsonKey(name: 'counter_padding') int? counterPadding,
    @JsonKey(name: 'counter_number_applied') String? counterNumberApplied,
    @JsonKey(name: 'quote_number_applied') String? quoteNumberApplied,
    @JsonKey(name: 'tax_name1') String? taxName1,
    @JsonKey(name: 'tax_rate1') double? taxRate1,
    @JsonKey(name: 'tax_name2') String? taxName2,
    @JsonKey(name: 'tax_rate2') double? taxRate2,
    @JsonKey(name: 'tax_name3') String? taxName3,
    @JsonKey(name: 'tax_rate3') double? taxRate3,
    @JsonKey(name: 'invoice_taxes') int? invoiceTaxes,
    @JsonKey(name: 'inclusive_taxes') bool? inclusiveTaxes,
    @JsonKey(name: 'enable_rappen_rounding') bool? enableRappenRounding,
    @JsonKey(name: 'email_sending_method') String? emailSendingMethod,
    @JsonKey(name: 'gmail_sending_user_id') String? gmailSendingUserId,
    @JsonKey(name: 'reply_to_email') String? replyToEmail,
    @JsonKey(name: 'reply_to_name') String? replyToName,
    @JsonKey(name: 'bcc_email') String? bccEmail,
    @JsonKey(name: 'email_from_name') String? emailFromName,
    @JsonKey(name: 'custom_sending_email') String? customSendingEmail,
    @JsonKey(name: 'email_style') String? emailStyle,
    @JsonKey(name: 'email_style_custom') String? emailStyleCustom,
    @JsonKey(name: 'email_signature') String? emailSignature,
    @JsonKey(name: 'enable_email_markup') bool? enableEmailMarkup,
    @JsonKey(name: 'show_email_footer') bool? showEmailFooter,
    @JsonKey(name: 'pdf_email_attachment') bool? pdfEmailAttachment,
    @JsonKey(name: 'ubl_email_attachment') bool? ublEmailAttachment,
    @JsonKey(name: 'document_email_attachment') bool? documentEmailAttachment,
    @JsonKey(name: 'send_email_on_mark_paid') bool? sendEmailOnMarkPaid,
    @JsonKey(name: 'payment_email_all_contacts') bool? paymentEmailAllContacts,
    @JsonKey(name: 'postmark_secret') String? postmarkSecret,
    @JsonKey(name: 'mailgun_secret') String? mailgunSecret,
    @JsonKey(name: 'mailgun_domain') String? mailgunDomain,
    @JsonKey(name: 'mailgun_endpoint') String? mailgunEndpoint,
    @JsonKey(name: 'brevo_secret') String? brevoSecret,
    @JsonKey(name: 'ses_secret_key') String? sesSecretKey,
    @JsonKey(name: 'ses_access_key') String? sesAccessKey,
    @JsonKey(name: 'ses_region') String? sesRegion,
    @JsonKey(name: 'ses_topic_arn') String? sesTopicArn,
    @JsonKey(name: 'ses_from_address') String? sesFromAddress,
    @JsonKey(name: 'email_subject_invoice') String? emailSubjectInvoice,
    @JsonKey(name: 'email_subject_quote') String? emailSubjectQuote,
    @JsonKey(name: 'email_subject_credit') String? emailSubjectCredit,
    @JsonKey(name: 'email_subject_payment') String? emailSubjectPayment,
    @JsonKey(name: 'email_subject_payment_partial')
    String? emailSubjectPaymentPartial,
    @JsonKey(name: 'email_subject_statement') String? emailSubjectStatement,
    @JsonKey(name: 'email_subject_purchase_order')
    String? emailSubjectPurchaseOrder,
    @JsonKey(name: 'email_subject_reminder1') String? emailSubjectReminder1,
    @JsonKey(name: 'email_subject_reminder2') String? emailSubjectReminder2,
    @JsonKey(name: 'email_subject_reminder3') String? emailSubjectReminder3,
    @JsonKey(name: 'email_subject_reminder_endless')
    String? emailSubjectReminderEndless,
    @JsonKey(name: 'email_subject_custom1') String? emailSubjectCustom1,
    @JsonKey(name: 'email_subject_custom2') String? emailSubjectCustom2,
    @JsonKey(name: 'email_subject_custom3') String? emailSubjectCustom3,
    @JsonKey(name: 'email_template_invoice') String? emailTemplateInvoice,
    @JsonKey(name: 'email_template_quote') String? emailTemplateQuote,
    @JsonKey(name: 'email_template_credit') String? emailTemplateCredit,
    @JsonKey(name: 'email_template_payment') String? emailTemplatePayment,
    @JsonKey(name: 'email_template_payment_partial')
    String? emailTemplatePaymentPartial,
    @JsonKey(name: 'email_template_statement') String? emailTemplateStatement,
    @JsonKey(name: 'email_template_purchase_order')
    String? emailTemplatePurchaseOrder,
    @JsonKey(name: 'email_template_reminder1') String? emailTemplateReminder1,
    @JsonKey(name: 'email_template_reminder2') String? emailTemplateReminder2,
    @JsonKey(name: 'email_template_reminder3') String? emailTemplateReminder3,
    @JsonKey(name: 'email_template_reminder_endless')
    String? emailTemplateReminderEndless,
    @JsonKey(name: 'email_template_custom1') String? emailTemplateCustom1,
    @JsonKey(name: 'email_template_custom2') String? emailTemplateCustom2,
    @JsonKey(name: 'email_template_custom3') String? emailTemplateCustom3,
    @JsonKey(name: 'send_reminders') bool? sendReminders,
    @JsonKey(name: 'enable_reminder1') bool? enableReminder1,
    @JsonKey(name: 'enable_reminder2') bool? enableReminder2,
    @JsonKey(name: 'enable_reminder3') bool? enableReminder3,
    @JsonKey(name: 'enable_reminder_endless') bool? enableReminderEndless,
    @JsonKey(name: 'num_days_reminder1') int? numDaysReminder1,
    @JsonKey(name: 'num_days_reminder2') int? numDaysReminder2,
    @JsonKey(name: 'num_days_reminder3') int? numDaysReminder3,
    @JsonKey(name: 'schedule_reminder1') String? scheduleReminder1,
    @JsonKey(name: 'schedule_reminder2') String? scheduleReminder2,
    @JsonKey(name: 'schedule_reminder3') String? scheduleReminder3,
    @JsonKey(name: 'reminder_send_time') int? reminderSendTime,
    @JsonKey(name: 'late_fee_amount1') double? lateFeeAmount1,
    @JsonKey(name: 'late_fee_amount2') double? lateFeeAmount2,
    @JsonKey(name: 'late_fee_amount3') double? lateFeeAmount3,
    @JsonKey(name: 'late_fee_percent1') double? lateFeePercent1,
    @JsonKey(name: 'late_fee_percent2') double? lateFeePercent2,
    @JsonKey(name: 'late_fee_percent3') double? lateFeePercent3,
    @JsonKey(name: 'endless_reminder_frequency_id')
    String? endlessReminderFrequencyId,
    @JsonKey(name: 'late_fee_endless_amount') double? lateFeeEndlessAmount,
    @JsonKey(name: 'late_fee_endless_percent') double? lateFeeEndlessPercent,
    @JsonKey(name: 'auto_archive_invoice') bool? autoArchiveInvoice,
    @JsonKey(name: 'auto_archive_invoice_cancelled')
    bool? autoArchiveInvoiceCancelled,
    @JsonKey(name: 'auto_archive_quote') bool? autoArchiveQuote,
    @JsonKey(name: 'auto_convert_quote') bool? autoConvertQuote,
    @JsonKey(name: 'auto_email_invoice') bool? autoEmailInvoice,
    @JsonKey(name: 'auto_bill_standard_invoices')
    bool? autoBillStandardInvoices,
    @JsonKey(name: 'auto_bill') String? autoBill,
    @JsonKey(name: 'auto_bill_date') String? autoBillDate,
    @JsonKey(name: 'lock_invoices') String? lockInvoices,
    @JsonKey(name: 'entity_send_time') int? entitySendTime,
    @JsonKey(name: 'show_accept_invoice_terms') bool? showAcceptInvoiceTerms,
    @JsonKey(name: 'show_accept_quote_terms') bool? showAcceptQuoteTerms,
    @JsonKey(name: 'require_invoice_signature') bool? requireInvoiceSignature,
    @JsonKey(name: 'require_quote_signature') bool? requireQuoteSignature,
    @JsonKey(name: 'require_purchase_order_signature')
    bool? requirePurchaseOrderSignature,
    @JsonKey(name: 'signature_on_pdf') bool? signatureOnPdf,
    @JsonKey(name: 'accept_client_input_quote_approval')
    bool? acceptClientInputQuoteApproval,
    @JsonKey(name: 'sync_invoice_quote_columns') bool? syncInvoiceQuoteColumns,
    @JsonKey(name: 'show_shipping_address') bool? showShippingAddress,
    @JsonKey(name: 'show_paid_stamp') bool? showPaidStamp,
    @JsonKey(name: 'page_size') String? pageSize,
    @JsonKey(name: 'page_layout') String? pageLayout,
    @JsonKey(name: 'font_size') int? fontSize,
    @JsonKey(name: 'primary_font') String? primaryFont,
    @JsonKey(name: 'secondary_font') String? secondaryFont,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'page_numbering') bool? pageNumbering,
    @JsonKey(name: 'page_numbering_alignment') String? pageNumberingAlignment,
    @JsonKey(name: 'hide_paid_to_date') bool? hidePaidToDate,
    @JsonKey(name: 'hide_empty_columns_on_pdf') bool? hideEmptyColumnsOnPdf,
    @JsonKey(name: 'embed_documents') bool? embedDocuments,
    @JsonKey(name: 'all_pages_header') bool? allPagesHeader,
    @JsonKey(name: 'all_pages_footer') bool? allPagesFooter,
    @JsonKey(name: 'pdf_variables') Map<String, List<String>>? pdfVariables,
    @JsonKey(name: 'show_pdfhtml_on_mobile') bool? showPdfhtmlOnMobile,
    @JsonKey(name: 'enable_client_portal') bool? enableClientPortal,
    @JsonKey(name: 'enable_client_portal_dashboard')
    bool? enableClientPortalDashboard,
    @JsonKey(name: 'enable_client_portal_tasks') bool? enableClientPortalTasks,
    @JsonKey(name: 'show_all_tasks_client_portal')
    String? showAllTasksClientPortal,
    @JsonKey(name: 'enable_client_portal_password')
    bool? enableClientPortalPassword,
    @JsonKey(name: 'client_portal_terms') String? clientPortalTerms,
    @JsonKey(name: 'client_portal_privacy_policy')
    String? clientPortalPrivacyPolicy,
    @JsonKey(name: 'client_portal_enable_uploads')
    bool? clientPortalEnableUploads,
    @JsonKey(name: 'client_portal_allow_under_payment')
    bool? clientPortalAllowUnderPayment,
    @JsonKey(name: 'client_portal_under_payment_minimum')
    double? clientPortalUnderPaymentMinimum,
    @JsonKey(name: 'client_portal_allow_over_payment')
    bool? clientPortalAllowOverPayment,
    @JsonKey(name: 'portal_custom_head') String? portalCustomHead,
    @JsonKey(name: 'portal_custom_css') String? portalCustomCss,
    @JsonKey(name: 'portal_custom_footer') String? portalCustomFooter,
    @JsonKey(name: 'portal_custom_js') String? portalCustomJs,
    @JsonKey(name: 'client_can_register') bool? clientCanRegister,
    @JsonKey(name: 'client_initiated_payments') bool? clientInitiatedPayments,
    @JsonKey(name: 'client_initiated_payments_minimum')
    double? clientInitiatedPaymentsMinimum,
    @JsonKey(name: 'enable_client_profile_update')
    bool? enableClientProfileUpdate,
    @JsonKey(name: 'client_online_payment_notification')
    bool? clientOnlinePaymentNotification,
    @JsonKey(name: 'client_manual_payment_notification')
    bool? clientManualPaymentNotification,
    @JsonKey(name: 'vendor_portal_enable_uploads')
    bool? vendorPortalEnableUploads,
    @JsonKey(name: 'use_credits_payment') String? useCreditsPayment,
    @JsonKey(name: 'use_unapplied_payment') String? useUnappliedPayment,
    @JsonKey(name: 'payment_terms') String? paymentTerms,
    @JsonKey(name: 'valid_until') String? validUntil,
    @JsonKey(name: 'payment_type_id') String? paymentTypeId,
    @JsonKey(name: 'default_expense_payment_type_id')
    String? defaultExpensePaymentTypeId,
    @JsonKey(name: 'company_gateway_ids') String? companyGatewayIds,
    @JsonKey(name: 'payment_flow') String? paymentFlow,
    @JsonKey(name: 'unlock_invoice_documents_after_payment')
    bool? unlockInvoiceDocumentsAfterPayment,
    @JsonKey(name: 'show_task_item_description') bool? showTaskItemDescription,
    @JsonKey(name: 'allow_billable_task_items') bool? allowBillableTaskItems,
    @JsonKey(name: 'default_task_rate') double? defaultTaskRate,
    @JsonKey(name: 'task_round_up') bool? taskRoundUp,
    @JsonKey(name: 'task_round_to_nearest') double? taskRoundToNearest,
    @JsonKey(name: 'enable_e_invoice') bool? enableEInvoice,
    @JsonKey(name: 'e_invoice_type') String? eInvoiceType,
    @JsonKey(name: 'e_quote_type') String? eQuoteType,
    @JsonKey(name: 'merge_e_invoice_to_pdf') bool? mergeEInvoiceToPdf,
    @JsonKey(name: 'skip_automatic_email_with_peppol')
    bool? skipAutomaticEmailWithPeppol,
    @JsonKey(name: 'e_invoice_forward_email') String? eInvoiceForwardEmail,
    @JsonKey(name: 'e_expense_forward_email') String? eExpenseForwardEmail,
    @JsonKey(name: 'preference_product_notes_for_html_view')
    bool? preferenceProductNotesForHtmlView,
    @JsonKey(name: 'custom_message_dashboard') String? customMessageDashboard,
    @JsonKey(name: 'custom_message_unpaid_invoice')
    String? customMessageUnpaidInvoice,
    @JsonKey(name: 'custom_message_paid_invoice')
    String? customMessagePaidInvoice,
    @JsonKey(name: 'custom_message_unapproved_quote')
    String? customMessageUnapprovedQuote,
    List<dynamic>? translations,
  });
}

/// @nodoc
class __$$CompanySettingsApiImplCopyWithImpl<$Res>
    extends _$CompanySettingsApiCopyWithImpl<$Res, _$CompanySettingsApiImpl>
    implements _$$CompanySettingsApiImplCopyWith<$Res> {
  __$$CompanySettingsApiImplCopyWithImpl(
    _$CompanySettingsApiImpl _value,
    $Res Function(_$CompanySettingsApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanySettingsApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? companyLogo = freezed,
    Object? companyLogoSize = freezed,
    Object? website = freezed,
    Object? phone = freezed,
    Object? email = freezed,
    Object? address1 = freezed,
    Object? address2 = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? postalCode = freezed,
    Object? countryId = freezed,
    Object? vatNumber = freezed,
    Object? idNumber = freezed,
    Object? classification = freezed,
    Object? qrIban = freezed,
    Object? besrId = freezed,
    Object? customValue1 = freezed,
    Object? customValue2 = freezed,
    Object? customValue3 = freezed,
    Object? customValue4 = freezed,
    Object? timezoneId = freezed,
    Object? dateFormatId = freezed,
    Object? languageId = freezed,
    Object? currencyId = freezed,
    Object? militaryTime = freezed,
    Object? showCurrencyCode = freezed,
    Object? useCommaAsDecimalPlace = freezed,
    Object? firstMonthOfYear = freezed,
    Object? invoiceTerms = freezed,
    Object? invoiceFooter = freezed,
    Object? quoteTerms = freezed,
    Object? quoteFooter = freezed,
    Object? creditTerms = freezed,
    Object? creditFooter = freezed,
    Object? purchaseOrderTerms = freezed,
    Object? purchaseOrderFooter = freezed,
    Object? purchaseOrderPublicNotes = freezed,
    Object? invoiceLabels = freezed,
    Object? invoiceDesignId = freezed,
    Object? quoteDesignId = freezed,
    Object? creditDesignId = freezed,
    Object? purchaseOrderDesignId = freezed,
    Object? statementDesignId = freezed,
    Object? deliveryNoteDesignId = freezed,
    Object? paymentReceiptDesignId = freezed,
    Object? paymentRefundDesignId = freezed,
    Object? portalDesignId = freezed,
    Object? invoiceNumberPattern = freezed,
    Object? invoiceNumberCounter = freezed,
    Object? recurringInvoiceNumberPattern = freezed,
    Object? recurringInvoiceNumberCounter = freezed,
    Object? quoteNumberPattern = freezed,
    Object? quoteNumberCounter = freezed,
    Object? recurringQuoteNumberPattern = freezed,
    Object? recurringQuoteNumberCounter = freezed,
    Object? clientNumberPattern = freezed,
    Object? clientNumberCounter = freezed,
    Object? creditNumberPattern = freezed,
    Object? creditNumberCounter = freezed,
    Object? taskNumberPattern = freezed,
    Object? taskNumberCounter = freezed,
    Object? expenseNumberPattern = freezed,
    Object? expenseNumberCounter = freezed,
    Object? recurringExpenseNumberPattern = freezed,
    Object? recurringExpenseNumberCounter = freezed,
    Object? vendorNumberPattern = freezed,
    Object? vendorNumberCounter = freezed,
    Object? ticketNumberPattern = freezed,
    Object? ticketNumberCounter = freezed,
    Object? paymentNumberPattern = freezed,
    Object? paymentNumberCounter = freezed,
    Object? projectNumberPattern = freezed,
    Object? projectNumberCounter = freezed,
    Object? purchaseOrderNumberPattern = freezed,
    Object? purchaseOrderNumberCounter = freezed,
    Object? sharedInvoiceQuoteCounter = freezed,
    Object? sharedInvoiceCreditCounter = freezed,
    Object? recurringNumberPrefix = freezed,
    Object? resetCounterFrequencyId = freezed,
    Object? resetCounterDate = freezed,
    Object? counterPadding = freezed,
    Object? counterNumberApplied = freezed,
    Object? quoteNumberApplied = freezed,
    Object? taxName1 = freezed,
    Object? taxRate1 = freezed,
    Object? taxName2 = freezed,
    Object? taxRate2 = freezed,
    Object? taxName3 = freezed,
    Object? taxRate3 = freezed,
    Object? invoiceTaxes = freezed,
    Object? inclusiveTaxes = freezed,
    Object? enableRappenRounding = freezed,
    Object? emailSendingMethod = freezed,
    Object? gmailSendingUserId = freezed,
    Object? replyToEmail = freezed,
    Object? replyToName = freezed,
    Object? bccEmail = freezed,
    Object? emailFromName = freezed,
    Object? customSendingEmail = freezed,
    Object? emailStyle = freezed,
    Object? emailStyleCustom = freezed,
    Object? emailSignature = freezed,
    Object? enableEmailMarkup = freezed,
    Object? showEmailFooter = freezed,
    Object? pdfEmailAttachment = freezed,
    Object? ublEmailAttachment = freezed,
    Object? documentEmailAttachment = freezed,
    Object? sendEmailOnMarkPaid = freezed,
    Object? paymentEmailAllContacts = freezed,
    Object? postmarkSecret = freezed,
    Object? mailgunSecret = freezed,
    Object? mailgunDomain = freezed,
    Object? mailgunEndpoint = freezed,
    Object? brevoSecret = freezed,
    Object? sesSecretKey = freezed,
    Object? sesAccessKey = freezed,
    Object? sesRegion = freezed,
    Object? sesTopicArn = freezed,
    Object? sesFromAddress = freezed,
    Object? emailSubjectInvoice = freezed,
    Object? emailSubjectQuote = freezed,
    Object? emailSubjectCredit = freezed,
    Object? emailSubjectPayment = freezed,
    Object? emailSubjectPaymentPartial = freezed,
    Object? emailSubjectStatement = freezed,
    Object? emailSubjectPurchaseOrder = freezed,
    Object? emailSubjectReminder1 = freezed,
    Object? emailSubjectReminder2 = freezed,
    Object? emailSubjectReminder3 = freezed,
    Object? emailSubjectReminderEndless = freezed,
    Object? emailSubjectCustom1 = freezed,
    Object? emailSubjectCustom2 = freezed,
    Object? emailSubjectCustom3 = freezed,
    Object? emailTemplateInvoice = freezed,
    Object? emailTemplateQuote = freezed,
    Object? emailTemplateCredit = freezed,
    Object? emailTemplatePayment = freezed,
    Object? emailTemplatePaymentPartial = freezed,
    Object? emailTemplateStatement = freezed,
    Object? emailTemplatePurchaseOrder = freezed,
    Object? emailTemplateReminder1 = freezed,
    Object? emailTemplateReminder2 = freezed,
    Object? emailTemplateReminder3 = freezed,
    Object? emailTemplateReminderEndless = freezed,
    Object? emailTemplateCustom1 = freezed,
    Object? emailTemplateCustom2 = freezed,
    Object? emailTemplateCustom3 = freezed,
    Object? sendReminders = freezed,
    Object? enableReminder1 = freezed,
    Object? enableReminder2 = freezed,
    Object? enableReminder3 = freezed,
    Object? enableReminderEndless = freezed,
    Object? numDaysReminder1 = freezed,
    Object? numDaysReminder2 = freezed,
    Object? numDaysReminder3 = freezed,
    Object? scheduleReminder1 = freezed,
    Object? scheduleReminder2 = freezed,
    Object? scheduleReminder3 = freezed,
    Object? reminderSendTime = freezed,
    Object? lateFeeAmount1 = freezed,
    Object? lateFeeAmount2 = freezed,
    Object? lateFeeAmount3 = freezed,
    Object? lateFeePercent1 = freezed,
    Object? lateFeePercent2 = freezed,
    Object? lateFeePercent3 = freezed,
    Object? endlessReminderFrequencyId = freezed,
    Object? lateFeeEndlessAmount = freezed,
    Object? lateFeeEndlessPercent = freezed,
    Object? autoArchiveInvoice = freezed,
    Object? autoArchiveInvoiceCancelled = freezed,
    Object? autoArchiveQuote = freezed,
    Object? autoConvertQuote = freezed,
    Object? autoEmailInvoice = freezed,
    Object? autoBillStandardInvoices = freezed,
    Object? autoBill = freezed,
    Object? autoBillDate = freezed,
    Object? lockInvoices = freezed,
    Object? entitySendTime = freezed,
    Object? showAcceptInvoiceTerms = freezed,
    Object? showAcceptQuoteTerms = freezed,
    Object? requireInvoiceSignature = freezed,
    Object? requireQuoteSignature = freezed,
    Object? requirePurchaseOrderSignature = freezed,
    Object? signatureOnPdf = freezed,
    Object? acceptClientInputQuoteApproval = freezed,
    Object? syncInvoiceQuoteColumns = freezed,
    Object? showShippingAddress = freezed,
    Object? showPaidStamp = freezed,
    Object? pageSize = freezed,
    Object? pageLayout = freezed,
    Object? fontSize = freezed,
    Object? primaryFont = freezed,
    Object? secondaryFont = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
    Object? pageNumbering = freezed,
    Object? pageNumberingAlignment = freezed,
    Object? hidePaidToDate = freezed,
    Object? hideEmptyColumnsOnPdf = freezed,
    Object? embedDocuments = freezed,
    Object? allPagesHeader = freezed,
    Object? allPagesFooter = freezed,
    Object? pdfVariables = freezed,
    Object? showPdfhtmlOnMobile = freezed,
    Object? enableClientPortal = freezed,
    Object? enableClientPortalDashboard = freezed,
    Object? enableClientPortalTasks = freezed,
    Object? showAllTasksClientPortal = freezed,
    Object? enableClientPortalPassword = freezed,
    Object? clientPortalTerms = freezed,
    Object? clientPortalPrivacyPolicy = freezed,
    Object? clientPortalEnableUploads = freezed,
    Object? clientPortalAllowUnderPayment = freezed,
    Object? clientPortalUnderPaymentMinimum = freezed,
    Object? clientPortalAllowOverPayment = freezed,
    Object? portalCustomHead = freezed,
    Object? portalCustomCss = freezed,
    Object? portalCustomFooter = freezed,
    Object? portalCustomJs = freezed,
    Object? clientCanRegister = freezed,
    Object? clientInitiatedPayments = freezed,
    Object? clientInitiatedPaymentsMinimum = freezed,
    Object? enableClientProfileUpdate = freezed,
    Object? clientOnlinePaymentNotification = freezed,
    Object? clientManualPaymentNotification = freezed,
    Object? vendorPortalEnableUploads = freezed,
    Object? useCreditsPayment = freezed,
    Object? useUnappliedPayment = freezed,
    Object? paymentTerms = freezed,
    Object? validUntil = freezed,
    Object? paymentTypeId = freezed,
    Object? defaultExpensePaymentTypeId = freezed,
    Object? companyGatewayIds = freezed,
    Object? paymentFlow = freezed,
    Object? unlockInvoiceDocumentsAfterPayment = freezed,
    Object? showTaskItemDescription = freezed,
    Object? allowBillableTaskItems = freezed,
    Object? defaultTaskRate = freezed,
    Object? taskRoundUp = freezed,
    Object? taskRoundToNearest = freezed,
    Object? enableEInvoice = freezed,
    Object? eInvoiceType = freezed,
    Object? eQuoteType = freezed,
    Object? mergeEInvoiceToPdf = freezed,
    Object? skipAutomaticEmailWithPeppol = freezed,
    Object? eInvoiceForwardEmail = freezed,
    Object? eExpenseForwardEmail = freezed,
    Object? preferenceProductNotesForHtmlView = freezed,
    Object? customMessageDashboard = freezed,
    Object? customMessageUnpaidInvoice = freezed,
    Object? customMessagePaidInvoice = freezed,
    Object? customMessageUnapprovedQuote = freezed,
    Object? translations = freezed,
  }) {
    return _then(
      _$CompanySettingsApiImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        companyLogo: freezed == companyLogo
            ? _value.companyLogo
            : companyLogo // ignore: cast_nullable_to_non_nullable
                  as String?,
        companyLogoSize: freezed == companyLogoSize
            ? _value.companyLogoSize
            : companyLogoSize // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        address1: freezed == address1
            ? _value.address1
            : address1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        address2: freezed == address2
            ? _value.address2
            : address2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        state: freezed == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String?,
        postalCode: freezed == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        countryId: freezed == countryId
            ? _value.countryId
            : countryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        vatNumber: freezed == vatNumber
            ? _value.vatNumber
            : vatNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        idNumber: freezed == idNumber
            ? _value.idNumber
            : idNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        classification: freezed == classification
            ? _value.classification
            : classification // ignore: cast_nullable_to_non_nullable
                  as String?,
        qrIban: freezed == qrIban
            ? _value.qrIban
            : qrIban // ignore: cast_nullable_to_non_nullable
                  as String?,
        besrId: freezed == besrId
            ? _value.besrId
            : besrId // ignore: cast_nullable_to_non_nullable
                  as String?,
        customValue1: freezed == customValue1
            ? _value.customValue1
            : customValue1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        customValue2: freezed == customValue2
            ? _value.customValue2
            : customValue2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        customValue3: freezed == customValue3
            ? _value.customValue3
            : customValue3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        customValue4: freezed == customValue4
            ? _value.customValue4
            : customValue4 // ignore: cast_nullable_to_non_nullable
                  as String?,
        timezoneId: freezed == timezoneId
            ? _value.timezoneId
            : timezoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateFormatId: freezed == dateFormatId
            ? _value.dateFormatId
            : dateFormatId // ignore: cast_nullable_to_non_nullable
                  as String?,
        languageId: freezed == languageId
            ? _value.languageId
            : languageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currencyId: freezed == currencyId
            ? _value.currencyId
            : currencyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        militaryTime: freezed == militaryTime
            ? _value.militaryTime
            : militaryTime // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showCurrencyCode: freezed == showCurrencyCode
            ? _value.showCurrencyCode
            : showCurrencyCode // ignore: cast_nullable_to_non_nullable
                  as bool?,
        useCommaAsDecimalPlace: freezed == useCommaAsDecimalPlace
            ? _value.useCommaAsDecimalPlace
            : useCommaAsDecimalPlace // ignore: cast_nullable_to_non_nullable
                  as bool?,
        firstMonthOfYear: freezed == firstMonthOfYear
            ? _value.firstMonthOfYear
            : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceTerms: freezed == invoiceTerms
            ? _value.invoiceTerms
            : invoiceTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceFooter: freezed == invoiceFooter
            ? _value.invoiceFooter
            : invoiceFooter // ignore: cast_nullable_to_non_nullable
                  as String?,
        quoteTerms: freezed == quoteTerms
            ? _value.quoteTerms
            : quoteTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        quoteFooter: freezed == quoteFooter
            ? _value.quoteFooter
            : quoteFooter // ignore: cast_nullable_to_non_nullable
                  as String?,
        creditTerms: freezed == creditTerms
            ? _value.creditTerms
            : creditTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        creditFooter: freezed == creditFooter
            ? _value.creditFooter
            : creditFooter // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseOrderTerms: freezed == purchaseOrderTerms
            ? _value.purchaseOrderTerms
            : purchaseOrderTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseOrderFooter: freezed == purchaseOrderFooter
            ? _value.purchaseOrderFooter
            : purchaseOrderFooter // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseOrderPublicNotes: freezed == purchaseOrderPublicNotes
            ? _value.purchaseOrderPublicNotes
            : purchaseOrderPublicNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceLabels: freezed == invoiceLabels
            ? _value.invoiceLabels
            : invoiceLabels // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceDesignId: freezed == invoiceDesignId
            ? _value.invoiceDesignId
            : invoiceDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        quoteDesignId: freezed == quoteDesignId
            ? _value.quoteDesignId
            : quoteDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        creditDesignId: freezed == creditDesignId
            ? _value.creditDesignId
            : creditDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseOrderDesignId: freezed == purchaseOrderDesignId
            ? _value.purchaseOrderDesignId
            : purchaseOrderDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        statementDesignId: freezed == statementDesignId
            ? _value.statementDesignId
            : statementDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deliveryNoteDesignId: freezed == deliveryNoteDesignId
            ? _value.deliveryNoteDesignId
            : deliveryNoteDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentReceiptDesignId: freezed == paymentReceiptDesignId
            ? _value.paymentReceiptDesignId
            : paymentReceiptDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentRefundDesignId: freezed == paymentRefundDesignId
            ? _value.paymentRefundDesignId
            : paymentRefundDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        portalDesignId: freezed == portalDesignId
            ? _value.portalDesignId
            : portalDesignId // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceNumberPattern: freezed == invoiceNumberPattern
            ? _value.invoiceNumberPattern
            : invoiceNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceNumberCounter: freezed == invoiceNumberCounter
            ? _value.invoiceNumberCounter
            : invoiceNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurringInvoiceNumberPattern: freezed == recurringInvoiceNumberPattern
            ? _value.recurringInvoiceNumberPattern
            : recurringInvoiceNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurringInvoiceNumberCounter: freezed == recurringInvoiceNumberCounter
            ? _value.recurringInvoiceNumberCounter
            : recurringInvoiceNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        quoteNumberPattern: freezed == quoteNumberPattern
            ? _value.quoteNumberPattern
            : quoteNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        quoteNumberCounter: freezed == quoteNumberCounter
            ? _value.quoteNumberCounter
            : quoteNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurringQuoteNumberPattern: freezed == recurringQuoteNumberPattern
            ? _value.recurringQuoteNumberPattern
            : recurringQuoteNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurringQuoteNumberCounter: freezed == recurringQuoteNumberCounter
            ? _value.recurringQuoteNumberCounter
            : recurringQuoteNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        clientNumberPattern: freezed == clientNumberPattern
            ? _value.clientNumberPattern
            : clientNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientNumberCounter: freezed == clientNumberCounter
            ? _value.clientNumberCounter
            : clientNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        creditNumberPattern: freezed == creditNumberPattern
            ? _value.creditNumberPattern
            : creditNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        creditNumberCounter: freezed == creditNumberCounter
            ? _value.creditNumberCounter
            : creditNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        taskNumberPattern: freezed == taskNumberPattern
            ? _value.taskNumberPattern
            : taskNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        taskNumberCounter: freezed == taskNumberCounter
            ? _value.taskNumberCounter
            : taskNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        expenseNumberPattern: freezed == expenseNumberPattern
            ? _value.expenseNumberPattern
            : expenseNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        expenseNumberCounter: freezed == expenseNumberCounter
            ? _value.expenseNumberCounter
            : expenseNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurringExpenseNumberPattern: freezed == recurringExpenseNumberPattern
            ? _value.recurringExpenseNumberPattern
            : recurringExpenseNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurringExpenseNumberCounter: freezed == recurringExpenseNumberCounter
            ? _value.recurringExpenseNumberCounter
            : recurringExpenseNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        vendorNumberPattern: freezed == vendorNumberPattern
            ? _value.vendorNumberPattern
            : vendorNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        vendorNumberCounter: freezed == vendorNumberCounter
            ? _value.vendorNumberCounter
            : vendorNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        ticketNumberPattern: freezed == ticketNumberPattern
            ? _value.ticketNumberPattern
            : ticketNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        ticketNumberCounter: freezed == ticketNumberCounter
            ? _value.ticketNumberCounter
            : ticketNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        paymentNumberPattern: freezed == paymentNumberPattern
            ? _value.paymentNumberPattern
            : paymentNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentNumberCounter: freezed == paymentNumberCounter
            ? _value.paymentNumberCounter
            : paymentNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        projectNumberPattern: freezed == projectNumberPattern
            ? _value.projectNumberPattern
            : projectNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectNumberCounter: freezed == projectNumberCounter
            ? _value.projectNumberCounter
            : projectNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        purchaseOrderNumberPattern: freezed == purchaseOrderNumberPattern
            ? _value.purchaseOrderNumberPattern
            : purchaseOrderNumberPattern // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseOrderNumberCounter: freezed == purchaseOrderNumberCounter
            ? _value.purchaseOrderNumberCounter
            : purchaseOrderNumberCounter // ignore: cast_nullable_to_non_nullable
                  as int?,
        sharedInvoiceQuoteCounter: freezed == sharedInvoiceQuoteCounter
            ? _value.sharedInvoiceQuoteCounter
            : sharedInvoiceQuoteCounter // ignore: cast_nullable_to_non_nullable
                  as bool?,
        sharedInvoiceCreditCounter: freezed == sharedInvoiceCreditCounter
            ? _value.sharedInvoiceCreditCounter
            : sharedInvoiceCreditCounter // ignore: cast_nullable_to_non_nullable
                  as bool?,
        recurringNumberPrefix: freezed == recurringNumberPrefix
            ? _value.recurringNumberPrefix
            : recurringNumberPrefix // ignore: cast_nullable_to_non_nullable
                  as String?,
        resetCounterFrequencyId: freezed == resetCounterFrequencyId
            ? _value.resetCounterFrequencyId
            : resetCounterFrequencyId // ignore: cast_nullable_to_non_nullable
                  as int?,
        resetCounterDate: freezed == resetCounterDate
            ? _value.resetCounterDate
            : resetCounterDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        counterPadding: freezed == counterPadding
            ? _value.counterPadding
            : counterPadding // ignore: cast_nullable_to_non_nullable
                  as int?,
        counterNumberApplied: freezed == counterNumberApplied
            ? _value.counterNumberApplied
            : counterNumberApplied // ignore: cast_nullable_to_non_nullable
                  as String?,
        quoteNumberApplied: freezed == quoteNumberApplied
            ? _value.quoteNumberApplied
            : quoteNumberApplied // ignore: cast_nullable_to_non_nullable
                  as String?,
        taxName1: freezed == taxName1
            ? _value.taxName1
            : taxName1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        taxRate1: freezed == taxRate1
            ? _value.taxRate1
            : taxRate1 // ignore: cast_nullable_to_non_nullable
                  as double?,
        taxName2: freezed == taxName2
            ? _value.taxName2
            : taxName2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        taxRate2: freezed == taxRate2
            ? _value.taxRate2
            : taxRate2 // ignore: cast_nullable_to_non_nullable
                  as double?,
        taxName3: freezed == taxName3
            ? _value.taxName3
            : taxName3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        taxRate3: freezed == taxRate3
            ? _value.taxRate3
            : taxRate3 // ignore: cast_nullable_to_non_nullable
                  as double?,
        invoiceTaxes: freezed == invoiceTaxes
            ? _value.invoiceTaxes
            : invoiceTaxes // ignore: cast_nullable_to_non_nullable
                  as int?,
        inclusiveTaxes: freezed == inclusiveTaxes
            ? _value.inclusiveTaxes
            : inclusiveTaxes // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableRappenRounding: freezed == enableRappenRounding
            ? _value.enableRappenRounding
            : enableRappenRounding // ignore: cast_nullable_to_non_nullable
                  as bool?,
        emailSendingMethod: freezed == emailSendingMethod
            ? _value.emailSendingMethod
            : emailSendingMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        gmailSendingUserId: freezed == gmailSendingUserId
            ? _value.gmailSendingUserId
            : gmailSendingUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        replyToEmail: freezed == replyToEmail
            ? _value.replyToEmail
            : replyToEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        replyToName: freezed == replyToName
            ? _value.replyToName
            : replyToName // ignore: cast_nullable_to_non_nullable
                  as String?,
        bccEmail: freezed == bccEmail
            ? _value.bccEmail
            : bccEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailFromName: freezed == emailFromName
            ? _value.emailFromName
            : emailFromName // ignore: cast_nullable_to_non_nullable
                  as String?,
        customSendingEmail: freezed == customSendingEmail
            ? _value.customSendingEmail
            : customSendingEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailStyle: freezed == emailStyle
            ? _value.emailStyle
            : emailStyle // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailStyleCustom: freezed == emailStyleCustom
            ? _value.emailStyleCustom
            : emailStyleCustom // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSignature: freezed == emailSignature
            ? _value.emailSignature
            : emailSignature // ignore: cast_nullable_to_non_nullable
                  as String?,
        enableEmailMarkup: freezed == enableEmailMarkup
            ? _value.enableEmailMarkup
            : enableEmailMarkup // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showEmailFooter: freezed == showEmailFooter
            ? _value.showEmailFooter
            : showEmailFooter // ignore: cast_nullable_to_non_nullable
                  as bool?,
        pdfEmailAttachment: freezed == pdfEmailAttachment
            ? _value.pdfEmailAttachment
            : pdfEmailAttachment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        ublEmailAttachment: freezed == ublEmailAttachment
            ? _value.ublEmailAttachment
            : ublEmailAttachment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        documentEmailAttachment: freezed == documentEmailAttachment
            ? _value.documentEmailAttachment
            : documentEmailAttachment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        sendEmailOnMarkPaid: freezed == sendEmailOnMarkPaid
            ? _value.sendEmailOnMarkPaid
            : sendEmailOnMarkPaid // ignore: cast_nullable_to_non_nullable
                  as bool?,
        paymentEmailAllContacts: freezed == paymentEmailAllContacts
            ? _value.paymentEmailAllContacts
            : paymentEmailAllContacts // ignore: cast_nullable_to_non_nullable
                  as bool?,
        postmarkSecret: freezed == postmarkSecret
            ? _value.postmarkSecret
            : postmarkSecret // ignore: cast_nullable_to_non_nullable
                  as String?,
        mailgunSecret: freezed == mailgunSecret
            ? _value.mailgunSecret
            : mailgunSecret // ignore: cast_nullable_to_non_nullable
                  as String?,
        mailgunDomain: freezed == mailgunDomain
            ? _value.mailgunDomain
            : mailgunDomain // ignore: cast_nullable_to_non_nullable
                  as String?,
        mailgunEndpoint: freezed == mailgunEndpoint
            ? _value.mailgunEndpoint
            : mailgunEndpoint // ignore: cast_nullable_to_non_nullable
                  as String?,
        brevoSecret: freezed == brevoSecret
            ? _value.brevoSecret
            : brevoSecret // ignore: cast_nullable_to_non_nullable
                  as String?,
        sesSecretKey: freezed == sesSecretKey
            ? _value.sesSecretKey
            : sesSecretKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        sesAccessKey: freezed == sesAccessKey
            ? _value.sesAccessKey
            : sesAccessKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        sesRegion: freezed == sesRegion
            ? _value.sesRegion
            : sesRegion // ignore: cast_nullable_to_non_nullable
                  as String?,
        sesTopicArn: freezed == sesTopicArn
            ? _value.sesTopicArn
            : sesTopicArn // ignore: cast_nullable_to_non_nullable
                  as String?,
        sesFromAddress: freezed == sesFromAddress
            ? _value.sesFromAddress
            : sesFromAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectInvoice: freezed == emailSubjectInvoice
            ? _value.emailSubjectInvoice
            : emailSubjectInvoice // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectQuote: freezed == emailSubjectQuote
            ? _value.emailSubjectQuote
            : emailSubjectQuote // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectCredit: freezed == emailSubjectCredit
            ? _value.emailSubjectCredit
            : emailSubjectCredit // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectPayment: freezed == emailSubjectPayment
            ? _value.emailSubjectPayment
            : emailSubjectPayment // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectPaymentPartial: freezed == emailSubjectPaymentPartial
            ? _value.emailSubjectPaymentPartial
            : emailSubjectPaymentPartial // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectStatement: freezed == emailSubjectStatement
            ? _value.emailSubjectStatement
            : emailSubjectStatement // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectPurchaseOrder: freezed == emailSubjectPurchaseOrder
            ? _value.emailSubjectPurchaseOrder
            : emailSubjectPurchaseOrder // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectReminder1: freezed == emailSubjectReminder1
            ? _value.emailSubjectReminder1
            : emailSubjectReminder1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectReminder2: freezed == emailSubjectReminder2
            ? _value.emailSubjectReminder2
            : emailSubjectReminder2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectReminder3: freezed == emailSubjectReminder3
            ? _value.emailSubjectReminder3
            : emailSubjectReminder3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectReminderEndless: freezed == emailSubjectReminderEndless
            ? _value.emailSubjectReminderEndless
            : emailSubjectReminderEndless // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectCustom1: freezed == emailSubjectCustom1
            ? _value.emailSubjectCustom1
            : emailSubjectCustom1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectCustom2: freezed == emailSubjectCustom2
            ? _value.emailSubjectCustom2
            : emailSubjectCustom2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailSubjectCustom3: freezed == emailSubjectCustom3
            ? _value.emailSubjectCustom3
            : emailSubjectCustom3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateInvoice: freezed == emailTemplateInvoice
            ? _value.emailTemplateInvoice
            : emailTemplateInvoice // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateQuote: freezed == emailTemplateQuote
            ? _value.emailTemplateQuote
            : emailTemplateQuote // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateCredit: freezed == emailTemplateCredit
            ? _value.emailTemplateCredit
            : emailTemplateCredit // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplatePayment: freezed == emailTemplatePayment
            ? _value.emailTemplatePayment
            : emailTemplatePayment // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplatePaymentPartial: freezed == emailTemplatePaymentPartial
            ? _value.emailTemplatePaymentPartial
            : emailTemplatePaymentPartial // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateStatement: freezed == emailTemplateStatement
            ? _value.emailTemplateStatement
            : emailTemplateStatement // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplatePurchaseOrder: freezed == emailTemplatePurchaseOrder
            ? _value.emailTemplatePurchaseOrder
            : emailTemplatePurchaseOrder // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateReminder1: freezed == emailTemplateReminder1
            ? _value.emailTemplateReminder1
            : emailTemplateReminder1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateReminder2: freezed == emailTemplateReminder2
            ? _value.emailTemplateReminder2
            : emailTemplateReminder2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateReminder3: freezed == emailTemplateReminder3
            ? _value.emailTemplateReminder3
            : emailTemplateReminder3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateReminderEndless: freezed == emailTemplateReminderEndless
            ? _value.emailTemplateReminderEndless
            : emailTemplateReminderEndless // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateCustom1: freezed == emailTemplateCustom1
            ? _value.emailTemplateCustom1
            : emailTemplateCustom1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateCustom2: freezed == emailTemplateCustom2
            ? _value.emailTemplateCustom2
            : emailTemplateCustom2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emailTemplateCustom3: freezed == emailTemplateCustom3
            ? _value.emailTemplateCustom3
            : emailTemplateCustom3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        sendReminders: freezed == sendReminders
            ? _value.sendReminders
            : sendReminders // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableReminder1: freezed == enableReminder1
            ? _value.enableReminder1
            : enableReminder1 // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableReminder2: freezed == enableReminder2
            ? _value.enableReminder2
            : enableReminder2 // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableReminder3: freezed == enableReminder3
            ? _value.enableReminder3
            : enableReminder3 // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableReminderEndless: freezed == enableReminderEndless
            ? _value.enableReminderEndless
            : enableReminderEndless // ignore: cast_nullable_to_non_nullable
                  as bool?,
        numDaysReminder1: freezed == numDaysReminder1
            ? _value.numDaysReminder1
            : numDaysReminder1 // ignore: cast_nullable_to_non_nullable
                  as int?,
        numDaysReminder2: freezed == numDaysReminder2
            ? _value.numDaysReminder2
            : numDaysReminder2 // ignore: cast_nullable_to_non_nullable
                  as int?,
        numDaysReminder3: freezed == numDaysReminder3
            ? _value.numDaysReminder3
            : numDaysReminder3 // ignore: cast_nullable_to_non_nullable
                  as int?,
        scheduleReminder1: freezed == scheduleReminder1
            ? _value.scheduleReminder1
            : scheduleReminder1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        scheduleReminder2: freezed == scheduleReminder2
            ? _value.scheduleReminder2
            : scheduleReminder2 // ignore: cast_nullable_to_non_nullable
                  as String?,
        scheduleReminder3: freezed == scheduleReminder3
            ? _value.scheduleReminder3
            : scheduleReminder3 // ignore: cast_nullable_to_non_nullable
                  as String?,
        reminderSendTime: freezed == reminderSendTime
            ? _value.reminderSendTime
            : reminderSendTime // ignore: cast_nullable_to_non_nullable
                  as int?,
        lateFeeAmount1: freezed == lateFeeAmount1
            ? _value.lateFeeAmount1
            : lateFeeAmount1 // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeeAmount2: freezed == lateFeeAmount2
            ? _value.lateFeeAmount2
            : lateFeeAmount2 // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeeAmount3: freezed == lateFeeAmount3
            ? _value.lateFeeAmount3
            : lateFeeAmount3 // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeePercent1: freezed == lateFeePercent1
            ? _value.lateFeePercent1
            : lateFeePercent1 // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeePercent2: freezed == lateFeePercent2
            ? _value.lateFeePercent2
            : lateFeePercent2 // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeePercent3: freezed == lateFeePercent3
            ? _value.lateFeePercent3
            : lateFeePercent3 // ignore: cast_nullable_to_non_nullable
                  as double?,
        endlessReminderFrequencyId: freezed == endlessReminderFrequencyId
            ? _value.endlessReminderFrequencyId
            : endlessReminderFrequencyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lateFeeEndlessAmount: freezed == lateFeeEndlessAmount
            ? _value.lateFeeEndlessAmount
            : lateFeeEndlessAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        lateFeeEndlessPercent: freezed == lateFeeEndlessPercent
            ? _value.lateFeeEndlessPercent
            : lateFeeEndlessPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        autoArchiveInvoice: freezed == autoArchiveInvoice
            ? _value.autoArchiveInvoice
            : autoArchiveInvoice // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoArchiveInvoiceCancelled: freezed == autoArchiveInvoiceCancelled
            ? _value.autoArchiveInvoiceCancelled
            : autoArchiveInvoiceCancelled // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoArchiveQuote: freezed == autoArchiveQuote
            ? _value.autoArchiveQuote
            : autoArchiveQuote // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoConvertQuote: freezed == autoConvertQuote
            ? _value.autoConvertQuote
            : autoConvertQuote // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoEmailInvoice: freezed == autoEmailInvoice
            ? _value.autoEmailInvoice
            : autoEmailInvoice // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoBillStandardInvoices: freezed == autoBillStandardInvoices
            ? _value.autoBillStandardInvoices
            : autoBillStandardInvoices // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoBill: freezed == autoBill
            ? _value.autoBill
            : autoBill // ignore: cast_nullable_to_non_nullable
                  as String?,
        autoBillDate: freezed == autoBillDate
            ? _value.autoBillDate
            : autoBillDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        lockInvoices: freezed == lockInvoices
            ? _value.lockInvoices
            : lockInvoices // ignore: cast_nullable_to_non_nullable
                  as String?,
        entitySendTime: freezed == entitySendTime
            ? _value.entitySendTime
            : entitySendTime // ignore: cast_nullable_to_non_nullable
                  as int?,
        showAcceptInvoiceTerms: freezed == showAcceptInvoiceTerms
            ? _value.showAcceptInvoiceTerms
            : showAcceptInvoiceTerms // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showAcceptQuoteTerms: freezed == showAcceptQuoteTerms
            ? _value.showAcceptQuoteTerms
            : showAcceptQuoteTerms // ignore: cast_nullable_to_non_nullable
                  as bool?,
        requireInvoiceSignature: freezed == requireInvoiceSignature
            ? _value.requireInvoiceSignature
            : requireInvoiceSignature // ignore: cast_nullable_to_non_nullable
                  as bool?,
        requireQuoteSignature: freezed == requireQuoteSignature
            ? _value.requireQuoteSignature
            : requireQuoteSignature // ignore: cast_nullable_to_non_nullable
                  as bool?,
        requirePurchaseOrderSignature: freezed == requirePurchaseOrderSignature
            ? _value.requirePurchaseOrderSignature
            : requirePurchaseOrderSignature // ignore: cast_nullable_to_non_nullable
                  as bool?,
        signatureOnPdf: freezed == signatureOnPdf
            ? _value.signatureOnPdf
            : signatureOnPdf // ignore: cast_nullable_to_non_nullable
                  as bool?,
        acceptClientInputQuoteApproval:
            freezed == acceptClientInputQuoteApproval
            ? _value.acceptClientInputQuoteApproval
            : acceptClientInputQuoteApproval // ignore: cast_nullable_to_non_nullable
                  as bool?,
        syncInvoiceQuoteColumns: freezed == syncInvoiceQuoteColumns
            ? _value.syncInvoiceQuoteColumns
            : syncInvoiceQuoteColumns // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showShippingAddress: freezed == showShippingAddress
            ? _value.showShippingAddress
            : showShippingAddress // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showPaidStamp: freezed == showPaidStamp
            ? _value.showPaidStamp
            : showPaidStamp // ignore: cast_nullable_to_non_nullable
                  as bool?,
        pageSize: freezed == pageSize
            ? _value.pageSize
            : pageSize // ignore: cast_nullable_to_non_nullable
                  as String?,
        pageLayout: freezed == pageLayout
            ? _value.pageLayout
            : pageLayout // ignore: cast_nullable_to_non_nullable
                  as String?,
        fontSize: freezed == fontSize
            ? _value.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        primaryFont: freezed == primaryFont
            ? _value.primaryFont
            : primaryFont // ignore: cast_nullable_to_non_nullable
                  as String?,
        secondaryFont: freezed == secondaryFont
            ? _value.secondaryFont
            : secondaryFont // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryColor: freezed == primaryColor
            ? _value.primaryColor
            : primaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        secondaryColor: freezed == secondaryColor
            ? _value.secondaryColor
            : secondaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        pageNumbering: freezed == pageNumbering
            ? _value.pageNumbering
            : pageNumbering // ignore: cast_nullable_to_non_nullable
                  as bool?,
        pageNumberingAlignment: freezed == pageNumberingAlignment
            ? _value.pageNumberingAlignment
            : pageNumberingAlignment // ignore: cast_nullable_to_non_nullable
                  as String?,
        hidePaidToDate: freezed == hidePaidToDate
            ? _value.hidePaidToDate
            : hidePaidToDate // ignore: cast_nullable_to_non_nullable
                  as bool?,
        hideEmptyColumnsOnPdf: freezed == hideEmptyColumnsOnPdf
            ? _value.hideEmptyColumnsOnPdf
            : hideEmptyColumnsOnPdf // ignore: cast_nullable_to_non_nullable
                  as bool?,
        embedDocuments: freezed == embedDocuments
            ? _value.embedDocuments
            : embedDocuments // ignore: cast_nullable_to_non_nullable
                  as bool?,
        allPagesHeader: freezed == allPagesHeader
            ? _value.allPagesHeader
            : allPagesHeader // ignore: cast_nullable_to_non_nullable
                  as bool?,
        allPagesFooter: freezed == allPagesFooter
            ? _value.allPagesFooter
            : allPagesFooter // ignore: cast_nullable_to_non_nullable
                  as bool?,
        pdfVariables: freezed == pdfVariables
            ? _value._pdfVariables
            : pdfVariables // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>?,
        showPdfhtmlOnMobile: freezed == showPdfhtmlOnMobile
            ? _value.showPdfhtmlOnMobile
            : showPdfhtmlOnMobile // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableClientPortal: freezed == enableClientPortal
            ? _value.enableClientPortal
            : enableClientPortal // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableClientPortalDashboard: freezed == enableClientPortalDashboard
            ? _value.enableClientPortalDashboard
            : enableClientPortalDashboard // ignore: cast_nullable_to_non_nullable
                  as bool?,
        enableClientPortalTasks: freezed == enableClientPortalTasks
            ? _value.enableClientPortalTasks
            : enableClientPortalTasks // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showAllTasksClientPortal: freezed == showAllTasksClientPortal
            ? _value.showAllTasksClientPortal
            : showAllTasksClientPortal // ignore: cast_nullable_to_non_nullable
                  as String?,
        enableClientPortalPassword: freezed == enableClientPortalPassword
            ? _value.enableClientPortalPassword
            : enableClientPortalPassword // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientPortalTerms: freezed == clientPortalTerms
            ? _value.clientPortalTerms
            : clientPortalTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientPortalPrivacyPolicy: freezed == clientPortalPrivacyPolicy
            ? _value.clientPortalPrivacyPolicy
            : clientPortalPrivacyPolicy // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientPortalEnableUploads: freezed == clientPortalEnableUploads
            ? _value.clientPortalEnableUploads
            : clientPortalEnableUploads // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientPortalAllowUnderPayment: freezed == clientPortalAllowUnderPayment
            ? _value.clientPortalAllowUnderPayment
            : clientPortalAllowUnderPayment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientPortalUnderPaymentMinimum:
            freezed == clientPortalUnderPaymentMinimum
            ? _value.clientPortalUnderPaymentMinimum
            : clientPortalUnderPaymentMinimum // ignore: cast_nullable_to_non_nullable
                  as double?,
        clientPortalAllowOverPayment: freezed == clientPortalAllowOverPayment
            ? _value.clientPortalAllowOverPayment
            : clientPortalAllowOverPayment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        portalCustomHead: freezed == portalCustomHead
            ? _value.portalCustomHead
            : portalCustomHead // ignore: cast_nullable_to_non_nullable
                  as String?,
        portalCustomCss: freezed == portalCustomCss
            ? _value.portalCustomCss
            : portalCustomCss // ignore: cast_nullable_to_non_nullable
                  as String?,
        portalCustomFooter: freezed == portalCustomFooter
            ? _value.portalCustomFooter
            : portalCustomFooter // ignore: cast_nullable_to_non_nullable
                  as String?,
        portalCustomJs: freezed == portalCustomJs
            ? _value.portalCustomJs
            : portalCustomJs // ignore: cast_nullable_to_non_nullable
                  as String?,
        clientCanRegister: freezed == clientCanRegister
            ? _value.clientCanRegister
            : clientCanRegister // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientInitiatedPayments: freezed == clientInitiatedPayments
            ? _value.clientInitiatedPayments
            : clientInitiatedPayments // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientInitiatedPaymentsMinimum:
            freezed == clientInitiatedPaymentsMinimum
            ? _value.clientInitiatedPaymentsMinimum
            : clientInitiatedPaymentsMinimum // ignore: cast_nullable_to_non_nullable
                  as double?,
        enableClientProfileUpdate: freezed == enableClientProfileUpdate
            ? _value.enableClientProfileUpdate
            : enableClientProfileUpdate // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientOnlinePaymentNotification:
            freezed == clientOnlinePaymentNotification
            ? _value.clientOnlinePaymentNotification
            : clientOnlinePaymentNotification // ignore: cast_nullable_to_non_nullable
                  as bool?,
        clientManualPaymentNotification:
            freezed == clientManualPaymentNotification
            ? _value.clientManualPaymentNotification
            : clientManualPaymentNotification // ignore: cast_nullable_to_non_nullable
                  as bool?,
        vendorPortalEnableUploads: freezed == vendorPortalEnableUploads
            ? _value.vendorPortalEnableUploads
            : vendorPortalEnableUploads // ignore: cast_nullable_to_non_nullable
                  as bool?,
        useCreditsPayment: freezed == useCreditsPayment
            ? _value.useCreditsPayment
            : useCreditsPayment // ignore: cast_nullable_to_non_nullable
                  as String?,
        useUnappliedPayment: freezed == useUnappliedPayment
            ? _value.useUnappliedPayment
            : useUnappliedPayment // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentTerms: freezed == paymentTerms
            ? _value.paymentTerms
            : paymentTerms // ignore: cast_nullable_to_non_nullable
                  as String?,
        validUntil: freezed == validUntil
            ? _value.validUntil
            : validUntil // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentTypeId: freezed == paymentTypeId
            ? _value.paymentTypeId
            : paymentTypeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        defaultExpensePaymentTypeId: freezed == defaultExpensePaymentTypeId
            ? _value.defaultExpensePaymentTypeId
            : defaultExpensePaymentTypeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        companyGatewayIds: freezed == companyGatewayIds
            ? _value.companyGatewayIds
            : companyGatewayIds // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentFlow: freezed == paymentFlow
            ? _value.paymentFlow
            : paymentFlow // ignore: cast_nullable_to_non_nullable
                  as String?,
        unlockInvoiceDocumentsAfterPayment:
            freezed == unlockInvoiceDocumentsAfterPayment
            ? _value.unlockInvoiceDocumentsAfterPayment
            : unlockInvoiceDocumentsAfterPayment // ignore: cast_nullable_to_non_nullable
                  as bool?,
        showTaskItemDescription: freezed == showTaskItemDescription
            ? _value.showTaskItemDescription
            : showTaskItemDescription // ignore: cast_nullable_to_non_nullable
                  as bool?,
        allowBillableTaskItems: freezed == allowBillableTaskItems
            ? _value.allowBillableTaskItems
            : allowBillableTaskItems // ignore: cast_nullable_to_non_nullable
                  as bool?,
        defaultTaskRate: freezed == defaultTaskRate
            ? _value.defaultTaskRate
            : defaultTaskRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        taskRoundUp: freezed == taskRoundUp
            ? _value.taskRoundUp
            : taskRoundUp // ignore: cast_nullable_to_non_nullable
                  as bool?,
        taskRoundToNearest: freezed == taskRoundToNearest
            ? _value.taskRoundToNearest
            : taskRoundToNearest // ignore: cast_nullable_to_non_nullable
                  as double?,
        enableEInvoice: freezed == enableEInvoice
            ? _value.enableEInvoice
            : enableEInvoice // ignore: cast_nullable_to_non_nullable
                  as bool?,
        eInvoiceType: freezed == eInvoiceType
            ? _value.eInvoiceType
            : eInvoiceType // ignore: cast_nullable_to_non_nullable
                  as String?,
        eQuoteType: freezed == eQuoteType
            ? _value.eQuoteType
            : eQuoteType // ignore: cast_nullable_to_non_nullable
                  as String?,
        mergeEInvoiceToPdf: freezed == mergeEInvoiceToPdf
            ? _value.mergeEInvoiceToPdf
            : mergeEInvoiceToPdf // ignore: cast_nullable_to_non_nullable
                  as bool?,
        skipAutomaticEmailWithPeppol: freezed == skipAutomaticEmailWithPeppol
            ? _value.skipAutomaticEmailWithPeppol
            : skipAutomaticEmailWithPeppol // ignore: cast_nullable_to_non_nullable
                  as bool?,
        eInvoiceForwardEmail: freezed == eInvoiceForwardEmail
            ? _value.eInvoiceForwardEmail
            : eInvoiceForwardEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        eExpenseForwardEmail: freezed == eExpenseForwardEmail
            ? _value.eExpenseForwardEmail
            : eExpenseForwardEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        preferenceProductNotesForHtmlView:
            freezed == preferenceProductNotesForHtmlView
            ? _value.preferenceProductNotesForHtmlView
            : preferenceProductNotesForHtmlView // ignore: cast_nullable_to_non_nullable
                  as bool?,
        customMessageDashboard: freezed == customMessageDashboard
            ? _value.customMessageDashboard
            : customMessageDashboard // ignore: cast_nullable_to_non_nullable
                  as String?,
        customMessageUnpaidInvoice: freezed == customMessageUnpaidInvoice
            ? _value.customMessageUnpaidInvoice
            : customMessageUnpaidInvoice // ignore: cast_nullable_to_non_nullable
                  as String?,
        customMessagePaidInvoice: freezed == customMessagePaidInvoice
            ? _value.customMessagePaidInvoice
            : customMessagePaidInvoice // ignore: cast_nullable_to_non_nullable
                  as String?,
        customMessageUnapprovedQuote: freezed == customMessageUnapprovedQuote
            ? _value.customMessageUnapprovedQuote
            : customMessageUnapprovedQuote // ignore: cast_nullable_to_non_nullable
                  as String?,
        translations: freezed == translations
            ? _value._translations
            : translations // ignore: cast_nullable_to_non_nullable
                  as List<dynamic>?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _$CompanySettingsApiImpl implements _CompanySettingsApi {
  const _$CompanySettingsApiImpl({
    this.id,
    this.name,
    @JsonKey(name: 'company_logo') this.companyLogo,
    @JsonKey(name: 'company_logo_size') this.companyLogoSize,
    this.website,
    this.phone,
    this.email,
    this.address1,
    this.address2,
    this.city,
    this.state,
    @JsonKey(name: 'postal_code') this.postalCode,
    @JsonKey(name: 'country_id') this.countryId,
    @JsonKey(name: 'vat_number') this.vatNumber,
    @JsonKey(name: 'id_number') this.idNumber,
    this.classification,
    @JsonKey(name: 'qr_iban') this.qrIban,
    @JsonKey(name: 'besr_id') this.besrId,
    @JsonKey(name: 'custom_value1') this.customValue1,
    @JsonKey(name: 'custom_value2') this.customValue2,
    @JsonKey(name: 'custom_value3') this.customValue3,
    @JsonKey(name: 'custom_value4') this.customValue4,
    @JsonKey(name: 'timezone_id') this.timezoneId,
    @JsonKey(name: 'date_format_id') this.dateFormatId,
    @JsonKey(name: 'language_id') this.languageId,
    @JsonKey(name: 'currency_id') this.currencyId,
    @JsonKey(name: 'military_time') this.militaryTime,
    @JsonKey(name: 'show_currency_code') this.showCurrencyCode,
    @JsonKey(name: 'use_comma_as_decimal_place') this.useCommaAsDecimalPlace,
    @JsonKey(name: 'first_month_of_year') this.firstMonthOfYear,
    @JsonKey(name: 'invoice_terms') this.invoiceTerms,
    @JsonKey(name: 'invoice_footer') this.invoiceFooter,
    @JsonKey(name: 'quote_terms') this.quoteTerms,
    @JsonKey(name: 'quote_footer') this.quoteFooter,
    @JsonKey(name: 'credit_terms') this.creditTerms,
    @JsonKey(name: 'credit_footer') this.creditFooter,
    @JsonKey(name: 'purchase_order_terms') this.purchaseOrderTerms,
    @JsonKey(name: 'purchase_order_footer') this.purchaseOrderFooter,
    @JsonKey(name: 'purchase_order_public_notes') this.purchaseOrderPublicNotes,
    @JsonKey(name: 'invoice_labels') this.invoiceLabels,
    @JsonKey(name: 'invoice_design_id') this.invoiceDesignId,
    @JsonKey(name: 'quote_design_id') this.quoteDesignId,
    @JsonKey(name: 'credit_design_id') this.creditDesignId,
    @JsonKey(name: 'purchase_order_design_id') this.purchaseOrderDesignId,
    @JsonKey(name: 'statement_design_id') this.statementDesignId,
    @JsonKey(name: 'delivery_note_design_id') this.deliveryNoteDesignId,
    @JsonKey(name: 'payment_receipt_design_id') this.paymentReceiptDesignId,
    @JsonKey(name: 'payment_refund_design_id') this.paymentRefundDesignId,
    @JsonKey(name: 'portal_design_id') this.portalDesignId,
    @JsonKey(name: 'invoice_number_pattern') this.invoiceNumberPattern,
    @JsonKey(name: 'invoice_number_counter') this.invoiceNumberCounter,
    @JsonKey(name: 'recurring_invoice_number_pattern')
    this.recurringInvoiceNumberPattern,
    @JsonKey(name: 'recurring_invoice_number_counter')
    this.recurringInvoiceNumberCounter,
    @JsonKey(name: 'quote_number_pattern') this.quoteNumberPattern,
    @JsonKey(name: 'quote_number_counter') this.quoteNumberCounter,
    @JsonKey(name: 'recurring_quote_number_pattern')
    this.recurringQuoteNumberPattern,
    @JsonKey(name: 'recurring_quote_number_counter')
    this.recurringQuoteNumberCounter,
    @JsonKey(name: 'client_number_pattern') this.clientNumberPattern,
    @JsonKey(name: 'client_number_counter') this.clientNumberCounter,
    @JsonKey(name: 'credit_number_pattern') this.creditNumberPattern,
    @JsonKey(name: 'credit_number_counter') this.creditNumberCounter,
    @JsonKey(name: 'task_number_pattern') this.taskNumberPattern,
    @JsonKey(name: 'task_number_counter') this.taskNumberCounter,
    @JsonKey(name: 'expense_number_pattern') this.expenseNumberPattern,
    @JsonKey(name: 'expense_number_counter') this.expenseNumberCounter,
    @JsonKey(name: 'recurring_expense_number_pattern')
    this.recurringExpenseNumberPattern,
    @JsonKey(name: 'recurring_expense_number_counter')
    this.recurringExpenseNumberCounter,
    @JsonKey(name: 'vendor_number_pattern') this.vendorNumberPattern,
    @JsonKey(name: 'vendor_number_counter') this.vendorNumberCounter,
    @JsonKey(name: 'ticket_number_pattern') this.ticketNumberPattern,
    @JsonKey(name: 'ticket_number_counter') this.ticketNumberCounter,
    @JsonKey(name: 'payment_number_pattern') this.paymentNumberPattern,
    @JsonKey(name: 'payment_number_counter') this.paymentNumberCounter,
    @JsonKey(name: 'project_number_pattern') this.projectNumberPattern,
    @JsonKey(name: 'project_number_counter') this.projectNumberCounter,
    @JsonKey(name: 'purchase_order_number_pattern')
    this.purchaseOrderNumberPattern,
    @JsonKey(name: 'purchase_order_number_counter')
    this.purchaseOrderNumberCounter,
    @JsonKey(name: 'shared_invoice_quote_counter')
    this.sharedInvoiceQuoteCounter,
    @JsonKey(name: 'shared_invoice_credit_counter')
    this.sharedInvoiceCreditCounter,
    @JsonKey(name: 'recurring_number_prefix') this.recurringNumberPrefix,
    @JsonKey(name: 'reset_counter_frequency_id') this.resetCounterFrequencyId,
    @JsonKey(name: 'reset_counter_date') this.resetCounterDate,
    @JsonKey(name: 'counter_padding') this.counterPadding,
    @JsonKey(name: 'counter_number_applied') this.counterNumberApplied,
    @JsonKey(name: 'quote_number_applied') this.quoteNumberApplied,
    @JsonKey(name: 'tax_name1') this.taxName1,
    @JsonKey(name: 'tax_rate1') this.taxRate1,
    @JsonKey(name: 'tax_name2') this.taxName2,
    @JsonKey(name: 'tax_rate2') this.taxRate2,
    @JsonKey(name: 'tax_name3') this.taxName3,
    @JsonKey(name: 'tax_rate3') this.taxRate3,
    @JsonKey(name: 'invoice_taxes') this.invoiceTaxes,
    @JsonKey(name: 'inclusive_taxes') this.inclusiveTaxes,
    @JsonKey(name: 'enable_rappen_rounding') this.enableRappenRounding,
    @JsonKey(name: 'email_sending_method') this.emailSendingMethod,
    @JsonKey(name: 'gmail_sending_user_id') this.gmailSendingUserId,
    @JsonKey(name: 'reply_to_email') this.replyToEmail,
    @JsonKey(name: 'reply_to_name') this.replyToName,
    @JsonKey(name: 'bcc_email') this.bccEmail,
    @JsonKey(name: 'email_from_name') this.emailFromName,
    @JsonKey(name: 'custom_sending_email') this.customSendingEmail,
    @JsonKey(name: 'email_style') this.emailStyle,
    @JsonKey(name: 'email_style_custom') this.emailStyleCustom,
    @JsonKey(name: 'email_signature') this.emailSignature,
    @JsonKey(name: 'enable_email_markup') this.enableEmailMarkup,
    @JsonKey(name: 'show_email_footer') this.showEmailFooter,
    @JsonKey(name: 'pdf_email_attachment') this.pdfEmailAttachment,
    @JsonKey(name: 'ubl_email_attachment') this.ublEmailAttachment,
    @JsonKey(name: 'document_email_attachment') this.documentEmailAttachment,
    @JsonKey(name: 'send_email_on_mark_paid') this.sendEmailOnMarkPaid,
    @JsonKey(name: 'payment_email_all_contacts') this.paymentEmailAllContacts,
    @JsonKey(name: 'postmark_secret') this.postmarkSecret,
    @JsonKey(name: 'mailgun_secret') this.mailgunSecret,
    @JsonKey(name: 'mailgun_domain') this.mailgunDomain,
    @JsonKey(name: 'mailgun_endpoint') this.mailgunEndpoint,
    @JsonKey(name: 'brevo_secret') this.brevoSecret,
    @JsonKey(name: 'ses_secret_key') this.sesSecretKey,
    @JsonKey(name: 'ses_access_key') this.sesAccessKey,
    @JsonKey(name: 'ses_region') this.sesRegion,
    @JsonKey(name: 'ses_topic_arn') this.sesTopicArn,
    @JsonKey(name: 'ses_from_address') this.sesFromAddress,
    @JsonKey(name: 'email_subject_invoice') this.emailSubjectInvoice,
    @JsonKey(name: 'email_subject_quote') this.emailSubjectQuote,
    @JsonKey(name: 'email_subject_credit') this.emailSubjectCredit,
    @JsonKey(name: 'email_subject_payment') this.emailSubjectPayment,
    @JsonKey(name: 'email_subject_payment_partial')
    this.emailSubjectPaymentPartial,
    @JsonKey(name: 'email_subject_statement') this.emailSubjectStatement,
    @JsonKey(name: 'email_subject_purchase_order')
    this.emailSubjectPurchaseOrder,
    @JsonKey(name: 'email_subject_reminder1') this.emailSubjectReminder1,
    @JsonKey(name: 'email_subject_reminder2') this.emailSubjectReminder2,
    @JsonKey(name: 'email_subject_reminder3') this.emailSubjectReminder3,
    @JsonKey(name: 'email_subject_reminder_endless')
    this.emailSubjectReminderEndless,
    @JsonKey(name: 'email_subject_custom1') this.emailSubjectCustom1,
    @JsonKey(name: 'email_subject_custom2') this.emailSubjectCustom2,
    @JsonKey(name: 'email_subject_custom3') this.emailSubjectCustom3,
    @JsonKey(name: 'email_template_invoice') this.emailTemplateInvoice,
    @JsonKey(name: 'email_template_quote') this.emailTemplateQuote,
    @JsonKey(name: 'email_template_credit') this.emailTemplateCredit,
    @JsonKey(name: 'email_template_payment') this.emailTemplatePayment,
    @JsonKey(name: 'email_template_payment_partial')
    this.emailTemplatePaymentPartial,
    @JsonKey(name: 'email_template_statement') this.emailTemplateStatement,
    @JsonKey(name: 'email_template_purchase_order')
    this.emailTemplatePurchaseOrder,
    @JsonKey(name: 'email_template_reminder1') this.emailTemplateReminder1,
    @JsonKey(name: 'email_template_reminder2') this.emailTemplateReminder2,
    @JsonKey(name: 'email_template_reminder3') this.emailTemplateReminder3,
    @JsonKey(name: 'email_template_reminder_endless')
    this.emailTemplateReminderEndless,
    @JsonKey(name: 'email_template_custom1') this.emailTemplateCustom1,
    @JsonKey(name: 'email_template_custom2') this.emailTemplateCustom2,
    @JsonKey(name: 'email_template_custom3') this.emailTemplateCustom3,
    @JsonKey(name: 'send_reminders') this.sendReminders,
    @JsonKey(name: 'enable_reminder1') this.enableReminder1,
    @JsonKey(name: 'enable_reminder2') this.enableReminder2,
    @JsonKey(name: 'enable_reminder3') this.enableReminder3,
    @JsonKey(name: 'enable_reminder_endless') this.enableReminderEndless,
    @JsonKey(name: 'num_days_reminder1') this.numDaysReminder1,
    @JsonKey(name: 'num_days_reminder2') this.numDaysReminder2,
    @JsonKey(name: 'num_days_reminder3') this.numDaysReminder3,
    @JsonKey(name: 'schedule_reminder1') this.scheduleReminder1,
    @JsonKey(name: 'schedule_reminder2') this.scheduleReminder2,
    @JsonKey(name: 'schedule_reminder3') this.scheduleReminder3,
    @JsonKey(name: 'reminder_send_time') this.reminderSendTime,
    @JsonKey(name: 'late_fee_amount1') this.lateFeeAmount1,
    @JsonKey(name: 'late_fee_amount2') this.lateFeeAmount2,
    @JsonKey(name: 'late_fee_amount3') this.lateFeeAmount3,
    @JsonKey(name: 'late_fee_percent1') this.lateFeePercent1,
    @JsonKey(name: 'late_fee_percent2') this.lateFeePercent2,
    @JsonKey(name: 'late_fee_percent3') this.lateFeePercent3,
    @JsonKey(name: 'endless_reminder_frequency_id')
    this.endlessReminderFrequencyId,
    @JsonKey(name: 'late_fee_endless_amount') this.lateFeeEndlessAmount,
    @JsonKey(name: 'late_fee_endless_percent') this.lateFeeEndlessPercent,
    @JsonKey(name: 'auto_archive_invoice') this.autoArchiveInvoice,
    @JsonKey(name: 'auto_archive_invoice_cancelled')
    this.autoArchiveInvoiceCancelled,
    @JsonKey(name: 'auto_archive_quote') this.autoArchiveQuote,
    @JsonKey(name: 'auto_convert_quote') this.autoConvertQuote,
    @JsonKey(name: 'auto_email_invoice') this.autoEmailInvoice,
    @JsonKey(name: 'auto_bill_standard_invoices') this.autoBillStandardInvoices,
    @JsonKey(name: 'auto_bill') this.autoBill,
    @JsonKey(name: 'auto_bill_date') this.autoBillDate,
    @JsonKey(name: 'lock_invoices') this.lockInvoices,
    @JsonKey(name: 'entity_send_time') this.entitySendTime,
    @JsonKey(name: 'show_accept_invoice_terms') this.showAcceptInvoiceTerms,
    @JsonKey(name: 'show_accept_quote_terms') this.showAcceptQuoteTerms,
    @JsonKey(name: 'require_invoice_signature') this.requireInvoiceSignature,
    @JsonKey(name: 'require_quote_signature') this.requireQuoteSignature,
    @JsonKey(name: 'require_purchase_order_signature')
    this.requirePurchaseOrderSignature,
    @JsonKey(name: 'signature_on_pdf') this.signatureOnPdf,
    @JsonKey(name: 'accept_client_input_quote_approval')
    this.acceptClientInputQuoteApproval,
    @JsonKey(name: 'sync_invoice_quote_columns') this.syncInvoiceQuoteColumns,
    @JsonKey(name: 'show_shipping_address') this.showShippingAddress,
    @JsonKey(name: 'show_paid_stamp') this.showPaidStamp,
    @JsonKey(name: 'page_size') this.pageSize,
    @JsonKey(name: 'page_layout') this.pageLayout,
    @JsonKey(name: 'font_size') this.fontSize,
    @JsonKey(name: 'primary_font') this.primaryFont,
    @JsonKey(name: 'secondary_font') this.secondaryFont,
    @JsonKey(name: 'primary_color') this.primaryColor,
    @JsonKey(name: 'secondary_color') this.secondaryColor,
    @JsonKey(name: 'page_numbering') this.pageNumbering,
    @JsonKey(name: 'page_numbering_alignment') this.pageNumberingAlignment,
    @JsonKey(name: 'hide_paid_to_date') this.hidePaidToDate,
    @JsonKey(name: 'hide_empty_columns_on_pdf') this.hideEmptyColumnsOnPdf,
    @JsonKey(name: 'embed_documents') this.embedDocuments,
    @JsonKey(name: 'all_pages_header') this.allPagesHeader,
    @JsonKey(name: 'all_pages_footer') this.allPagesFooter,
    @JsonKey(name: 'pdf_variables')
    final Map<String, List<String>>? pdfVariables,
    @JsonKey(name: 'show_pdfhtml_on_mobile') this.showPdfhtmlOnMobile,
    @JsonKey(name: 'enable_client_portal') this.enableClientPortal,
    @JsonKey(name: 'enable_client_portal_dashboard')
    this.enableClientPortalDashboard,
    @JsonKey(name: 'enable_client_portal_tasks') this.enableClientPortalTasks,
    @JsonKey(name: 'show_all_tasks_client_portal')
    this.showAllTasksClientPortal,
    @JsonKey(name: 'enable_client_portal_password')
    this.enableClientPortalPassword,
    @JsonKey(name: 'client_portal_terms') this.clientPortalTerms,
    @JsonKey(name: 'client_portal_privacy_policy')
    this.clientPortalPrivacyPolicy,
    @JsonKey(name: 'client_portal_enable_uploads')
    this.clientPortalEnableUploads,
    @JsonKey(name: 'client_portal_allow_under_payment')
    this.clientPortalAllowUnderPayment,
    @JsonKey(name: 'client_portal_under_payment_minimum')
    this.clientPortalUnderPaymentMinimum,
    @JsonKey(name: 'client_portal_allow_over_payment')
    this.clientPortalAllowOverPayment,
    @JsonKey(name: 'portal_custom_head') this.portalCustomHead,
    @JsonKey(name: 'portal_custom_css') this.portalCustomCss,
    @JsonKey(name: 'portal_custom_footer') this.portalCustomFooter,
    @JsonKey(name: 'portal_custom_js') this.portalCustomJs,
    @JsonKey(name: 'client_can_register') this.clientCanRegister,
    @JsonKey(name: 'client_initiated_payments') this.clientInitiatedPayments,
    @JsonKey(name: 'client_initiated_payments_minimum')
    this.clientInitiatedPaymentsMinimum,
    @JsonKey(name: 'enable_client_profile_update')
    this.enableClientProfileUpdate,
    @JsonKey(name: 'client_online_payment_notification')
    this.clientOnlinePaymentNotification,
    @JsonKey(name: 'client_manual_payment_notification')
    this.clientManualPaymentNotification,
    @JsonKey(name: 'vendor_portal_enable_uploads')
    this.vendorPortalEnableUploads,
    @JsonKey(name: 'use_credits_payment') this.useCreditsPayment,
    @JsonKey(name: 'use_unapplied_payment') this.useUnappliedPayment,
    @JsonKey(name: 'payment_terms') this.paymentTerms,
    @JsonKey(name: 'valid_until') this.validUntil,
    @JsonKey(name: 'payment_type_id') this.paymentTypeId,
    @JsonKey(name: 'default_expense_payment_type_id')
    this.defaultExpensePaymentTypeId,
    @JsonKey(name: 'company_gateway_ids') this.companyGatewayIds,
    @JsonKey(name: 'payment_flow') this.paymentFlow,
    @JsonKey(name: 'unlock_invoice_documents_after_payment')
    this.unlockInvoiceDocumentsAfterPayment,
    @JsonKey(name: 'show_task_item_description') this.showTaskItemDescription,
    @JsonKey(name: 'allow_billable_task_items') this.allowBillableTaskItems,
    @JsonKey(name: 'default_task_rate') this.defaultTaskRate,
    @JsonKey(name: 'task_round_up') this.taskRoundUp,
    @JsonKey(name: 'task_round_to_nearest') this.taskRoundToNearest,
    @JsonKey(name: 'enable_e_invoice') this.enableEInvoice,
    @JsonKey(name: 'e_invoice_type') this.eInvoiceType,
    @JsonKey(name: 'e_quote_type') this.eQuoteType,
    @JsonKey(name: 'merge_e_invoice_to_pdf') this.mergeEInvoiceToPdf,
    @JsonKey(name: 'skip_automatic_email_with_peppol')
    this.skipAutomaticEmailWithPeppol,
    @JsonKey(name: 'e_invoice_forward_email') this.eInvoiceForwardEmail,
    @JsonKey(name: 'e_expense_forward_email') this.eExpenseForwardEmail,
    @JsonKey(name: 'preference_product_notes_for_html_view')
    this.preferenceProductNotesForHtmlView,
    @JsonKey(name: 'custom_message_dashboard') this.customMessageDashboard,
    @JsonKey(name: 'custom_message_unpaid_invoice')
    this.customMessageUnpaidInvoice,
    @JsonKey(name: 'custom_message_paid_invoice') this.customMessagePaidInvoice,
    @JsonKey(name: 'custom_message_unapproved_quote')
    this.customMessageUnapprovedQuote,
    final List<dynamic>? translations,
  }) : _pdfVariables = pdfVariables,
       _translations = translations;

  factory _$CompanySettingsApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanySettingsApiImplFromJson(json);

  // ── Identity / brand ────────────────────────────────────────────────
  @override
  final String? id;
  @override
  final String? name;
  @override
  @JsonKey(name: 'company_logo')
  final String? companyLogo;
  @override
  @JsonKey(name: 'company_logo_size')
  final String? companyLogoSize;
  @override
  final String? website;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? address1;
  @override
  final String? address2;
  @override
  final String? city;
  @override
  final String? state;
  @override
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  @override
  @JsonKey(name: 'country_id')
  final String? countryId;
  @override
  @JsonKey(name: 'vat_number')
  final String? vatNumber;
  @override
  @JsonKey(name: 'id_number')
  final String? idNumber;
  @override
  final String? classification;
  @override
  @JsonKey(name: 'qr_iban')
  final String? qrIban;
  @override
  @JsonKey(name: 'besr_id')
  final String? besrId;
  @override
  @JsonKey(name: 'custom_value1')
  final String? customValue1;
  @override
  @JsonKey(name: 'custom_value2')
  final String? customValue2;
  @override
  @JsonKey(name: 'custom_value3')
  final String? customValue3;
  @override
  @JsonKey(name: 'custom_value4')
  final String? customValue4;
  // ── Localization ────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'timezone_id')
  final String? timezoneId;
  @override
  @JsonKey(name: 'date_format_id')
  final String? dateFormatId;
  @override
  @JsonKey(name: 'language_id')
  final String? languageId;
  @override
  @JsonKey(name: 'currency_id')
  final String? currencyId;
  @override
  @JsonKey(name: 'military_time')
  final bool? militaryTime;
  @override
  @JsonKey(name: 'show_currency_code')
  final bool? showCurrencyCode;
  @override
  @JsonKey(name: 'use_comma_as_decimal_place')
  final bool? useCommaAsDecimalPlace;
  @override
  @JsonKey(name: 'first_month_of_year')
  final String? firstMonthOfYear;
  // ── Defaults: terms & footers ───────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_terms')
  final String? invoiceTerms;
  @override
  @JsonKey(name: 'invoice_footer')
  final String? invoiceFooter;
  @override
  @JsonKey(name: 'quote_terms')
  final String? quoteTerms;
  @override
  @JsonKey(name: 'quote_footer')
  final String? quoteFooter;
  @override
  @JsonKey(name: 'credit_terms')
  final String? creditTerms;
  @override
  @JsonKey(name: 'credit_footer')
  final String? creditFooter;
  @override
  @JsonKey(name: 'purchase_order_terms')
  final String? purchaseOrderTerms;
  @override
  @JsonKey(name: 'purchase_order_footer')
  final String? purchaseOrderFooter;
  @override
  @JsonKey(name: 'purchase_order_public_notes')
  final String? purchaseOrderPublicNotes;
  @override
  @JsonKey(name: 'invoice_labels')
  final String? invoiceLabels;
  // ── Design ids ──────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_design_id')
  final String? invoiceDesignId;
  @override
  @JsonKey(name: 'quote_design_id')
  final String? quoteDesignId;
  @override
  @JsonKey(name: 'credit_design_id')
  final String? creditDesignId;
  @override
  @JsonKey(name: 'purchase_order_design_id')
  final String? purchaseOrderDesignId;
  @override
  @JsonKey(name: 'statement_design_id')
  final String? statementDesignId;
  @override
  @JsonKey(name: 'delivery_note_design_id')
  final String? deliveryNoteDesignId;
  @override
  @JsonKey(name: 'payment_receipt_design_id')
  final String? paymentReceiptDesignId;
  @override
  @JsonKey(name: 'payment_refund_design_id')
  final String? paymentRefundDesignId;
  @override
  @JsonKey(name: 'portal_design_id')
  final String? portalDesignId;
  // ── Numbering & counters ────────────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_number_pattern')
  final String? invoiceNumberPattern;
  @override
  @JsonKey(name: 'invoice_number_counter')
  final int? invoiceNumberCounter;
  @override
  @JsonKey(name: 'recurring_invoice_number_pattern')
  final String? recurringInvoiceNumberPattern;
  @override
  @JsonKey(name: 'recurring_invoice_number_counter')
  final int? recurringInvoiceNumberCounter;
  @override
  @JsonKey(name: 'quote_number_pattern')
  final String? quoteNumberPattern;
  @override
  @JsonKey(name: 'quote_number_counter')
  final int? quoteNumberCounter;
  @override
  @JsonKey(name: 'recurring_quote_number_pattern')
  final String? recurringQuoteNumberPattern;
  @override
  @JsonKey(name: 'recurring_quote_number_counter')
  final int? recurringQuoteNumberCounter;
  @override
  @JsonKey(name: 'client_number_pattern')
  final String? clientNumberPattern;
  @override
  @JsonKey(name: 'client_number_counter')
  final int? clientNumberCounter;
  @override
  @JsonKey(name: 'credit_number_pattern')
  final String? creditNumberPattern;
  @override
  @JsonKey(name: 'credit_number_counter')
  final int? creditNumberCounter;
  @override
  @JsonKey(name: 'task_number_pattern')
  final String? taskNumberPattern;
  @override
  @JsonKey(name: 'task_number_counter')
  final int? taskNumberCounter;
  @override
  @JsonKey(name: 'expense_number_pattern')
  final String? expenseNumberPattern;
  @override
  @JsonKey(name: 'expense_number_counter')
  final int? expenseNumberCounter;
  @override
  @JsonKey(name: 'recurring_expense_number_pattern')
  final String? recurringExpenseNumberPattern;
  @override
  @JsonKey(name: 'recurring_expense_number_counter')
  final int? recurringExpenseNumberCounter;
  @override
  @JsonKey(name: 'vendor_number_pattern')
  final String? vendorNumberPattern;
  @override
  @JsonKey(name: 'vendor_number_counter')
  final int? vendorNumberCounter;
  @override
  @JsonKey(name: 'ticket_number_pattern')
  final String? ticketNumberPattern;
  @override
  @JsonKey(name: 'ticket_number_counter')
  final int? ticketNumberCounter;
  @override
  @JsonKey(name: 'payment_number_pattern')
  final String? paymentNumberPattern;
  @override
  @JsonKey(name: 'payment_number_counter')
  final int? paymentNumberCounter;
  @override
  @JsonKey(name: 'project_number_pattern')
  final String? projectNumberPattern;
  @override
  @JsonKey(name: 'project_number_counter')
  final int? projectNumberCounter;
  @override
  @JsonKey(name: 'purchase_order_number_pattern')
  final String? purchaseOrderNumberPattern;
  @override
  @JsonKey(name: 'purchase_order_number_counter')
  final int? purchaseOrderNumberCounter;
  @override
  @JsonKey(name: 'shared_invoice_quote_counter')
  final bool? sharedInvoiceQuoteCounter;
  @override
  @JsonKey(name: 'shared_invoice_credit_counter')
  final bool? sharedInvoiceCreditCounter;
  @override
  @JsonKey(name: 'recurring_number_prefix')
  final String? recurringNumberPrefix;
  @override
  @JsonKey(name: 'reset_counter_frequency_id')
  final int? resetCounterFrequencyId;
  @override
  @JsonKey(name: 'reset_counter_date')
  final String? resetCounterDate;
  @override
  @JsonKey(name: 'counter_padding')
  final int? counterPadding;
  @override
  @JsonKey(name: 'counter_number_applied')
  final String? counterNumberApplied;
  @override
  @JsonKey(name: 'quote_number_applied')
  final String? quoteNumberApplied;
  // ── Taxes ───────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'tax_name1')
  final String? taxName1;
  @override
  @JsonKey(name: 'tax_rate1')
  final double? taxRate1;
  @override
  @JsonKey(name: 'tax_name2')
  final String? taxName2;
  @override
  @JsonKey(name: 'tax_rate2')
  final double? taxRate2;
  @override
  @JsonKey(name: 'tax_name3')
  final String? taxName3;
  @override
  @JsonKey(name: 'tax_rate3')
  final double? taxRate3;
  @override
  @JsonKey(name: 'invoice_taxes')
  final int? invoiceTaxes;
  @override
  @JsonKey(name: 'inclusive_taxes')
  final bool? inclusiveTaxes;
  @override
  @JsonKey(name: 'enable_rappen_rounding')
  final bool? enableRappenRounding;
  // ── Email config ────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'email_sending_method')
  final String? emailSendingMethod;
  @override
  @JsonKey(name: 'gmail_sending_user_id')
  final String? gmailSendingUserId;
  @override
  @JsonKey(name: 'reply_to_email')
  final String? replyToEmail;
  @override
  @JsonKey(name: 'reply_to_name')
  final String? replyToName;
  @override
  @JsonKey(name: 'bcc_email')
  final String? bccEmail;
  @override
  @JsonKey(name: 'email_from_name')
  final String? emailFromName;
  @override
  @JsonKey(name: 'custom_sending_email')
  final String? customSendingEmail;
  @override
  @JsonKey(name: 'email_style')
  final String? emailStyle;
  @override
  @JsonKey(name: 'email_style_custom')
  final String? emailStyleCustom;
  @override
  @JsonKey(name: 'email_signature')
  final String? emailSignature;
  @override
  @JsonKey(name: 'enable_email_markup')
  final bool? enableEmailMarkup;
  @override
  @JsonKey(name: 'show_email_footer')
  final bool? showEmailFooter;
  @override
  @JsonKey(name: 'pdf_email_attachment')
  final bool? pdfEmailAttachment;
  @override
  @JsonKey(name: 'ubl_email_attachment')
  final bool? ublEmailAttachment;
  @override
  @JsonKey(name: 'document_email_attachment')
  final bool? documentEmailAttachment;
  @override
  @JsonKey(name: 'send_email_on_mark_paid')
  final bool? sendEmailOnMarkPaid;
  @override
  @JsonKey(name: 'payment_email_all_contacts')
  final bool? paymentEmailAllContacts;
  // Mail service secrets
  @override
  @JsonKey(name: 'postmark_secret')
  final String? postmarkSecret;
  @override
  @JsonKey(name: 'mailgun_secret')
  final String? mailgunSecret;
  @override
  @JsonKey(name: 'mailgun_domain')
  final String? mailgunDomain;
  @override
  @JsonKey(name: 'mailgun_endpoint')
  final String? mailgunEndpoint;
  @override
  @JsonKey(name: 'brevo_secret')
  final String? brevoSecret;
  @override
  @JsonKey(name: 'ses_secret_key')
  final String? sesSecretKey;
  @override
  @JsonKey(name: 'ses_access_key')
  final String? sesAccessKey;
  @override
  @JsonKey(name: 'ses_region')
  final String? sesRegion;
  @override
  @JsonKey(name: 'ses_topic_arn')
  final String? sesTopicArn;
  @override
  @JsonKey(name: 'ses_from_address')
  final String? sesFromAddress;
  // Email subjects (per entity)
  @override
  @JsonKey(name: 'email_subject_invoice')
  final String? emailSubjectInvoice;
  @override
  @JsonKey(name: 'email_subject_quote')
  final String? emailSubjectQuote;
  @override
  @JsonKey(name: 'email_subject_credit')
  final String? emailSubjectCredit;
  @override
  @JsonKey(name: 'email_subject_payment')
  final String? emailSubjectPayment;
  @override
  @JsonKey(name: 'email_subject_payment_partial')
  final String? emailSubjectPaymentPartial;
  @override
  @JsonKey(name: 'email_subject_statement')
  final String? emailSubjectStatement;
  @override
  @JsonKey(name: 'email_subject_purchase_order')
  final String? emailSubjectPurchaseOrder;
  @override
  @JsonKey(name: 'email_subject_reminder1')
  final String? emailSubjectReminder1;
  @override
  @JsonKey(name: 'email_subject_reminder2')
  final String? emailSubjectReminder2;
  @override
  @JsonKey(name: 'email_subject_reminder3')
  final String? emailSubjectReminder3;
  @override
  @JsonKey(name: 'email_subject_reminder_endless')
  final String? emailSubjectReminderEndless;
  @override
  @JsonKey(name: 'email_subject_custom1')
  final String? emailSubjectCustom1;
  @override
  @JsonKey(name: 'email_subject_custom2')
  final String? emailSubjectCustom2;
  @override
  @JsonKey(name: 'email_subject_custom3')
  final String? emailSubjectCustom3;
  // Email templates (per entity)
  @override
  @JsonKey(name: 'email_template_invoice')
  final String? emailTemplateInvoice;
  @override
  @JsonKey(name: 'email_template_quote')
  final String? emailTemplateQuote;
  @override
  @JsonKey(name: 'email_template_credit')
  final String? emailTemplateCredit;
  @override
  @JsonKey(name: 'email_template_payment')
  final String? emailTemplatePayment;
  @override
  @JsonKey(name: 'email_template_payment_partial')
  final String? emailTemplatePaymentPartial;
  @override
  @JsonKey(name: 'email_template_statement')
  final String? emailTemplateStatement;
  @override
  @JsonKey(name: 'email_template_purchase_order')
  final String? emailTemplatePurchaseOrder;
  @override
  @JsonKey(name: 'email_template_reminder1')
  final String? emailTemplateReminder1;
  @override
  @JsonKey(name: 'email_template_reminder2')
  final String? emailTemplateReminder2;
  @override
  @JsonKey(name: 'email_template_reminder3')
  final String? emailTemplateReminder3;
  @override
  @JsonKey(name: 'email_template_reminder_endless')
  final String? emailTemplateReminderEndless;
  @override
  @JsonKey(name: 'email_template_custom1')
  final String? emailTemplateCustom1;
  @override
  @JsonKey(name: 'email_template_custom2')
  final String? emailTemplateCustom2;
  @override
  @JsonKey(name: 'email_template_custom3')
  final String? emailTemplateCustom3;
  // ── Reminders ───────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'send_reminders')
  final bool? sendReminders;
  @override
  @JsonKey(name: 'enable_reminder1')
  final bool? enableReminder1;
  @override
  @JsonKey(name: 'enable_reminder2')
  final bool? enableReminder2;
  @override
  @JsonKey(name: 'enable_reminder3')
  final bool? enableReminder3;
  @override
  @JsonKey(name: 'enable_reminder_endless')
  final bool? enableReminderEndless;
  @override
  @JsonKey(name: 'num_days_reminder1')
  final int? numDaysReminder1;
  @override
  @JsonKey(name: 'num_days_reminder2')
  final int? numDaysReminder2;
  @override
  @JsonKey(name: 'num_days_reminder3')
  final int? numDaysReminder3;
  @override
  @JsonKey(name: 'schedule_reminder1')
  final String? scheduleReminder1;
  @override
  @JsonKey(name: 'schedule_reminder2')
  final String? scheduleReminder2;
  @override
  @JsonKey(name: 'schedule_reminder3')
  final String? scheduleReminder3;
  @override
  @JsonKey(name: 'reminder_send_time')
  final int? reminderSendTime;
  @override
  @JsonKey(name: 'late_fee_amount1')
  final double? lateFeeAmount1;
  @override
  @JsonKey(name: 'late_fee_amount2')
  final double? lateFeeAmount2;
  @override
  @JsonKey(name: 'late_fee_amount3')
  final double? lateFeeAmount3;
  @override
  @JsonKey(name: 'late_fee_percent1')
  final double? lateFeePercent1;
  @override
  @JsonKey(name: 'late_fee_percent2')
  final double? lateFeePercent2;
  @override
  @JsonKey(name: 'late_fee_percent3')
  final double? lateFeePercent3;
  @override
  @JsonKey(name: 'endless_reminder_frequency_id')
  final String? endlessReminderFrequencyId;
  @override
  @JsonKey(name: 'late_fee_endless_amount')
  final double? lateFeeEndlessAmount;
  @override
  @JsonKey(name: 'late_fee_endless_percent')
  final double? lateFeeEndlessPercent;
  // ── Invoice / quote behavior ───────────────────────────────────────
  @override
  @JsonKey(name: 'auto_archive_invoice')
  final bool? autoArchiveInvoice;
  @override
  @JsonKey(name: 'auto_archive_invoice_cancelled')
  final bool? autoArchiveInvoiceCancelled;
  @override
  @JsonKey(name: 'auto_archive_quote')
  final bool? autoArchiveQuote;
  @override
  @JsonKey(name: 'auto_convert_quote')
  final bool? autoConvertQuote;
  @override
  @JsonKey(name: 'auto_email_invoice')
  final bool? autoEmailInvoice;
  @override
  @JsonKey(name: 'auto_bill_standard_invoices')
  final bool? autoBillStandardInvoices;
  @override
  @JsonKey(name: 'auto_bill')
  final String? autoBill;
  @override
  @JsonKey(name: 'auto_bill_date')
  final String? autoBillDate;
  @override
  @JsonKey(name: 'lock_invoices')
  final String? lockInvoices;
  @override
  @JsonKey(name: 'entity_send_time')
  final int? entitySendTime;
  @override
  @JsonKey(name: 'show_accept_invoice_terms')
  final bool? showAcceptInvoiceTerms;
  @override
  @JsonKey(name: 'show_accept_quote_terms')
  final bool? showAcceptQuoteTerms;
  @override
  @JsonKey(name: 'require_invoice_signature')
  final bool? requireInvoiceSignature;
  @override
  @JsonKey(name: 'require_quote_signature')
  final bool? requireQuoteSignature;
  @override
  @JsonKey(name: 'require_purchase_order_signature')
  final bool? requirePurchaseOrderSignature;
  @override
  @JsonKey(name: 'signature_on_pdf')
  final bool? signatureOnPdf;
  @override
  @JsonKey(name: 'accept_client_input_quote_approval')
  final bool? acceptClientInputQuoteApproval;
  @override
  @JsonKey(name: 'sync_invoice_quote_columns')
  final bool? syncInvoiceQuoteColumns;
  @override
  @JsonKey(name: 'show_shipping_address')
  final bool? showShippingAddress;
  @override
  @JsonKey(name: 'show_paid_stamp')
  final bool? showPaidStamp;
  // ── PDF / page layout ──────────────────────────────────────────────
  @override
  @JsonKey(name: 'page_size')
  final String? pageSize;
  @override
  @JsonKey(name: 'page_layout')
  final String? pageLayout;
  @override
  @JsonKey(name: 'font_size')
  final int? fontSize;
  @override
  @JsonKey(name: 'primary_font')
  final String? primaryFont;
  @override
  @JsonKey(name: 'secondary_font')
  final String? secondaryFont;
  @override
  @JsonKey(name: 'primary_color')
  final String? primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  final String? secondaryColor;
  @override
  @JsonKey(name: 'page_numbering')
  final bool? pageNumbering;
  @override
  @JsonKey(name: 'page_numbering_alignment')
  final String? pageNumberingAlignment;
  @override
  @JsonKey(name: 'hide_paid_to_date')
  final bool? hidePaidToDate;
  @override
  @JsonKey(name: 'hide_empty_columns_on_pdf')
  final bool? hideEmptyColumnsOnPdf;
  @override
  @JsonKey(name: 'embed_documents')
  final bool? embedDocuments;
  @override
  @JsonKey(name: 'all_pages_header')
  final bool? allPagesHeader;
  @override
  @JsonKey(name: 'all_pages_footer')
  final bool? allPagesFooter;
  final Map<String, List<String>>? _pdfVariables;
  @override
  @JsonKey(name: 'pdf_variables')
  Map<String, List<String>>? get pdfVariables {
    final value = _pdfVariables;
    if (value == null) return null;
    if (_pdfVariables is EqualUnmodifiableMapView) return _pdfVariables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'show_pdfhtml_on_mobile')
  final bool? showPdfhtmlOnMobile;
  // ── Portal ─────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'enable_client_portal')
  final bool? enableClientPortal;
  @override
  @JsonKey(name: 'enable_client_portal_dashboard')
  final bool? enableClientPortalDashboard;
  @override
  @JsonKey(name: 'enable_client_portal_tasks')
  final bool? enableClientPortalTasks;
  @override
  @JsonKey(name: 'show_all_tasks_client_portal')
  final String? showAllTasksClientPortal;
  @override
  @JsonKey(name: 'enable_client_portal_password')
  final bool? enableClientPortalPassword;
  @override
  @JsonKey(name: 'client_portal_terms')
  final String? clientPortalTerms;
  @override
  @JsonKey(name: 'client_portal_privacy_policy')
  final String? clientPortalPrivacyPolicy;
  @override
  @JsonKey(name: 'client_portal_enable_uploads')
  final bool? clientPortalEnableUploads;
  @override
  @JsonKey(name: 'client_portal_allow_under_payment')
  final bool? clientPortalAllowUnderPayment;
  @override
  @JsonKey(name: 'client_portal_under_payment_minimum')
  final double? clientPortalUnderPaymentMinimum;
  @override
  @JsonKey(name: 'client_portal_allow_over_payment')
  final bool? clientPortalAllowOverPayment;
  @override
  @JsonKey(name: 'portal_custom_head')
  final String? portalCustomHead;
  @override
  @JsonKey(name: 'portal_custom_css')
  final String? portalCustomCss;
  @override
  @JsonKey(name: 'portal_custom_footer')
  final String? portalCustomFooter;
  @override
  @JsonKey(name: 'portal_custom_js')
  final String? portalCustomJs;
  @override
  @JsonKey(name: 'client_can_register')
  final bool? clientCanRegister;
  @override
  @JsonKey(name: 'client_initiated_payments')
  final bool? clientInitiatedPayments;
  @override
  @JsonKey(name: 'client_initiated_payments_minimum')
  final double? clientInitiatedPaymentsMinimum;
  @override
  @JsonKey(name: 'enable_client_profile_update')
  final bool? enableClientProfileUpdate;
  @override
  @JsonKey(name: 'client_online_payment_notification')
  final bool? clientOnlinePaymentNotification;
  @override
  @JsonKey(name: 'client_manual_payment_notification')
  final bool? clientManualPaymentNotification;
  @override
  @JsonKey(name: 'vendor_portal_enable_uploads')
  final bool? vendorPortalEnableUploads;
  @override
  @JsonKey(name: 'use_credits_payment')
  final String? useCreditsPayment;
  @override
  @JsonKey(name: 'use_unapplied_payment')
  final String? useUnappliedPayment;
  // ── Payments / billing ─────────────────────────────────────────────
  @override
  @JsonKey(name: 'payment_terms')
  final String? paymentTerms;
  @override
  @JsonKey(name: 'valid_until')
  final String? validUntil;
  @override
  @JsonKey(name: 'payment_type_id')
  final String? paymentTypeId;
  @override
  @JsonKey(name: 'default_expense_payment_type_id')
  final String? defaultExpensePaymentTypeId;
  @override
  @JsonKey(name: 'company_gateway_ids')
  final String? companyGatewayIds;
  @override
  @JsonKey(name: 'payment_flow')
  final String? paymentFlow;
  @override
  @JsonKey(name: 'unlock_invoice_documents_after_payment')
  final bool? unlockInvoiceDocumentsAfterPayment;
  // ── Tasks ──────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'show_task_item_description')
  final bool? showTaskItemDescription;
  @override
  @JsonKey(name: 'allow_billable_task_items')
  final bool? allowBillableTaskItems;
  @override
  @JsonKey(name: 'default_task_rate')
  final double? defaultTaskRate;
  @override
  @JsonKey(name: 'task_round_up')
  final bool? taskRoundUp;
  @override
  @JsonKey(name: 'task_round_to_nearest')
  final double? taskRoundToNearest;
  // ── e-Invoice ──────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'enable_e_invoice')
  final bool? enableEInvoice;
  @override
  @JsonKey(name: 'e_invoice_type')
  final String? eInvoiceType;
  @override
  @JsonKey(name: 'e_quote_type')
  final String? eQuoteType;
  @override
  @JsonKey(name: 'merge_e_invoice_to_pdf')
  final bool? mergeEInvoiceToPdf;
  @override
  @JsonKey(name: 'skip_automatic_email_with_peppol')
  final bool? skipAutomaticEmailWithPeppol;
  @override
  @JsonKey(name: 'e_invoice_forward_email')
  final String? eInvoiceForwardEmail;
  @override
  @JsonKey(name: 'e_expense_forward_email')
  final String? eExpenseForwardEmail;
  @override
  @JsonKey(name: 'preference_product_notes_for_html_view')
  final bool? preferenceProductNotesForHtmlView;
  // ── Dashboard / messages ───────────────────────────────────────────
  @override
  @JsonKey(name: 'custom_message_dashboard')
  final String? customMessageDashboard;
  @override
  @JsonKey(name: 'custom_message_unpaid_invoice')
  final String? customMessageUnpaidInvoice;
  @override
  @JsonKey(name: 'custom_message_paid_invoice')
  final String? customMessagePaidInvoice;
  @override
  @JsonKey(name: 'custom_message_unapproved_quote')
  final String? customMessageUnapprovedQuote;
  // ── Misc ───────────────────────────────────────────────────────────
  final List<dynamic>? _translations;
  // ── Misc ───────────────────────────────────────────────────────────
  @override
  List<dynamic>? get translations {
    final value = _translations;
    if (value == null) return null;
    if (_translations is EqualUnmodifiableListView) return _translations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CompanySettingsApi(id: $id, name: $name, companyLogo: $companyLogo, companyLogoSize: $companyLogoSize, website: $website, phone: $phone, email: $email, address1: $address1, address2: $address2, city: $city, state: $state, postalCode: $postalCode, countryId: $countryId, vatNumber: $vatNumber, idNumber: $idNumber, classification: $classification, qrIban: $qrIban, besrId: $besrId, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, timezoneId: $timezoneId, dateFormatId: $dateFormatId, languageId: $languageId, currencyId: $currencyId, militaryTime: $militaryTime, showCurrencyCode: $showCurrencyCode, useCommaAsDecimalPlace: $useCommaAsDecimalPlace, firstMonthOfYear: $firstMonthOfYear, invoiceTerms: $invoiceTerms, invoiceFooter: $invoiceFooter, quoteTerms: $quoteTerms, quoteFooter: $quoteFooter, creditTerms: $creditTerms, creditFooter: $creditFooter, purchaseOrderTerms: $purchaseOrderTerms, purchaseOrderFooter: $purchaseOrderFooter, purchaseOrderPublicNotes: $purchaseOrderPublicNotes, invoiceLabels: $invoiceLabels, invoiceDesignId: $invoiceDesignId, quoteDesignId: $quoteDesignId, creditDesignId: $creditDesignId, purchaseOrderDesignId: $purchaseOrderDesignId, statementDesignId: $statementDesignId, deliveryNoteDesignId: $deliveryNoteDesignId, paymentReceiptDesignId: $paymentReceiptDesignId, paymentRefundDesignId: $paymentRefundDesignId, portalDesignId: $portalDesignId, invoiceNumberPattern: $invoiceNumberPattern, invoiceNumberCounter: $invoiceNumberCounter, recurringInvoiceNumberPattern: $recurringInvoiceNumberPattern, recurringInvoiceNumberCounter: $recurringInvoiceNumberCounter, quoteNumberPattern: $quoteNumberPattern, quoteNumberCounter: $quoteNumberCounter, recurringQuoteNumberPattern: $recurringQuoteNumberPattern, recurringQuoteNumberCounter: $recurringQuoteNumberCounter, clientNumberPattern: $clientNumberPattern, clientNumberCounter: $clientNumberCounter, creditNumberPattern: $creditNumberPattern, creditNumberCounter: $creditNumberCounter, taskNumberPattern: $taskNumberPattern, taskNumberCounter: $taskNumberCounter, expenseNumberPattern: $expenseNumberPattern, expenseNumberCounter: $expenseNumberCounter, recurringExpenseNumberPattern: $recurringExpenseNumberPattern, recurringExpenseNumberCounter: $recurringExpenseNumberCounter, vendorNumberPattern: $vendorNumberPattern, vendorNumberCounter: $vendorNumberCounter, ticketNumberPattern: $ticketNumberPattern, ticketNumberCounter: $ticketNumberCounter, paymentNumberPattern: $paymentNumberPattern, paymentNumberCounter: $paymentNumberCounter, projectNumberPattern: $projectNumberPattern, projectNumberCounter: $projectNumberCounter, purchaseOrderNumberPattern: $purchaseOrderNumberPattern, purchaseOrderNumberCounter: $purchaseOrderNumberCounter, sharedInvoiceQuoteCounter: $sharedInvoiceQuoteCounter, sharedInvoiceCreditCounter: $sharedInvoiceCreditCounter, recurringNumberPrefix: $recurringNumberPrefix, resetCounterFrequencyId: $resetCounterFrequencyId, resetCounterDate: $resetCounterDate, counterPadding: $counterPadding, counterNumberApplied: $counterNumberApplied, quoteNumberApplied: $quoteNumberApplied, taxName1: $taxName1, taxRate1: $taxRate1, taxName2: $taxName2, taxRate2: $taxRate2, taxName3: $taxName3, taxRate3: $taxRate3, invoiceTaxes: $invoiceTaxes, inclusiveTaxes: $inclusiveTaxes, enableRappenRounding: $enableRappenRounding, emailSendingMethod: $emailSendingMethod, gmailSendingUserId: $gmailSendingUserId, replyToEmail: $replyToEmail, replyToName: $replyToName, bccEmail: $bccEmail, emailFromName: $emailFromName, customSendingEmail: $customSendingEmail, emailStyle: $emailStyle, emailStyleCustom: $emailStyleCustom, emailSignature: $emailSignature, enableEmailMarkup: $enableEmailMarkup, showEmailFooter: $showEmailFooter, pdfEmailAttachment: $pdfEmailAttachment, ublEmailAttachment: $ublEmailAttachment, documentEmailAttachment: $documentEmailAttachment, sendEmailOnMarkPaid: $sendEmailOnMarkPaid, paymentEmailAllContacts: $paymentEmailAllContacts, postmarkSecret: $postmarkSecret, mailgunSecret: $mailgunSecret, mailgunDomain: $mailgunDomain, mailgunEndpoint: $mailgunEndpoint, brevoSecret: $brevoSecret, sesSecretKey: $sesSecretKey, sesAccessKey: $sesAccessKey, sesRegion: $sesRegion, sesTopicArn: $sesTopicArn, sesFromAddress: $sesFromAddress, emailSubjectInvoice: $emailSubjectInvoice, emailSubjectQuote: $emailSubjectQuote, emailSubjectCredit: $emailSubjectCredit, emailSubjectPayment: $emailSubjectPayment, emailSubjectPaymentPartial: $emailSubjectPaymentPartial, emailSubjectStatement: $emailSubjectStatement, emailSubjectPurchaseOrder: $emailSubjectPurchaseOrder, emailSubjectReminder1: $emailSubjectReminder1, emailSubjectReminder2: $emailSubjectReminder2, emailSubjectReminder3: $emailSubjectReminder3, emailSubjectReminderEndless: $emailSubjectReminderEndless, emailSubjectCustom1: $emailSubjectCustom1, emailSubjectCustom2: $emailSubjectCustom2, emailSubjectCustom3: $emailSubjectCustom3, emailTemplateInvoice: $emailTemplateInvoice, emailTemplateQuote: $emailTemplateQuote, emailTemplateCredit: $emailTemplateCredit, emailTemplatePayment: $emailTemplatePayment, emailTemplatePaymentPartial: $emailTemplatePaymentPartial, emailTemplateStatement: $emailTemplateStatement, emailTemplatePurchaseOrder: $emailTemplatePurchaseOrder, emailTemplateReminder1: $emailTemplateReminder1, emailTemplateReminder2: $emailTemplateReminder2, emailTemplateReminder3: $emailTemplateReminder3, emailTemplateReminderEndless: $emailTemplateReminderEndless, emailTemplateCustom1: $emailTemplateCustom1, emailTemplateCustom2: $emailTemplateCustom2, emailTemplateCustom3: $emailTemplateCustom3, sendReminders: $sendReminders, enableReminder1: $enableReminder1, enableReminder2: $enableReminder2, enableReminder3: $enableReminder3, enableReminderEndless: $enableReminderEndless, numDaysReminder1: $numDaysReminder1, numDaysReminder2: $numDaysReminder2, numDaysReminder3: $numDaysReminder3, scheduleReminder1: $scheduleReminder1, scheduleReminder2: $scheduleReminder2, scheduleReminder3: $scheduleReminder3, reminderSendTime: $reminderSendTime, lateFeeAmount1: $lateFeeAmount1, lateFeeAmount2: $lateFeeAmount2, lateFeeAmount3: $lateFeeAmount3, lateFeePercent1: $lateFeePercent1, lateFeePercent2: $lateFeePercent2, lateFeePercent3: $lateFeePercent3, endlessReminderFrequencyId: $endlessReminderFrequencyId, lateFeeEndlessAmount: $lateFeeEndlessAmount, lateFeeEndlessPercent: $lateFeeEndlessPercent, autoArchiveInvoice: $autoArchiveInvoice, autoArchiveInvoiceCancelled: $autoArchiveInvoiceCancelled, autoArchiveQuote: $autoArchiveQuote, autoConvertQuote: $autoConvertQuote, autoEmailInvoice: $autoEmailInvoice, autoBillStandardInvoices: $autoBillStandardInvoices, autoBill: $autoBill, autoBillDate: $autoBillDate, lockInvoices: $lockInvoices, entitySendTime: $entitySendTime, showAcceptInvoiceTerms: $showAcceptInvoiceTerms, showAcceptQuoteTerms: $showAcceptQuoteTerms, requireInvoiceSignature: $requireInvoiceSignature, requireQuoteSignature: $requireQuoteSignature, requirePurchaseOrderSignature: $requirePurchaseOrderSignature, signatureOnPdf: $signatureOnPdf, acceptClientInputQuoteApproval: $acceptClientInputQuoteApproval, syncInvoiceQuoteColumns: $syncInvoiceQuoteColumns, showShippingAddress: $showShippingAddress, showPaidStamp: $showPaidStamp, pageSize: $pageSize, pageLayout: $pageLayout, fontSize: $fontSize, primaryFont: $primaryFont, secondaryFont: $secondaryFont, primaryColor: $primaryColor, secondaryColor: $secondaryColor, pageNumbering: $pageNumbering, pageNumberingAlignment: $pageNumberingAlignment, hidePaidToDate: $hidePaidToDate, hideEmptyColumnsOnPdf: $hideEmptyColumnsOnPdf, embedDocuments: $embedDocuments, allPagesHeader: $allPagesHeader, allPagesFooter: $allPagesFooter, pdfVariables: $pdfVariables, showPdfhtmlOnMobile: $showPdfhtmlOnMobile, enableClientPortal: $enableClientPortal, enableClientPortalDashboard: $enableClientPortalDashboard, enableClientPortalTasks: $enableClientPortalTasks, showAllTasksClientPortal: $showAllTasksClientPortal, enableClientPortalPassword: $enableClientPortalPassword, clientPortalTerms: $clientPortalTerms, clientPortalPrivacyPolicy: $clientPortalPrivacyPolicy, clientPortalEnableUploads: $clientPortalEnableUploads, clientPortalAllowUnderPayment: $clientPortalAllowUnderPayment, clientPortalUnderPaymentMinimum: $clientPortalUnderPaymentMinimum, clientPortalAllowOverPayment: $clientPortalAllowOverPayment, portalCustomHead: $portalCustomHead, portalCustomCss: $portalCustomCss, portalCustomFooter: $portalCustomFooter, portalCustomJs: $portalCustomJs, clientCanRegister: $clientCanRegister, clientInitiatedPayments: $clientInitiatedPayments, clientInitiatedPaymentsMinimum: $clientInitiatedPaymentsMinimum, enableClientProfileUpdate: $enableClientProfileUpdate, clientOnlinePaymentNotification: $clientOnlinePaymentNotification, clientManualPaymentNotification: $clientManualPaymentNotification, vendorPortalEnableUploads: $vendorPortalEnableUploads, useCreditsPayment: $useCreditsPayment, useUnappliedPayment: $useUnappliedPayment, paymentTerms: $paymentTerms, validUntil: $validUntil, paymentTypeId: $paymentTypeId, defaultExpensePaymentTypeId: $defaultExpensePaymentTypeId, companyGatewayIds: $companyGatewayIds, paymentFlow: $paymentFlow, unlockInvoiceDocumentsAfterPayment: $unlockInvoiceDocumentsAfterPayment, showTaskItemDescription: $showTaskItemDescription, allowBillableTaskItems: $allowBillableTaskItems, defaultTaskRate: $defaultTaskRate, taskRoundUp: $taskRoundUp, taskRoundToNearest: $taskRoundToNearest, enableEInvoice: $enableEInvoice, eInvoiceType: $eInvoiceType, eQuoteType: $eQuoteType, mergeEInvoiceToPdf: $mergeEInvoiceToPdf, skipAutomaticEmailWithPeppol: $skipAutomaticEmailWithPeppol, eInvoiceForwardEmail: $eInvoiceForwardEmail, eExpenseForwardEmail: $eExpenseForwardEmail, preferenceProductNotesForHtmlView: $preferenceProductNotesForHtmlView, customMessageDashboard: $customMessageDashboard, customMessageUnpaidInvoice: $customMessageUnpaidInvoice, customMessagePaidInvoice: $customMessagePaidInvoice, customMessageUnapprovedQuote: $customMessageUnapprovedQuote, translations: $translations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanySettingsApiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.companyLogo, companyLogo) ||
                other.companyLogo == companyLogo) &&
            (identical(other.companyLogoSize, companyLogoSize) ||
                other.companyLogoSize == companyLogoSize) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address1, address1) ||
                other.address1 == address1) &&
            (identical(other.address2, address2) ||
                other.address2 == address2) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.vatNumber, vatNumber) ||
                other.vatNumber == vatNumber) &&
            (identical(other.idNumber, idNumber) ||
                other.idNumber == idNumber) &&
            (identical(other.classification, classification) ||
                other.classification == classification) &&
            (identical(other.qrIban, qrIban) || other.qrIban == qrIban) &&
            (identical(other.besrId, besrId) || other.besrId == besrId) &&
            (identical(other.customValue1, customValue1) ||
                other.customValue1 == customValue1) &&
            (identical(other.customValue2, customValue2) ||
                other.customValue2 == customValue2) &&
            (identical(other.customValue3, customValue3) ||
                other.customValue3 == customValue3) &&
            (identical(other.customValue4, customValue4) ||
                other.customValue4 == customValue4) &&
            (identical(other.timezoneId, timezoneId) ||
                other.timezoneId == timezoneId) &&
            (identical(other.dateFormatId, dateFormatId) ||
                other.dateFormatId == dateFormatId) &&
            (identical(other.languageId, languageId) ||
                other.languageId == languageId) &&
            (identical(other.currencyId, currencyId) ||
                other.currencyId == currencyId) &&
            (identical(other.militaryTime, militaryTime) ||
                other.militaryTime == militaryTime) &&
            (identical(other.showCurrencyCode, showCurrencyCode) ||
                other.showCurrencyCode == showCurrencyCode) &&
            (identical(other.useCommaAsDecimalPlace, useCommaAsDecimalPlace) ||
                other.useCommaAsDecimalPlace == useCommaAsDecimalPlace) &&
            (identical(other.firstMonthOfYear, firstMonthOfYear) ||
                other.firstMonthOfYear == firstMonthOfYear) &&
            (identical(other.invoiceTerms, invoiceTerms) ||
                other.invoiceTerms == invoiceTerms) &&
            (identical(other.invoiceFooter, invoiceFooter) ||
                other.invoiceFooter == invoiceFooter) &&
            (identical(other.quoteTerms, quoteTerms) ||
                other.quoteTerms == quoteTerms) &&
            (identical(other.quoteFooter, quoteFooter) ||
                other.quoteFooter == quoteFooter) &&
            (identical(other.creditTerms, creditTerms) ||
                other.creditTerms == creditTerms) &&
            (identical(other.creditFooter, creditFooter) ||
                other.creditFooter == creditFooter) &&
            (identical(other.purchaseOrderTerms, purchaseOrderTerms) ||
                other.purchaseOrderTerms == purchaseOrderTerms) &&
            (identical(other.purchaseOrderFooter, purchaseOrderFooter) ||
                other.purchaseOrderFooter == purchaseOrderFooter) &&
            (identical(
                  other.purchaseOrderPublicNotes,
                  purchaseOrderPublicNotes,
                ) ||
                other.purchaseOrderPublicNotes == purchaseOrderPublicNotes) &&
            (identical(other.invoiceLabels, invoiceLabels) ||
                other.invoiceLabels == invoiceLabels) &&
            (identical(other.invoiceDesignId, invoiceDesignId) ||
                other.invoiceDesignId == invoiceDesignId) &&
            (identical(other.quoteDesignId, quoteDesignId) ||
                other.quoteDesignId == quoteDesignId) &&
            (identical(other.creditDesignId, creditDesignId) ||
                other.creditDesignId == creditDesignId) &&
            (identical(other.purchaseOrderDesignId, purchaseOrderDesignId) ||
                other.purchaseOrderDesignId == purchaseOrderDesignId) &&
            (identical(other.statementDesignId, statementDesignId) ||
                other.statementDesignId == statementDesignId) &&
            (identical(other.deliveryNoteDesignId, deliveryNoteDesignId) ||
                other.deliveryNoteDesignId == deliveryNoteDesignId) &&
            (identical(other.paymentReceiptDesignId, paymentReceiptDesignId) ||
                other.paymentReceiptDesignId == paymentReceiptDesignId) &&
            (identical(other.paymentRefundDesignId, paymentRefundDesignId) ||
                other.paymentRefundDesignId == paymentRefundDesignId) &&
            (identical(other.portalDesignId, portalDesignId) ||
                other.portalDesignId == portalDesignId) &&
            (identical(other.invoiceNumberPattern, invoiceNumberPattern) ||
                other.invoiceNumberPattern == invoiceNumberPattern) &&
            (identical(other.invoiceNumberCounter, invoiceNumberCounter) ||
                other.invoiceNumberCounter == invoiceNumberCounter) &&
            (identical(
                  other.recurringInvoiceNumberPattern,
                  recurringInvoiceNumberPattern,
                ) ||
                other.recurringInvoiceNumberPattern ==
                    recurringInvoiceNumberPattern) &&
            (identical(
                  other.recurringInvoiceNumberCounter,
                  recurringInvoiceNumberCounter,
                ) ||
                other.recurringInvoiceNumberCounter ==
                    recurringInvoiceNumberCounter) &&
            (identical(other.quoteNumberPattern, quoteNumberPattern) ||
                other.quoteNumberPattern == quoteNumberPattern) &&
            (identical(other.quoteNumberCounter, quoteNumberCounter) ||
                other.quoteNumberCounter == quoteNumberCounter) &&
            (identical(
                  other.recurringQuoteNumberPattern,
                  recurringQuoteNumberPattern,
                ) ||
                other.recurringQuoteNumberPattern ==
                    recurringQuoteNumberPattern) &&
            (identical(
                  other.recurringQuoteNumberCounter,
                  recurringQuoteNumberCounter,
                ) ||
                other.recurringQuoteNumberCounter ==
                    recurringQuoteNumberCounter) &&
            (identical(other.clientNumberPattern, clientNumberPattern) ||
                other.clientNumberPattern == clientNumberPattern) &&
            (identical(other.clientNumberCounter, clientNumberCounter) ||
                other.clientNumberCounter == clientNumberCounter) &&
            (identical(other.creditNumberPattern, creditNumberPattern) ||
                other.creditNumberPattern == creditNumberPattern) &&
            (identical(other.creditNumberCounter, creditNumberCounter) ||
                other.creditNumberCounter == creditNumberCounter) &&
            (identical(other.taskNumberPattern, taskNumberPattern) ||
                other.taskNumberPattern == taskNumberPattern) &&
            (identical(other.taskNumberCounter, taskNumberCounter) ||
                other.taskNumberCounter == taskNumberCounter) &&
            (identical(other.expenseNumberPattern, expenseNumberPattern) ||
                other.expenseNumberPattern == expenseNumberPattern) &&
            (identical(other.expenseNumberCounter, expenseNumberCounter) ||
                other.expenseNumberCounter == expenseNumberCounter) &&
            (identical(
                  other.recurringExpenseNumberPattern,
                  recurringExpenseNumberPattern,
                ) ||
                other.recurringExpenseNumberPattern ==
                    recurringExpenseNumberPattern) &&
            (identical(
                  other.recurringExpenseNumberCounter,
                  recurringExpenseNumberCounter,
                ) ||
                other.recurringExpenseNumberCounter ==
                    recurringExpenseNumberCounter) &&
            (identical(other.vendorNumberPattern, vendorNumberPattern) ||
                other.vendorNumberPattern == vendorNumberPattern) &&
            (identical(other.vendorNumberCounter, vendorNumberCounter) ||
                other.vendorNumberCounter == vendorNumberCounter) &&
            (identical(other.ticketNumberPattern, ticketNumberPattern) ||
                other.ticketNumberPattern == ticketNumberPattern) &&
            (identical(other.ticketNumberCounter, ticketNumberCounter) ||
                other.ticketNumberCounter == ticketNumberCounter) &&
            (identical(other.paymentNumberPattern, paymentNumberPattern) ||
                other.paymentNumberPattern == paymentNumberPattern) &&
            (identical(other.paymentNumberCounter, paymentNumberCounter) ||
                other.paymentNumberCounter == paymentNumberCounter) &&
            (identical(other.projectNumberPattern, projectNumberPattern) ||
                other.projectNumberPattern == projectNumberPattern) &&
            (identical(other.projectNumberCounter, projectNumberCounter) ||
                other.projectNumberCounter == projectNumberCounter) &&
            (identical(
                  other.purchaseOrderNumberPattern,
                  purchaseOrderNumberPattern,
                ) ||
                other.purchaseOrderNumberPattern ==
                    purchaseOrderNumberPattern) &&
            (identical(
                  other.purchaseOrderNumberCounter,
                  purchaseOrderNumberCounter,
                ) ||
                other.purchaseOrderNumberCounter ==
                    purchaseOrderNumberCounter) &&
            (identical(
                  other.sharedInvoiceQuoteCounter,
                  sharedInvoiceQuoteCounter,
                ) ||
                other.sharedInvoiceQuoteCounter == sharedInvoiceQuoteCounter) &&
            (identical(
                  other.sharedInvoiceCreditCounter,
                  sharedInvoiceCreditCounter,
                ) ||
                other.sharedInvoiceCreditCounter ==
                    sharedInvoiceCreditCounter) &&
            (identical(other.recurringNumberPrefix, recurringNumberPrefix) ||
                other.recurringNumberPrefix == recurringNumberPrefix) &&
            (identical(
                  other.resetCounterFrequencyId,
                  resetCounterFrequencyId,
                ) ||
                other.resetCounterFrequencyId == resetCounterFrequencyId) &&
            (identical(other.resetCounterDate, resetCounterDate) ||
                other.resetCounterDate == resetCounterDate) &&
            (identical(other.counterPadding, counterPadding) ||
                other.counterPadding == counterPadding) &&
            (identical(other.counterNumberApplied, counterNumberApplied) ||
                other.counterNumberApplied == counterNumberApplied) &&
            (identical(other.quoteNumberApplied, quoteNumberApplied) ||
                other.quoteNumberApplied == quoteNumberApplied) &&
            (identical(other.taxName1, taxName1) ||
                other.taxName1 == taxName1) &&
            (identical(other.taxRate1, taxRate1) ||
                other.taxRate1 == taxRate1) &&
            (identical(other.taxName2, taxName2) ||
                other.taxName2 == taxName2) &&
            (identical(other.taxRate2, taxRate2) ||
                other.taxRate2 == taxRate2) &&
            (identical(other.taxName3, taxName3) ||
                other.taxName3 == taxName3) &&
            (identical(other.taxRate3, taxRate3) ||
                other.taxRate3 == taxRate3) &&
            (identical(other.invoiceTaxes, invoiceTaxes) ||
                other.invoiceTaxes == invoiceTaxes) &&
            (identical(other.inclusiveTaxes, inclusiveTaxes) ||
                other.inclusiveTaxes == inclusiveTaxes) &&
            (identical(other.enableRappenRounding, enableRappenRounding) ||
                other.enableRappenRounding == enableRappenRounding) &&
            (identical(other.emailSendingMethod, emailSendingMethod) ||
                other.emailSendingMethod == emailSendingMethod) &&
            (identical(other.gmailSendingUserId, gmailSendingUserId) ||
                other.gmailSendingUserId == gmailSendingUserId) &&
            (identical(other.replyToEmail, replyToEmail) ||
                other.replyToEmail == replyToEmail) &&
            (identical(other.replyToName, replyToName) ||
                other.replyToName == replyToName) &&
            (identical(other.bccEmail, bccEmail) ||
                other.bccEmail == bccEmail) &&
            (identical(other.emailFromName, emailFromName) ||
                other.emailFromName == emailFromName) &&
            (identical(other.customSendingEmail, customSendingEmail) ||
                other.customSendingEmail == customSendingEmail) &&
            (identical(other.emailStyle, emailStyle) ||
                other.emailStyle == emailStyle) &&
            (identical(other.emailStyleCustom, emailStyleCustom) ||
                other.emailStyleCustom == emailStyleCustom) &&
            (identical(other.emailSignature, emailSignature) ||
                other.emailSignature == emailSignature) &&
            (identical(other.enableEmailMarkup, enableEmailMarkup) ||
                other.enableEmailMarkup == enableEmailMarkup) &&
            (identical(other.showEmailFooter, showEmailFooter) ||
                other.showEmailFooter == showEmailFooter) &&
            (identical(other.pdfEmailAttachment, pdfEmailAttachment) ||
                other.pdfEmailAttachment == pdfEmailAttachment) &&
            (identical(other.ublEmailAttachment, ublEmailAttachment) ||
                other.ublEmailAttachment == ublEmailAttachment) &&
            (identical(
                  other.documentEmailAttachment,
                  documentEmailAttachment,
                ) ||
                other.documentEmailAttachment == documentEmailAttachment) &&
            (identical(other.sendEmailOnMarkPaid, sendEmailOnMarkPaid) ||
                other.sendEmailOnMarkPaid == sendEmailOnMarkPaid) &&
            (identical(
                  other.paymentEmailAllContacts,
                  paymentEmailAllContacts,
                ) ||
                other.paymentEmailAllContacts == paymentEmailAllContacts) &&
            (identical(other.postmarkSecret, postmarkSecret) ||
                other.postmarkSecret == postmarkSecret) &&
            (identical(other.mailgunSecret, mailgunSecret) ||
                other.mailgunSecret == mailgunSecret) &&
            (identical(other.mailgunDomain, mailgunDomain) ||
                other.mailgunDomain == mailgunDomain) &&
            (identical(other.mailgunEndpoint, mailgunEndpoint) ||
                other.mailgunEndpoint == mailgunEndpoint) &&
            (identical(other.brevoSecret, brevoSecret) ||
                other.brevoSecret == brevoSecret) &&
            (identical(other.sesSecretKey, sesSecretKey) ||
                other.sesSecretKey == sesSecretKey) &&
            (identical(other.sesAccessKey, sesAccessKey) ||
                other.sesAccessKey == sesAccessKey) &&
            (identical(other.sesRegion, sesRegion) ||
                other.sesRegion == sesRegion) &&
            (identical(other.sesTopicArn, sesTopicArn) ||
                other.sesTopicArn == sesTopicArn) &&
            (identical(other.sesFromAddress, sesFromAddress) ||
                other.sesFromAddress == sesFromAddress) &&
            (identical(other.emailSubjectInvoice, emailSubjectInvoice) ||
                other.emailSubjectInvoice == emailSubjectInvoice) &&
            (identical(other.emailSubjectQuote, emailSubjectQuote) ||
                other.emailSubjectQuote == emailSubjectQuote) &&
            (identical(other.emailSubjectCredit, emailSubjectCredit) ||
                other.emailSubjectCredit == emailSubjectCredit) &&
            (identical(other.emailSubjectPayment, emailSubjectPayment) ||
                other.emailSubjectPayment == emailSubjectPayment) &&
            (identical(
                  other.emailSubjectPaymentPartial,
                  emailSubjectPaymentPartial,
                ) ||
                other.emailSubjectPaymentPartial ==
                    emailSubjectPaymentPartial) &&
            (identical(other.emailSubjectStatement, emailSubjectStatement) ||
                other.emailSubjectStatement == emailSubjectStatement) &&
            (identical(
                  other.emailSubjectPurchaseOrder,
                  emailSubjectPurchaseOrder,
                ) ||
                other.emailSubjectPurchaseOrder == emailSubjectPurchaseOrder) &&
            (identical(other.emailSubjectReminder1, emailSubjectReminder1) ||
                other.emailSubjectReminder1 == emailSubjectReminder1) &&
            (identical(other.emailSubjectReminder2, emailSubjectReminder2) ||
                other.emailSubjectReminder2 == emailSubjectReminder2) &&
            (identical(other.emailSubjectReminder3, emailSubjectReminder3) ||
                other.emailSubjectReminder3 == emailSubjectReminder3) &&
            (identical(
                  other.emailSubjectReminderEndless,
                  emailSubjectReminderEndless,
                ) ||
                other.emailSubjectReminderEndless ==
                    emailSubjectReminderEndless) &&
            (identical(other.emailSubjectCustom1, emailSubjectCustom1) ||
                other.emailSubjectCustom1 == emailSubjectCustom1) &&
            (identical(other.emailSubjectCustom2, emailSubjectCustom2) ||
                other.emailSubjectCustom2 == emailSubjectCustom2) &&
            (identical(other.emailSubjectCustom3, emailSubjectCustom3) ||
                other.emailSubjectCustom3 == emailSubjectCustom3) &&
            (identical(other.emailTemplateInvoice, emailTemplateInvoice) ||
                other.emailTemplateInvoice == emailTemplateInvoice) &&
            (identical(other.emailTemplateQuote, emailTemplateQuote) ||
                other.emailTemplateQuote == emailTemplateQuote) &&
            (identical(other.emailTemplateCredit, emailTemplateCredit) ||
                other.emailTemplateCredit == emailTemplateCredit) &&
            (identical(other.emailTemplatePayment, emailTemplatePayment) ||
                other.emailTemplatePayment == emailTemplatePayment) &&
            (identical(
                  other.emailTemplatePaymentPartial,
                  emailTemplatePaymentPartial,
                ) ||
                other.emailTemplatePaymentPartial ==
                    emailTemplatePaymentPartial) &&
            (identical(other.emailTemplateStatement, emailTemplateStatement) ||
                other.emailTemplateStatement == emailTemplateStatement) &&
            (identical(
                  other.emailTemplatePurchaseOrder,
                  emailTemplatePurchaseOrder,
                ) ||
                other.emailTemplatePurchaseOrder ==
                    emailTemplatePurchaseOrder) &&
            (identical(other.emailTemplateReminder1, emailTemplateReminder1) ||
                other.emailTemplateReminder1 == emailTemplateReminder1) &&
            (identical(other.emailTemplateReminder2, emailTemplateReminder2) ||
                other.emailTemplateReminder2 == emailTemplateReminder2) &&
            (identical(other.emailTemplateReminder3, emailTemplateReminder3) ||
                other.emailTemplateReminder3 == emailTemplateReminder3) &&
            (identical(
                  other.emailTemplateReminderEndless,
                  emailTemplateReminderEndless,
                ) ||
                other.emailTemplateReminderEndless ==
                    emailTemplateReminderEndless) &&
            (identical(other.emailTemplateCustom1, emailTemplateCustom1) ||
                other.emailTemplateCustom1 == emailTemplateCustom1) &&
            (identical(other.emailTemplateCustom2, emailTemplateCustom2) ||
                other.emailTemplateCustom2 == emailTemplateCustom2) &&
            (identical(other.emailTemplateCustom3, emailTemplateCustom3) ||
                other.emailTemplateCustom3 == emailTemplateCustom3) &&
            (identical(other.sendReminders, sendReminders) ||
                other.sendReminders == sendReminders) &&
            (identical(other.enableReminder1, enableReminder1) ||
                other.enableReminder1 == enableReminder1) &&
            (identical(other.enableReminder2, enableReminder2) ||
                other.enableReminder2 == enableReminder2) &&
            (identical(other.enableReminder3, enableReminder3) ||
                other.enableReminder3 == enableReminder3) &&
            (identical(other.enableReminderEndless, enableReminderEndless) ||
                other.enableReminderEndless == enableReminderEndless) &&
            (identical(other.numDaysReminder1, numDaysReminder1) ||
                other.numDaysReminder1 == numDaysReminder1) &&
            (identical(other.numDaysReminder2, numDaysReminder2) ||
                other.numDaysReminder2 == numDaysReminder2) &&
            (identical(other.numDaysReminder3, numDaysReminder3) ||
                other.numDaysReminder3 == numDaysReminder3) &&
            (identical(other.scheduleReminder1, scheduleReminder1) ||
                other.scheduleReminder1 == scheduleReminder1) &&
            (identical(other.scheduleReminder2, scheduleReminder2) ||
                other.scheduleReminder2 == scheduleReminder2) &&
            (identical(other.scheduleReminder3, scheduleReminder3) ||
                other.scheduleReminder3 == scheduleReminder3) &&
            (identical(other.reminderSendTime, reminderSendTime) ||
                other.reminderSendTime == reminderSendTime) &&
            (identical(other.lateFeeAmount1, lateFeeAmount1) ||
                other.lateFeeAmount1 == lateFeeAmount1) &&
            (identical(other.lateFeeAmount2, lateFeeAmount2) ||
                other.lateFeeAmount2 == lateFeeAmount2) &&
            (identical(other.lateFeeAmount3, lateFeeAmount3) ||
                other.lateFeeAmount3 == lateFeeAmount3) &&
            (identical(other.lateFeePercent1, lateFeePercent1) ||
                other.lateFeePercent1 == lateFeePercent1) &&
            (identical(other.lateFeePercent2, lateFeePercent2) ||
                other.lateFeePercent2 == lateFeePercent2) &&
            (identical(other.lateFeePercent3, lateFeePercent3) ||
                other.lateFeePercent3 == lateFeePercent3) &&
            (identical(
                  other.endlessReminderFrequencyId,
                  endlessReminderFrequencyId,
                ) ||
                other.endlessReminderFrequencyId ==
                    endlessReminderFrequencyId) &&
            (identical(other.lateFeeEndlessAmount, lateFeeEndlessAmount) ||
                other.lateFeeEndlessAmount == lateFeeEndlessAmount) &&
            (identical(other.lateFeeEndlessPercent, lateFeeEndlessPercent) ||
                other.lateFeeEndlessPercent == lateFeeEndlessPercent) &&
            (identical(other.autoArchiveInvoice, autoArchiveInvoice) ||
                other.autoArchiveInvoice == autoArchiveInvoice) &&
            (identical(
                  other.autoArchiveInvoiceCancelled,
                  autoArchiveInvoiceCancelled,
                ) ||
                other.autoArchiveInvoiceCancelled ==
                    autoArchiveInvoiceCancelled) &&
            (identical(other.autoArchiveQuote, autoArchiveQuote) ||
                other.autoArchiveQuote == autoArchiveQuote) &&
            (identical(other.autoConvertQuote, autoConvertQuote) ||
                other.autoConvertQuote == autoConvertQuote) &&
            (identical(other.autoEmailInvoice, autoEmailInvoice) ||
                other.autoEmailInvoice == autoEmailInvoice) &&
            (identical(
                  other.autoBillStandardInvoices,
                  autoBillStandardInvoices,
                ) ||
                other.autoBillStandardInvoices == autoBillStandardInvoices) &&
            (identical(other.autoBill, autoBill) ||
                other.autoBill == autoBill) &&
            (identical(other.autoBillDate, autoBillDate) ||
                other.autoBillDate == autoBillDate) &&
            (identical(other.lockInvoices, lockInvoices) ||
                other.lockInvoices == lockInvoices) &&
            (identical(other.entitySendTime, entitySendTime) ||
                other.entitySendTime == entitySendTime) &&
            (identical(other.showAcceptInvoiceTerms, showAcceptInvoiceTerms) ||
                other.showAcceptInvoiceTerms == showAcceptInvoiceTerms) &&
            (identical(other.showAcceptQuoteTerms, showAcceptQuoteTerms) ||
                other.showAcceptQuoteTerms == showAcceptQuoteTerms) &&
            (identical(
                  other.requireInvoiceSignature,
                  requireInvoiceSignature,
                ) ||
                other.requireInvoiceSignature == requireInvoiceSignature) &&
            (identical(other.requireQuoteSignature, requireQuoteSignature) ||
                other.requireQuoteSignature == requireQuoteSignature) &&
            (identical(
                  other.requirePurchaseOrderSignature,
                  requirePurchaseOrderSignature,
                ) ||
                other.requirePurchaseOrderSignature ==
                    requirePurchaseOrderSignature) &&
            (identical(other.signatureOnPdf, signatureOnPdf) ||
                other.signatureOnPdf == signatureOnPdf) &&
            (identical(
                  other.acceptClientInputQuoteApproval,
                  acceptClientInputQuoteApproval,
                ) ||
                other.acceptClientInputQuoteApproval ==
                    acceptClientInputQuoteApproval) &&
            (identical(
                  other.syncInvoiceQuoteColumns,
                  syncInvoiceQuoteColumns,
                ) ||
                other.syncInvoiceQuoteColumns == syncInvoiceQuoteColumns) &&
            (identical(other.showShippingAddress, showShippingAddress) ||
                other.showShippingAddress == showShippingAddress) &&
            (identical(other.showPaidStamp, showPaidStamp) ||
                other.showPaidStamp == showPaidStamp) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.pageLayout, pageLayout) ||
                other.pageLayout == pageLayout) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.primaryFont, primaryFont) ||
                other.primaryFont == primaryFont) &&
            (identical(other.secondaryFont, secondaryFont) ||
                other.secondaryFont == secondaryFont) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor) &&
            (identical(other.pageNumbering, pageNumbering) ||
                other.pageNumbering == pageNumbering) &&
            (identical(other.pageNumberingAlignment, pageNumberingAlignment) ||
                other.pageNumberingAlignment == pageNumberingAlignment) &&
            (identical(other.hidePaidToDate, hidePaidToDate) ||
                other.hidePaidToDate == hidePaidToDate) &&
            (identical(other.hideEmptyColumnsOnPdf, hideEmptyColumnsOnPdf) ||
                other.hideEmptyColumnsOnPdf == hideEmptyColumnsOnPdf) &&
            (identical(other.embedDocuments, embedDocuments) ||
                other.embedDocuments == embedDocuments) &&
            (identical(other.allPagesHeader, allPagesHeader) ||
                other.allPagesHeader == allPagesHeader) &&
            (identical(other.allPagesFooter, allPagesFooter) ||
                other.allPagesFooter == allPagesFooter) &&
            const DeepCollectionEquality().equals(
              other._pdfVariables,
              _pdfVariables,
            ) &&
            (identical(other.showPdfhtmlOnMobile, showPdfhtmlOnMobile) ||
                other.showPdfhtmlOnMobile == showPdfhtmlOnMobile) &&
            (identical(other.enableClientPortal, enableClientPortal) ||
                other.enableClientPortal == enableClientPortal) &&
            (identical(
                  other.enableClientPortalDashboard,
                  enableClientPortalDashboard,
                ) ||
                other.enableClientPortalDashboard ==
                    enableClientPortalDashboard) &&
            (identical(
                  other.enableClientPortalTasks,
                  enableClientPortalTasks,
                ) ||
                other.enableClientPortalTasks == enableClientPortalTasks) &&
            (identical(
                  other.showAllTasksClientPortal,
                  showAllTasksClientPortal,
                ) ||
                other.showAllTasksClientPortal == showAllTasksClientPortal) &&
            (identical(
                  other.enableClientPortalPassword,
                  enableClientPortalPassword,
                ) ||
                other.enableClientPortalPassword ==
                    enableClientPortalPassword) &&
            (identical(other.clientPortalTerms, clientPortalTerms) ||
                other.clientPortalTerms == clientPortalTerms) &&
            (identical(
                  other.clientPortalPrivacyPolicy,
                  clientPortalPrivacyPolicy,
                ) ||
                other.clientPortalPrivacyPolicy == clientPortalPrivacyPolicy) &&
            (identical(
                  other.clientPortalEnableUploads,
                  clientPortalEnableUploads,
                ) ||
                other.clientPortalEnableUploads == clientPortalEnableUploads) &&
            (identical(
                  other.clientPortalAllowUnderPayment,
                  clientPortalAllowUnderPayment,
                ) ||
                other.clientPortalAllowUnderPayment ==
                    clientPortalAllowUnderPayment) &&
            (identical(
                  other.clientPortalUnderPaymentMinimum,
                  clientPortalUnderPaymentMinimum,
                ) ||
                other.clientPortalUnderPaymentMinimum ==
                    clientPortalUnderPaymentMinimum) &&
            (identical(
                  other.clientPortalAllowOverPayment,
                  clientPortalAllowOverPayment,
                ) ||
                other.clientPortalAllowOverPayment ==
                    clientPortalAllowOverPayment) &&
            (identical(other.portalCustomHead, portalCustomHead) ||
                other.portalCustomHead == portalCustomHead) &&
            (identical(other.portalCustomCss, portalCustomCss) ||
                other.portalCustomCss == portalCustomCss) &&
            (identical(other.portalCustomFooter, portalCustomFooter) ||
                other.portalCustomFooter == portalCustomFooter) &&
            (identical(other.portalCustomJs, portalCustomJs) ||
                other.portalCustomJs == portalCustomJs) &&
            (identical(other.clientCanRegister, clientCanRegister) ||
                other.clientCanRegister == clientCanRegister) &&
            (identical(
                  other.clientInitiatedPayments,
                  clientInitiatedPayments,
                ) ||
                other.clientInitiatedPayments == clientInitiatedPayments) &&
            (identical(
                  other.clientInitiatedPaymentsMinimum,
                  clientInitiatedPaymentsMinimum,
                ) ||
                other.clientInitiatedPaymentsMinimum ==
                    clientInitiatedPaymentsMinimum) &&
            (identical(
                  other.enableClientProfileUpdate,
                  enableClientProfileUpdate,
                ) ||
                other.enableClientProfileUpdate == enableClientProfileUpdate) &&
            (identical(
                  other.clientOnlinePaymentNotification,
                  clientOnlinePaymentNotification,
                ) ||
                other.clientOnlinePaymentNotification ==
                    clientOnlinePaymentNotification) &&
            (identical(
                  other.clientManualPaymentNotification,
                  clientManualPaymentNotification,
                ) ||
                other.clientManualPaymentNotification ==
                    clientManualPaymentNotification) &&
            (identical(
                  other.vendorPortalEnableUploads,
                  vendorPortalEnableUploads,
                ) ||
                other.vendorPortalEnableUploads == vendorPortalEnableUploads) &&
            (identical(other.useCreditsPayment, useCreditsPayment) ||
                other.useCreditsPayment == useCreditsPayment) &&
            (identical(other.useUnappliedPayment, useUnappliedPayment) ||
                other.useUnappliedPayment == useUnappliedPayment) &&
            (identical(other.paymentTerms, paymentTerms) ||
                other.paymentTerms == paymentTerms) &&
            (identical(other.validUntil, validUntil) ||
                other.validUntil == validUntil) &&
            (identical(other.paymentTypeId, paymentTypeId) ||
                other.paymentTypeId == paymentTypeId) &&
            (identical(
                  other.defaultExpensePaymentTypeId,
                  defaultExpensePaymentTypeId,
                ) ||
                other.defaultExpensePaymentTypeId ==
                    defaultExpensePaymentTypeId) &&
            (identical(other.companyGatewayIds, companyGatewayIds) ||
                other.companyGatewayIds == companyGatewayIds) &&
            (identical(other.paymentFlow, paymentFlow) ||
                other.paymentFlow == paymentFlow) &&
            (identical(
                  other.unlockInvoiceDocumentsAfterPayment,
                  unlockInvoiceDocumentsAfterPayment,
                ) ||
                other.unlockInvoiceDocumentsAfterPayment ==
                    unlockInvoiceDocumentsAfterPayment) &&
            (identical(
                  other.showTaskItemDescription,
                  showTaskItemDescription,
                ) ||
                other.showTaskItemDescription == showTaskItemDescription) &&
            (identical(other.allowBillableTaskItems, allowBillableTaskItems) ||
                other.allowBillableTaskItems == allowBillableTaskItems) &&
            (identical(other.defaultTaskRate, defaultTaskRate) ||
                other.defaultTaskRate == defaultTaskRate) &&
            (identical(other.taskRoundUp, taskRoundUp) ||
                other.taskRoundUp == taskRoundUp) &&
            (identical(other.taskRoundToNearest, taskRoundToNearest) ||
                other.taskRoundToNearest == taskRoundToNearest) &&
            (identical(other.enableEInvoice, enableEInvoice) ||
                other.enableEInvoice == enableEInvoice) &&
            (identical(other.eInvoiceType, eInvoiceType) ||
                other.eInvoiceType == eInvoiceType) &&
            (identical(other.eQuoteType, eQuoteType) ||
                other.eQuoteType == eQuoteType) &&
            (identical(other.mergeEInvoiceToPdf, mergeEInvoiceToPdf) ||
                other.mergeEInvoiceToPdf == mergeEInvoiceToPdf) &&
            (identical(
                  other.skipAutomaticEmailWithPeppol,
                  skipAutomaticEmailWithPeppol,
                ) ||
                other.skipAutomaticEmailWithPeppol ==
                    skipAutomaticEmailWithPeppol) &&
            (identical(other.eInvoiceForwardEmail, eInvoiceForwardEmail) ||
                other.eInvoiceForwardEmail == eInvoiceForwardEmail) &&
            (identical(other.eExpenseForwardEmail, eExpenseForwardEmail) ||
                other.eExpenseForwardEmail == eExpenseForwardEmail) &&
            (identical(
                  other.preferenceProductNotesForHtmlView,
                  preferenceProductNotesForHtmlView,
                ) ||
                other.preferenceProductNotesForHtmlView ==
                    preferenceProductNotesForHtmlView) &&
            (identical(other.customMessageDashboard, customMessageDashboard) ||
                other.customMessageDashboard == customMessageDashboard) &&
            (identical(
                  other.customMessageUnpaidInvoice,
                  customMessageUnpaidInvoice,
                ) ||
                other.customMessageUnpaidInvoice ==
                    customMessageUnpaidInvoice) &&
            (identical(
                  other.customMessagePaidInvoice,
                  customMessagePaidInvoice,
                ) ||
                other.customMessagePaidInvoice == customMessagePaidInvoice) &&
            (identical(
                  other.customMessageUnapprovedQuote,
                  customMessageUnapprovedQuote,
                ) ||
                other.customMessageUnapprovedQuote ==
                    customMessageUnapprovedQuote) &&
            const DeepCollectionEquality().equals(
              other._translations,
              _translations,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    companyLogo,
    companyLogoSize,
    website,
    phone,
    email,
    address1,
    address2,
    city,
    state,
    postalCode,
    countryId,
    vatNumber,
    idNumber,
    classification,
    qrIban,
    besrId,
    customValue1,
    customValue2,
    customValue3,
    customValue4,
    timezoneId,
    dateFormatId,
    languageId,
    currencyId,
    militaryTime,
    showCurrencyCode,
    useCommaAsDecimalPlace,
    firstMonthOfYear,
    invoiceTerms,
    invoiceFooter,
    quoteTerms,
    quoteFooter,
    creditTerms,
    creditFooter,
    purchaseOrderTerms,
    purchaseOrderFooter,
    purchaseOrderPublicNotes,
    invoiceLabels,
    invoiceDesignId,
    quoteDesignId,
    creditDesignId,
    purchaseOrderDesignId,
    statementDesignId,
    deliveryNoteDesignId,
    paymentReceiptDesignId,
    paymentRefundDesignId,
    portalDesignId,
    invoiceNumberPattern,
    invoiceNumberCounter,
    recurringInvoiceNumberPattern,
    recurringInvoiceNumberCounter,
    quoteNumberPattern,
    quoteNumberCounter,
    recurringQuoteNumberPattern,
    recurringQuoteNumberCounter,
    clientNumberPattern,
    clientNumberCounter,
    creditNumberPattern,
    creditNumberCounter,
    taskNumberPattern,
    taskNumberCounter,
    expenseNumberPattern,
    expenseNumberCounter,
    recurringExpenseNumberPattern,
    recurringExpenseNumberCounter,
    vendorNumberPattern,
    vendorNumberCounter,
    ticketNumberPattern,
    ticketNumberCounter,
    paymentNumberPattern,
    paymentNumberCounter,
    projectNumberPattern,
    projectNumberCounter,
    purchaseOrderNumberPattern,
    purchaseOrderNumberCounter,
    sharedInvoiceQuoteCounter,
    sharedInvoiceCreditCounter,
    recurringNumberPrefix,
    resetCounterFrequencyId,
    resetCounterDate,
    counterPadding,
    counterNumberApplied,
    quoteNumberApplied,
    taxName1,
    taxRate1,
    taxName2,
    taxRate2,
    taxName3,
    taxRate3,
    invoiceTaxes,
    inclusiveTaxes,
    enableRappenRounding,
    emailSendingMethod,
    gmailSendingUserId,
    replyToEmail,
    replyToName,
    bccEmail,
    emailFromName,
    customSendingEmail,
    emailStyle,
    emailStyleCustom,
    emailSignature,
    enableEmailMarkup,
    showEmailFooter,
    pdfEmailAttachment,
    ublEmailAttachment,
    documentEmailAttachment,
    sendEmailOnMarkPaid,
    paymentEmailAllContacts,
    postmarkSecret,
    mailgunSecret,
    mailgunDomain,
    mailgunEndpoint,
    brevoSecret,
    sesSecretKey,
    sesAccessKey,
    sesRegion,
    sesTopicArn,
    sesFromAddress,
    emailSubjectInvoice,
    emailSubjectQuote,
    emailSubjectCredit,
    emailSubjectPayment,
    emailSubjectPaymentPartial,
    emailSubjectStatement,
    emailSubjectPurchaseOrder,
    emailSubjectReminder1,
    emailSubjectReminder2,
    emailSubjectReminder3,
    emailSubjectReminderEndless,
    emailSubjectCustom1,
    emailSubjectCustom2,
    emailSubjectCustom3,
    emailTemplateInvoice,
    emailTemplateQuote,
    emailTemplateCredit,
    emailTemplatePayment,
    emailTemplatePaymentPartial,
    emailTemplateStatement,
    emailTemplatePurchaseOrder,
    emailTemplateReminder1,
    emailTemplateReminder2,
    emailTemplateReminder3,
    emailTemplateReminderEndless,
    emailTemplateCustom1,
    emailTemplateCustom2,
    emailTemplateCustom3,
    sendReminders,
    enableReminder1,
    enableReminder2,
    enableReminder3,
    enableReminderEndless,
    numDaysReminder1,
    numDaysReminder2,
    numDaysReminder3,
    scheduleReminder1,
    scheduleReminder2,
    scheduleReminder3,
    reminderSendTime,
    lateFeeAmount1,
    lateFeeAmount2,
    lateFeeAmount3,
    lateFeePercent1,
    lateFeePercent2,
    lateFeePercent3,
    endlessReminderFrequencyId,
    lateFeeEndlessAmount,
    lateFeeEndlessPercent,
    autoArchiveInvoice,
    autoArchiveInvoiceCancelled,
    autoArchiveQuote,
    autoConvertQuote,
    autoEmailInvoice,
    autoBillStandardInvoices,
    autoBill,
    autoBillDate,
    lockInvoices,
    entitySendTime,
    showAcceptInvoiceTerms,
    showAcceptQuoteTerms,
    requireInvoiceSignature,
    requireQuoteSignature,
    requirePurchaseOrderSignature,
    signatureOnPdf,
    acceptClientInputQuoteApproval,
    syncInvoiceQuoteColumns,
    showShippingAddress,
    showPaidStamp,
    pageSize,
    pageLayout,
    fontSize,
    primaryFont,
    secondaryFont,
    primaryColor,
    secondaryColor,
    pageNumbering,
    pageNumberingAlignment,
    hidePaidToDate,
    hideEmptyColumnsOnPdf,
    embedDocuments,
    allPagesHeader,
    allPagesFooter,
    const DeepCollectionEquality().hash(_pdfVariables),
    showPdfhtmlOnMobile,
    enableClientPortal,
    enableClientPortalDashboard,
    enableClientPortalTasks,
    showAllTasksClientPortal,
    enableClientPortalPassword,
    clientPortalTerms,
    clientPortalPrivacyPolicy,
    clientPortalEnableUploads,
    clientPortalAllowUnderPayment,
    clientPortalUnderPaymentMinimum,
    clientPortalAllowOverPayment,
    portalCustomHead,
    portalCustomCss,
    portalCustomFooter,
    portalCustomJs,
    clientCanRegister,
    clientInitiatedPayments,
    clientInitiatedPaymentsMinimum,
    enableClientProfileUpdate,
    clientOnlinePaymentNotification,
    clientManualPaymentNotification,
    vendorPortalEnableUploads,
    useCreditsPayment,
    useUnappliedPayment,
    paymentTerms,
    validUntil,
    paymentTypeId,
    defaultExpensePaymentTypeId,
    companyGatewayIds,
    paymentFlow,
    unlockInvoiceDocumentsAfterPayment,
    showTaskItemDescription,
    allowBillableTaskItems,
    defaultTaskRate,
    taskRoundUp,
    taskRoundToNearest,
    enableEInvoice,
    eInvoiceType,
    eQuoteType,
    mergeEInvoiceToPdf,
    skipAutomaticEmailWithPeppol,
    eInvoiceForwardEmail,
    eExpenseForwardEmail,
    preferenceProductNotesForHtmlView,
    customMessageDashboard,
    customMessageUnpaidInvoice,
    customMessagePaidInvoice,
    customMessageUnapprovedQuote,
    const DeepCollectionEquality().hash(_translations),
  ]);

  /// Create a copy of CompanySettingsApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanySettingsApiImplCopyWith<_$CompanySettingsApiImpl> get copyWith =>
      __$$CompanySettingsApiImplCopyWithImpl<_$CompanySettingsApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanySettingsApiImplToJson(this);
  }
}

abstract class _CompanySettingsApi implements CompanySettingsApi {
  const factory _CompanySettingsApi({
    final String? id,
    final String? name,
    @JsonKey(name: 'company_logo') final String? companyLogo,
    @JsonKey(name: 'company_logo_size') final String? companyLogoSize,
    final String? website,
    final String? phone,
    final String? email,
    final String? address1,
    final String? address2,
    final String? city,
    final String? state,
    @JsonKey(name: 'postal_code') final String? postalCode,
    @JsonKey(name: 'country_id') final String? countryId,
    @JsonKey(name: 'vat_number') final String? vatNumber,
    @JsonKey(name: 'id_number') final String? idNumber,
    final String? classification,
    @JsonKey(name: 'qr_iban') final String? qrIban,
    @JsonKey(name: 'besr_id') final String? besrId,
    @JsonKey(name: 'custom_value1') final String? customValue1,
    @JsonKey(name: 'custom_value2') final String? customValue2,
    @JsonKey(name: 'custom_value3') final String? customValue3,
    @JsonKey(name: 'custom_value4') final String? customValue4,
    @JsonKey(name: 'timezone_id') final String? timezoneId,
    @JsonKey(name: 'date_format_id') final String? dateFormatId,
    @JsonKey(name: 'language_id') final String? languageId,
    @JsonKey(name: 'currency_id') final String? currencyId,
    @JsonKey(name: 'military_time') final bool? militaryTime,
    @JsonKey(name: 'show_currency_code') final bool? showCurrencyCode,
    @JsonKey(name: 'use_comma_as_decimal_place')
    final bool? useCommaAsDecimalPlace,
    @JsonKey(name: 'first_month_of_year') final String? firstMonthOfYear,
    @JsonKey(name: 'invoice_terms') final String? invoiceTerms,
    @JsonKey(name: 'invoice_footer') final String? invoiceFooter,
    @JsonKey(name: 'quote_terms') final String? quoteTerms,
    @JsonKey(name: 'quote_footer') final String? quoteFooter,
    @JsonKey(name: 'credit_terms') final String? creditTerms,
    @JsonKey(name: 'credit_footer') final String? creditFooter,
    @JsonKey(name: 'purchase_order_terms') final String? purchaseOrderTerms,
    @JsonKey(name: 'purchase_order_footer') final String? purchaseOrderFooter,
    @JsonKey(name: 'purchase_order_public_notes')
    final String? purchaseOrderPublicNotes,
    @JsonKey(name: 'invoice_labels') final String? invoiceLabels,
    @JsonKey(name: 'invoice_design_id') final String? invoiceDesignId,
    @JsonKey(name: 'quote_design_id') final String? quoteDesignId,
    @JsonKey(name: 'credit_design_id') final String? creditDesignId,
    @JsonKey(name: 'purchase_order_design_id')
    final String? purchaseOrderDesignId,
    @JsonKey(name: 'statement_design_id') final String? statementDesignId,
    @JsonKey(name: 'delivery_note_design_id')
    final String? deliveryNoteDesignId,
    @JsonKey(name: 'payment_receipt_design_id')
    final String? paymentReceiptDesignId,
    @JsonKey(name: 'payment_refund_design_id')
    final String? paymentRefundDesignId,
    @JsonKey(name: 'portal_design_id') final String? portalDesignId,
    @JsonKey(name: 'invoice_number_pattern') final String? invoiceNumberPattern,
    @JsonKey(name: 'invoice_number_counter') final int? invoiceNumberCounter,
    @JsonKey(name: 'recurring_invoice_number_pattern')
    final String? recurringInvoiceNumberPattern,
    @JsonKey(name: 'recurring_invoice_number_counter')
    final int? recurringInvoiceNumberCounter,
    @JsonKey(name: 'quote_number_pattern') final String? quoteNumberPattern,
    @JsonKey(name: 'quote_number_counter') final int? quoteNumberCounter,
    @JsonKey(name: 'recurring_quote_number_pattern')
    final String? recurringQuoteNumberPattern,
    @JsonKey(name: 'recurring_quote_number_counter')
    final int? recurringQuoteNumberCounter,
    @JsonKey(name: 'client_number_pattern') final String? clientNumberPattern,
    @JsonKey(name: 'client_number_counter') final int? clientNumberCounter,
    @JsonKey(name: 'credit_number_pattern') final String? creditNumberPattern,
    @JsonKey(name: 'credit_number_counter') final int? creditNumberCounter,
    @JsonKey(name: 'task_number_pattern') final String? taskNumberPattern,
    @JsonKey(name: 'task_number_counter') final int? taskNumberCounter,
    @JsonKey(name: 'expense_number_pattern') final String? expenseNumberPattern,
    @JsonKey(name: 'expense_number_counter') final int? expenseNumberCounter,
    @JsonKey(name: 'recurring_expense_number_pattern')
    final String? recurringExpenseNumberPattern,
    @JsonKey(name: 'recurring_expense_number_counter')
    final int? recurringExpenseNumberCounter,
    @JsonKey(name: 'vendor_number_pattern') final String? vendorNumberPattern,
    @JsonKey(name: 'vendor_number_counter') final int? vendorNumberCounter,
    @JsonKey(name: 'ticket_number_pattern') final String? ticketNumberPattern,
    @JsonKey(name: 'ticket_number_counter') final int? ticketNumberCounter,
    @JsonKey(name: 'payment_number_pattern') final String? paymentNumberPattern,
    @JsonKey(name: 'payment_number_counter') final int? paymentNumberCounter,
    @JsonKey(name: 'project_number_pattern') final String? projectNumberPattern,
    @JsonKey(name: 'project_number_counter') final int? projectNumberCounter,
    @JsonKey(name: 'purchase_order_number_pattern')
    final String? purchaseOrderNumberPattern,
    @JsonKey(name: 'purchase_order_number_counter')
    final int? purchaseOrderNumberCounter,
    @JsonKey(name: 'shared_invoice_quote_counter')
    final bool? sharedInvoiceQuoteCounter,
    @JsonKey(name: 'shared_invoice_credit_counter')
    final bool? sharedInvoiceCreditCounter,
    @JsonKey(name: 'recurring_number_prefix')
    final String? recurringNumberPrefix,
    @JsonKey(name: 'reset_counter_frequency_id')
    final int? resetCounterFrequencyId,
    @JsonKey(name: 'reset_counter_date') final String? resetCounterDate,
    @JsonKey(name: 'counter_padding') final int? counterPadding,
    @JsonKey(name: 'counter_number_applied') final String? counterNumberApplied,
    @JsonKey(name: 'quote_number_applied') final String? quoteNumberApplied,
    @JsonKey(name: 'tax_name1') final String? taxName1,
    @JsonKey(name: 'tax_rate1') final double? taxRate1,
    @JsonKey(name: 'tax_name2') final String? taxName2,
    @JsonKey(name: 'tax_rate2') final double? taxRate2,
    @JsonKey(name: 'tax_name3') final String? taxName3,
    @JsonKey(name: 'tax_rate3') final double? taxRate3,
    @JsonKey(name: 'invoice_taxes') final int? invoiceTaxes,
    @JsonKey(name: 'inclusive_taxes') final bool? inclusiveTaxes,
    @JsonKey(name: 'enable_rappen_rounding') final bool? enableRappenRounding,
    @JsonKey(name: 'email_sending_method') final String? emailSendingMethod,
    @JsonKey(name: 'gmail_sending_user_id') final String? gmailSendingUserId,
    @JsonKey(name: 'reply_to_email') final String? replyToEmail,
    @JsonKey(name: 'reply_to_name') final String? replyToName,
    @JsonKey(name: 'bcc_email') final String? bccEmail,
    @JsonKey(name: 'email_from_name') final String? emailFromName,
    @JsonKey(name: 'custom_sending_email') final String? customSendingEmail,
    @JsonKey(name: 'email_style') final String? emailStyle,
    @JsonKey(name: 'email_style_custom') final String? emailStyleCustom,
    @JsonKey(name: 'email_signature') final String? emailSignature,
    @JsonKey(name: 'enable_email_markup') final bool? enableEmailMarkup,
    @JsonKey(name: 'show_email_footer') final bool? showEmailFooter,
    @JsonKey(name: 'pdf_email_attachment') final bool? pdfEmailAttachment,
    @JsonKey(name: 'ubl_email_attachment') final bool? ublEmailAttachment,
    @JsonKey(name: 'document_email_attachment')
    final bool? documentEmailAttachment,
    @JsonKey(name: 'send_email_on_mark_paid') final bool? sendEmailOnMarkPaid,
    @JsonKey(name: 'payment_email_all_contacts')
    final bool? paymentEmailAllContacts,
    @JsonKey(name: 'postmark_secret') final String? postmarkSecret,
    @JsonKey(name: 'mailgun_secret') final String? mailgunSecret,
    @JsonKey(name: 'mailgun_domain') final String? mailgunDomain,
    @JsonKey(name: 'mailgun_endpoint') final String? mailgunEndpoint,
    @JsonKey(name: 'brevo_secret') final String? brevoSecret,
    @JsonKey(name: 'ses_secret_key') final String? sesSecretKey,
    @JsonKey(name: 'ses_access_key') final String? sesAccessKey,
    @JsonKey(name: 'ses_region') final String? sesRegion,
    @JsonKey(name: 'ses_topic_arn') final String? sesTopicArn,
    @JsonKey(name: 'ses_from_address') final String? sesFromAddress,
    @JsonKey(name: 'email_subject_invoice') final String? emailSubjectInvoice,
    @JsonKey(name: 'email_subject_quote') final String? emailSubjectQuote,
    @JsonKey(name: 'email_subject_credit') final String? emailSubjectCredit,
    @JsonKey(name: 'email_subject_payment') final String? emailSubjectPayment,
    @JsonKey(name: 'email_subject_payment_partial')
    final String? emailSubjectPaymentPartial,
    @JsonKey(name: 'email_subject_statement')
    final String? emailSubjectStatement,
    @JsonKey(name: 'email_subject_purchase_order')
    final String? emailSubjectPurchaseOrder,
    @JsonKey(name: 'email_subject_reminder1')
    final String? emailSubjectReminder1,
    @JsonKey(name: 'email_subject_reminder2')
    final String? emailSubjectReminder2,
    @JsonKey(name: 'email_subject_reminder3')
    final String? emailSubjectReminder3,
    @JsonKey(name: 'email_subject_reminder_endless')
    final String? emailSubjectReminderEndless,
    @JsonKey(name: 'email_subject_custom1') final String? emailSubjectCustom1,
    @JsonKey(name: 'email_subject_custom2') final String? emailSubjectCustom2,
    @JsonKey(name: 'email_subject_custom3') final String? emailSubjectCustom3,
    @JsonKey(name: 'email_template_invoice') final String? emailTemplateInvoice,
    @JsonKey(name: 'email_template_quote') final String? emailTemplateQuote,
    @JsonKey(name: 'email_template_credit') final String? emailTemplateCredit,
    @JsonKey(name: 'email_template_payment') final String? emailTemplatePayment,
    @JsonKey(name: 'email_template_payment_partial')
    final String? emailTemplatePaymentPartial,
    @JsonKey(name: 'email_template_statement')
    final String? emailTemplateStatement,
    @JsonKey(name: 'email_template_purchase_order')
    final String? emailTemplatePurchaseOrder,
    @JsonKey(name: 'email_template_reminder1')
    final String? emailTemplateReminder1,
    @JsonKey(name: 'email_template_reminder2')
    final String? emailTemplateReminder2,
    @JsonKey(name: 'email_template_reminder3')
    final String? emailTemplateReminder3,
    @JsonKey(name: 'email_template_reminder_endless')
    final String? emailTemplateReminderEndless,
    @JsonKey(name: 'email_template_custom1') final String? emailTemplateCustom1,
    @JsonKey(name: 'email_template_custom2') final String? emailTemplateCustom2,
    @JsonKey(name: 'email_template_custom3') final String? emailTemplateCustom3,
    @JsonKey(name: 'send_reminders') final bool? sendReminders,
    @JsonKey(name: 'enable_reminder1') final bool? enableReminder1,
    @JsonKey(name: 'enable_reminder2') final bool? enableReminder2,
    @JsonKey(name: 'enable_reminder3') final bool? enableReminder3,
    @JsonKey(name: 'enable_reminder_endless') final bool? enableReminderEndless,
    @JsonKey(name: 'num_days_reminder1') final int? numDaysReminder1,
    @JsonKey(name: 'num_days_reminder2') final int? numDaysReminder2,
    @JsonKey(name: 'num_days_reminder3') final int? numDaysReminder3,
    @JsonKey(name: 'schedule_reminder1') final String? scheduleReminder1,
    @JsonKey(name: 'schedule_reminder2') final String? scheduleReminder2,
    @JsonKey(name: 'schedule_reminder3') final String? scheduleReminder3,
    @JsonKey(name: 'reminder_send_time') final int? reminderSendTime,
    @JsonKey(name: 'late_fee_amount1') final double? lateFeeAmount1,
    @JsonKey(name: 'late_fee_amount2') final double? lateFeeAmount2,
    @JsonKey(name: 'late_fee_amount3') final double? lateFeeAmount3,
    @JsonKey(name: 'late_fee_percent1') final double? lateFeePercent1,
    @JsonKey(name: 'late_fee_percent2') final double? lateFeePercent2,
    @JsonKey(name: 'late_fee_percent3') final double? lateFeePercent3,
    @JsonKey(name: 'endless_reminder_frequency_id')
    final String? endlessReminderFrequencyId,
    @JsonKey(name: 'late_fee_endless_amount')
    final double? lateFeeEndlessAmount,
    @JsonKey(name: 'late_fee_endless_percent')
    final double? lateFeeEndlessPercent,
    @JsonKey(name: 'auto_archive_invoice') final bool? autoArchiveInvoice,
    @JsonKey(name: 'auto_archive_invoice_cancelled')
    final bool? autoArchiveInvoiceCancelled,
    @JsonKey(name: 'auto_archive_quote') final bool? autoArchiveQuote,
    @JsonKey(name: 'auto_convert_quote') final bool? autoConvertQuote,
    @JsonKey(name: 'auto_email_invoice') final bool? autoEmailInvoice,
    @JsonKey(name: 'auto_bill_standard_invoices')
    final bool? autoBillStandardInvoices,
    @JsonKey(name: 'auto_bill') final String? autoBill,
    @JsonKey(name: 'auto_bill_date') final String? autoBillDate,
    @JsonKey(name: 'lock_invoices') final String? lockInvoices,
    @JsonKey(name: 'entity_send_time') final int? entitySendTime,
    @JsonKey(name: 'show_accept_invoice_terms')
    final bool? showAcceptInvoiceTerms,
    @JsonKey(name: 'show_accept_quote_terms') final bool? showAcceptQuoteTerms,
    @JsonKey(name: 'require_invoice_signature')
    final bool? requireInvoiceSignature,
    @JsonKey(name: 'require_quote_signature') final bool? requireQuoteSignature,
    @JsonKey(name: 'require_purchase_order_signature')
    final bool? requirePurchaseOrderSignature,
    @JsonKey(name: 'signature_on_pdf') final bool? signatureOnPdf,
    @JsonKey(name: 'accept_client_input_quote_approval')
    final bool? acceptClientInputQuoteApproval,
    @JsonKey(name: 'sync_invoice_quote_columns')
    final bool? syncInvoiceQuoteColumns,
    @JsonKey(name: 'show_shipping_address') final bool? showShippingAddress,
    @JsonKey(name: 'show_paid_stamp') final bool? showPaidStamp,
    @JsonKey(name: 'page_size') final String? pageSize,
    @JsonKey(name: 'page_layout') final String? pageLayout,
    @JsonKey(name: 'font_size') final int? fontSize,
    @JsonKey(name: 'primary_font') final String? primaryFont,
    @JsonKey(name: 'secondary_font') final String? secondaryFont,
    @JsonKey(name: 'primary_color') final String? primaryColor,
    @JsonKey(name: 'secondary_color') final String? secondaryColor,
    @JsonKey(name: 'page_numbering') final bool? pageNumbering,
    @JsonKey(name: 'page_numbering_alignment')
    final String? pageNumberingAlignment,
    @JsonKey(name: 'hide_paid_to_date') final bool? hidePaidToDate,
    @JsonKey(name: 'hide_empty_columns_on_pdf')
    final bool? hideEmptyColumnsOnPdf,
    @JsonKey(name: 'embed_documents') final bool? embedDocuments,
    @JsonKey(name: 'all_pages_header') final bool? allPagesHeader,
    @JsonKey(name: 'all_pages_footer') final bool? allPagesFooter,
    @JsonKey(name: 'pdf_variables')
    final Map<String, List<String>>? pdfVariables,
    @JsonKey(name: 'show_pdfhtml_on_mobile') final bool? showPdfhtmlOnMobile,
    @JsonKey(name: 'enable_client_portal') final bool? enableClientPortal,
    @JsonKey(name: 'enable_client_portal_dashboard')
    final bool? enableClientPortalDashboard,
    @JsonKey(name: 'enable_client_portal_tasks')
    final bool? enableClientPortalTasks,
    @JsonKey(name: 'show_all_tasks_client_portal')
    final String? showAllTasksClientPortal,
    @JsonKey(name: 'enable_client_portal_password')
    final bool? enableClientPortalPassword,
    @JsonKey(name: 'client_portal_terms') final String? clientPortalTerms,
    @JsonKey(name: 'client_portal_privacy_policy')
    final String? clientPortalPrivacyPolicy,
    @JsonKey(name: 'client_portal_enable_uploads')
    final bool? clientPortalEnableUploads,
    @JsonKey(name: 'client_portal_allow_under_payment')
    final bool? clientPortalAllowUnderPayment,
    @JsonKey(name: 'client_portal_under_payment_minimum')
    final double? clientPortalUnderPaymentMinimum,
    @JsonKey(name: 'client_portal_allow_over_payment')
    final bool? clientPortalAllowOverPayment,
    @JsonKey(name: 'portal_custom_head') final String? portalCustomHead,
    @JsonKey(name: 'portal_custom_css') final String? portalCustomCss,
    @JsonKey(name: 'portal_custom_footer') final String? portalCustomFooter,
    @JsonKey(name: 'portal_custom_js') final String? portalCustomJs,
    @JsonKey(name: 'client_can_register') final bool? clientCanRegister,
    @JsonKey(name: 'client_initiated_payments')
    final bool? clientInitiatedPayments,
    @JsonKey(name: 'client_initiated_payments_minimum')
    final double? clientInitiatedPaymentsMinimum,
    @JsonKey(name: 'enable_client_profile_update')
    final bool? enableClientProfileUpdate,
    @JsonKey(name: 'client_online_payment_notification')
    final bool? clientOnlinePaymentNotification,
    @JsonKey(name: 'client_manual_payment_notification')
    final bool? clientManualPaymentNotification,
    @JsonKey(name: 'vendor_portal_enable_uploads')
    final bool? vendorPortalEnableUploads,
    @JsonKey(name: 'use_credits_payment') final String? useCreditsPayment,
    @JsonKey(name: 'use_unapplied_payment') final String? useUnappliedPayment,
    @JsonKey(name: 'payment_terms') final String? paymentTerms,
    @JsonKey(name: 'valid_until') final String? validUntil,
    @JsonKey(name: 'payment_type_id') final String? paymentTypeId,
    @JsonKey(name: 'default_expense_payment_type_id')
    final String? defaultExpensePaymentTypeId,
    @JsonKey(name: 'company_gateway_ids') final String? companyGatewayIds,
    @JsonKey(name: 'payment_flow') final String? paymentFlow,
    @JsonKey(name: 'unlock_invoice_documents_after_payment')
    final bool? unlockInvoiceDocumentsAfterPayment,
    @JsonKey(name: 'show_task_item_description')
    final bool? showTaskItemDescription,
    @JsonKey(name: 'allow_billable_task_items')
    final bool? allowBillableTaskItems,
    @JsonKey(name: 'default_task_rate') final double? defaultTaskRate,
    @JsonKey(name: 'task_round_up') final bool? taskRoundUp,
    @JsonKey(name: 'task_round_to_nearest') final double? taskRoundToNearest,
    @JsonKey(name: 'enable_e_invoice') final bool? enableEInvoice,
    @JsonKey(name: 'e_invoice_type') final String? eInvoiceType,
    @JsonKey(name: 'e_quote_type') final String? eQuoteType,
    @JsonKey(name: 'merge_e_invoice_to_pdf') final bool? mergeEInvoiceToPdf,
    @JsonKey(name: 'skip_automatic_email_with_peppol')
    final bool? skipAutomaticEmailWithPeppol,
    @JsonKey(name: 'e_invoice_forward_email')
    final String? eInvoiceForwardEmail,
    @JsonKey(name: 'e_expense_forward_email')
    final String? eExpenseForwardEmail,
    @JsonKey(name: 'preference_product_notes_for_html_view')
    final bool? preferenceProductNotesForHtmlView,
    @JsonKey(name: 'custom_message_dashboard')
    final String? customMessageDashboard,
    @JsonKey(name: 'custom_message_unpaid_invoice')
    final String? customMessageUnpaidInvoice,
    @JsonKey(name: 'custom_message_paid_invoice')
    final String? customMessagePaidInvoice,
    @JsonKey(name: 'custom_message_unapproved_quote')
    final String? customMessageUnapprovedQuote,
    final List<dynamic>? translations,
  }) = _$CompanySettingsApiImpl;

  factory _CompanySettingsApi.fromJson(Map<String, dynamic> json) =
      _$CompanySettingsApiImpl.fromJson;

  // ── Identity / brand ────────────────────────────────────────────────
  @override
  String? get id;
  @override
  String? get name;
  @override
  @JsonKey(name: 'company_logo')
  String? get companyLogo;
  @override
  @JsonKey(name: 'company_logo_size')
  String? get companyLogoSize;
  @override
  String? get website;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get address1;
  @override
  String? get address2;
  @override
  String? get city;
  @override
  String? get state;
  @override
  @JsonKey(name: 'postal_code')
  String? get postalCode;
  @override
  @JsonKey(name: 'country_id')
  String? get countryId;
  @override
  @JsonKey(name: 'vat_number')
  String? get vatNumber;
  @override
  @JsonKey(name: 'id_number')
  String? get idNumber;
  @override
  String? get classification;
  @override
  @JsonKey(name: 'qr_iban')
  String? get qrIban;
  @override
  @JsonKey(name: 'besr_id')
  String? get besrId;
  @override
  @JsonKey(name: 'custom_value1')
  String? get customValue1;
  @override
  @JsonKey(name: 'custom_value2')
  String? get customValue2;
  @override
  @JsonKey(name: 'custom_value3')
  String? get customValue3;
  @override
  @JsonKey(name: 'custom_value4')
  String? get customValue4; // ── Localization ────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'timezone_id')
  String? get timezoneId;
  @override
  @JsonKey(name: 'date_format_id')
  String? get dateFormatId;
  @override
  @JsonKey(name: 'language_id')
  String? get languageId;
  @override
  @JsonKey(name: 'currency_id')
  String? get currencyId;
  @override
  @JsonKey(name: 'military_time')
  bool? get militaryTime;
  @override
  @JsonKey(name: 'show_currency_code')
  bool? get showCurrencyCode;
  @override
  @JsonKey(name: 'use_comma_as_decimal_place')
  bool? get useCommaAsDecimalPlace;
  @override
  @JsonKey(name: 'first_month_of_year')
  String? get firstMonthOfYear; // ── Defaults: terms & footers ───────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_terms')
  String? get invoiceTerms;
  @override
  @JsonKey(name: 'invoice_footer')
  String? get invoiceFooter;
  @override
  @JsonKey(name: 'quote_terms')
  String? get quoteTerms;
  @override
  @JsonKey(name: 'quote_footer')
  String? get quoteFooter;
  @override
  @JsonKey(name: 'credit_terms')
  String? get creditTerms;
  @override
  @JsonKey(name: 'credit_footer')
  String? get creditFooter;
  @override
  @JsonKey(name: 'purchase_order_terms')
  String? get purchaseOrderTerms;
  @override
  @JsonKey(name: 'purchase_order_footer')
  String? get purchaseOrderFooter;
  @override
  @JsonKey(name: 'purchase_order_public_notes')
  String? get purchaseOrderPublicNotes;
  @override
  @JsonKey(name: 'invoice_labels')
  String? get invoiceLabels; // ── Design ids ──────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_design_id')
  String? get invoiceDesignId;
  @override
  @JsonKey(name: 'quote_design_id')
  String? get quoteDesignId;
  @override
  @JsonKey(name: 'credit_design_id')
  String? get creditDesignId;
  @override
  @JsonKey(name: 'purchase_order_design_id')
  String? get purchaseOrderDesignId;
  @override
  @JsonKey(name: 'statement_design_id')
  String? get statementDesignId;
  @override
  @JsonKey(name: 'delivery_note_design_id')
  String? get deliveryNoteDesignId;
  @override
  @JsonKey(name: 'payment_receipt_design_id')
  String? get paymentReceiptDesignId;
  @override
  @JsonKey(name: 'payment_refund_design_id')
  String? get paymentRefundDesignId;
  @override
  @JsonKey(name: 'portal_design_id')
  String? get portalDesignId; // ── Numbering & counters ────────────────────────────────────────────
  @override
  @JsonKey(name: 'invoice_number_pattern')
  String? get invoiceNumberPattern;
  @override
  @JsonKey(name: 'invoice_number_counter')
  int? get invoiceNumberCounter;
  @override
  @JsonKey(name: 'recurring_invoice_number_pattern')
  String? get recurringInvoiceNumberPattern;
  @override
  @JsonKey(name: 'recurring_invoice_number_counter')
  int? get recurringInvoiceNumberCounter;
  @override
  @JsonKey(name: 'quote_number_pattern')
  String? get quoteNumberPattern;
  @override
  @JsonKey(name: 'quote_number_counter')
  int? get quoteNumberCounter;
  @override
  @JsonKey(name: 'recurring_quote_number_pattern')
  String? get recurringQuoteNumberPattern;
  @override
  @JsonKey(name: 'recurring_quote_number_counter')
  int? get recurringQuoteNumberCounter;
  @override
  @JsonKey(name: 'client_number_pattern')
  String? get clientNumberPattern;
  @override
  @JsonKey(name: 'client_number_counter')
  int? get clientNumberCounter;
  @override
  @JsonKey(name: 'credit_number_pattern')
  String? get creditNumberPattern;
  @override
  @JsonKey(name: 'credit_number_counter')
  int? get creditNumberCounter;
  @override
  @JsonKey(name: 'task_number_pattern')
  String? get taskNumberPattern;
  @override
  @JsonKey(name: 'task_number_counter')
  int? get taskNumberCounter;
  @override
  @JsonKey(name: 'expense_number_pattern')
  String? get expenseNumberPattern;
  @override
  @JsonKey(name: 'expense_number_counter')
  int? get expenseNumberCounter;
  @override
  @JsonKey(name: 'recurring_expense_number_pattern')
  String? get recurringExpenseNumberPattern;
  @override
  @JsonKey(name: 'recurring_expense_number_counter')
  int? get recurringExpenseNumberCounter;
  @override
  @JsonKey(name: 'vendor_number_pattern')
  String? get vendorNumberPattern;
  @override
  @JsonKey(name: 'vendor_number_counter')
  int? get vendorNumberCounter;
  @override
  @JsonKey(name: 'ticket_number_pattern')
  String? get ticketNumberPattern;
  @override
  @JsonKey(name: 'ticket_number_counter')
  int? get ticketNumberCounter;
  @override
  @JsonKey(name: 'payment_number_pattern')
  String? get paymentNumberPattern;
  @override
  @JsonKey(name: 'payment_number_counter')
  int? get paymentNumberCounter;
  @override
  @JsonKey(name: 'project_number_pattern')
  String? get projectNumberPattern;
  @override
  @JsonKey(name: 'project_number_counter')
  int? get projectNumberCounter;
  @override
  @JsonKey(name: 'purchase_order_number_pattern')
  String? get purchaseOrderNumberPattern;
  @override
  @JsonKey(name: 'purchase_order_number_counter')
  int? get purchaseOrderNumberCounter;
  @override
  @JsonKey(name: 'shared_invoice_quote_counter')
  bool? get sharedInvoiceQuoteCounter;
  @override
  @JsonKey(name: 'shared_invoice_credit_counter')
  bool? get sharedInvoiceCreditCounter;
  @override
  @JsonKey(name: 'recurring_number_prefix')
  String? get recurringNumberPrefix;
  @override
  @JsonKey(name: 'reset_counter_frequency_id')
  int? get resetCounterFrequencyId;
  @override
  @JsonKey(name: 'reset_counter_date')
  String? get resetCounterDate;
  @override
  @JsonKey(name: 'counter_padding')
  int? get counterPadding;
  @override
  @JsonKey(name: 'counter_number_applied')
  String? get counterNumberApplied;
  @override
  @JsonKey(name: 'quote_number_applied')
  String? get quoteNumberApplied; // ── Taxes ───────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'tax_name1')
  String? get taxName1;
  @override
  @JsonKey(name: 'tax_rate1')
  double? get taxRate1;
  @override
  @JsonKey(name: 'tax_name2')
  String? get taxName2;
  @override
  @JsonKey(name: 'tax_rate2')
  double? get taxRate2;
  @override
  @JsonKey(name: 'tax_name3')
  String? get taxName3;
  @override
  @JsonKey(name: 'tax_rate3')
  double? get taxRate3;
  @override
  @JsonKey(name: 'invoice_taxes')
  int? get invoiceTaxes;
  @override
  @JsonKey(name: 'inclusive_taxes')
  bool? get inclusiveTaxes;
  @override
  @JsonKey(name: 'enable_rappen_rounding')
  bool? get enableRappenRounding; // ── Email config ────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'email_sending_method')
  String? get emailSendingMethod;
  @override
  @JsonKey(name: 'gmail_sending_user_id')
  String? get gmailSendingUserId;
  @override
  @JsonKey(name: 'reply_to_email')
  String? get replyToEmail;
  @override
  @JsonKey(name: 'reply_to_name')
  String? get replyToName;
  @override
  @JsonKey(name: 'bcc_email')
  String? get bccEmail;
  @override
  @JsonKey(name: 'email_from_name')
  String? get emailFromName;
  @override
  @JsonKey(name: 'custom_sending_email')
  String? get customSendingEmail;
  @override
  @JsonKey(name: 'email_style')
  String? get emailStyle;
  @override
  @JsonKey(name: 'email_style_custom')
  String? get emailStyleCustom;
  @override
  @JsonKey(name: 'email_signature')
  String? get emailSignature;
  @override
  @JsonKey(name: 'enable_email_markup')
  bool? get enableEmailMarkup;
  @override
  @JsonKey(name: 'show_email_footer')
  bool? get showEmailFooter;
  @override
  @JsonKey(name: 'pdf_email_attachment')
  bool? get pdfEmailAttachment;
  @override
  @JsonKey(name: 'ubl_email_attachment')
  bool? get ublEmailAttachment;
  @override
  @JsonKey(name: 'document_email_attachment')
  bool? get documentEmailAttachment;
  @override
  @JsonKey(name: 'send_email_on_mark_paid')
  bool? get sendEmailOnMarkPaid;
  @override
  @JsonKey(name: 'payment_email_all_contacts')
  bool? get paymentEmailAllContacts; // Mail service secrets
  @override
  @JsonKey(name: 'postmark_secret')
  String? get postmarkSecret;
  @override
  @JsonKey(name: 'mailgun_secret')
  String? get mailgunSecret;
  @override
  @JsonKey(name: 'mailgun_domain')
  String? get mailgunDomain;
  @override
  @JsonKey(name: 'mailgun_endpoint')
  String? get mailgunEndpoint;
  @override
  @JsonKey(name: 'brevo_secret')
  String? get brevoSecret;
  @override
  @JsonKey(name: 'ses_secret_key')
  String? get sesSecretKey;
  @override
  @JsonKey(name: 'ses_access_key')
  String? get sesAccessKey;
  @override
  @JsonKey(name: 'ses_region')
  String? get sesRegion;
  @override
  @JsonKey(name: 'ses_topic_arn')
  String? get sesTopicArn;
  @override
  @JsonKey(name: 'ses_from_address')
  String? get sesFromAddress; // Email subjects (per entity)
  @override
  @JsonKey(name: 'email_subject_invoice')
  String? get emailSubjectInvoice;
  @override
  @JsonKey(name: 'email_subject_quote')
  String? get emailSubjectQuote;
  @override
  @JsonKey(name: 'email_subject_credit')
  String? get emailSubjectCredit;
  @override
  @JsonKey(name: 'email_subject_payment')
  String? get emailSubjectPayment;
  @override
  @JsonKey(name: 'email_subject_payment_partial')
  String? get emailSubjectPaymentPartial;
  @override
  @JsonKey(name: 'email_subject_statement')
  String? get emailSubjectStatement;
  @override
  @JsonKey(name: 'email_subject_purchase_order')
  String? get emailSubjectPurchaseOrder;
  @override
  @JsonKey(name: 'email_subject_reminder1')
  String? get emailSubjectReminder1;
  @override
  @JsonKey(name: 'email_subject_reminder2')
  String? get emailSubjectReminder2;
  @override
  @JsonKey(name: 'email_subject_reminder3')
  String? get emailSubjectReminder3;
  @override
  @JsonKey(name: 'email_subject_reminder_endless')
  String? get emailSubjectReminderEndless;
  @override
  @JsonKey(name: 'email_subject_custom1')
  String? get emailSubjectCustom1;
  @override
  @JsonKey(name: 'email_subject_custom2')
  String? get emailSubjectCustom2;
  @override
  @JsonKey(name: 'email_subject_custom3')
  String? get emailSubjectCustom3; // Email templates (per entity)
  @override
  @JsonKey(name: 'email_template_invoice')
  String? get emailTemplateInvoice;
  @override
  @JsonKey(name: 'email_template_quote')
  String? get emailTemplateQuote;
  @override
  @JsonKey(name: 'email_template_credit')
  String? get emailTemplateCredit;
  @override
  @JsonKey(name: 'email_template_payment')
  String? get emailTemplatePayment;
  @override
  @JsonKey(name: 'email_template_payment_partial')
  String? get emailTemplatePaymentPartial;
  @override
  @JsonKey(name: 'email_template_statement')
  String? get emailTemplateStatement;
  @override
  @JsonKey(name: 'email_template_purchase_order')
  String? get emailTemplatePurchaseOrder;
  @override
  @JsonKey(name: 'email_template_reminder1')
  String? get emailTemplateReminder1;
  @override
  @JsonKey(name: 'email_template_reminder2')
  String? get emailTemplateReminder2;
  @override
  @JsonKey(name: 'email_template_reminder3')
  String? get emailTemplateReminder3;
  @override
  @JsonKey(name: 'email_template_reminder_endless')
  String? get emailTemplateReminderEndless;
  @override
  @JsonKey(name: 'email_template_custom1')
  String? get emailTemplateCustom1;
  @override
  @JsonKey(name: 'email_template_custom2')
  String? get emailTemplateCustom2;
  @override
  @JsonKey(name: 'email_template_custom3')
  String? get emailTemplateCustom3; // ── Reminders ───────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'send_reminders')
  bool? get sendReminders;
  @override
  @JsonKey(name: 'enable_reminder1')
  bool? get enableReminder1;
  @override
  @JsonKey(name: 'enable_reminder2')
  bool? get enableReminder2;
  @override
  @JsonKey(name: 'enable_reminder3')
  bool? get enableReminder3;
  @override
  @JsonKey(name: 'enable_reminder_endless')
  bool? get enableReminderEndless;
  @override
  @JsonKey(name: 'num_days_reminder1')
  int? get numDaysReminder1;
  @override
  @JsonKey(name: 'num_days_reminder2')
  int? get numDaysReminder2;
  @override
  @JsonKey(name: 'num_days_reminder3')
  int? get numDaysReminder3;
  @override
  @JsonKey(name: 'schedule_reminder1')
  String? get scheduleReminder1;
  @override
  @JsonKey(name: 'schedule_reminder2')
  String? get scheduleReminder2;
  @override
  @JsonKey(name: 'schedule_reminder3')
  String? get scheduleReminder3;
  @override
  @JsonKey(name: 'reminder_send_time')
  int? get reminderSendTime;
  @override
  @JsonKey(name: 'late_fee_amount1')
  double? get lateFeeAmount1;
  @override
  @JsonKey(name: 'late_fee_amount2')
  double? get lateFeeAmount2;
  @override
  @JsonKey(name: 'late_fee_amount3')
  double? get lateFeeAmount3;
  @override
  @JsonKey(name: 'late_fee_percent1')
  double? get lateFeePercent1;
  @override
  @JsonKey(name: 'late_fee_percent2')
  double? get lateFeePercent2;
  @override
  @JsonKey(name: 'late_fee_percent3')
  double? get lateFeePercent3;
  @override
  @JsonKey(name: 'endless_reminder_frequency_id')
  String? get endlessReminderFrequencyId;
  @override
  @JsonKey(name: 'late_fee_endless_amount')
  double? get lateFeeEndlessAmount;
  @override
  @JsonKey(name: 'late_fee_endless_percent')
  double? get lateFeeEndlessPercent; // ── Invoice / quote behavior ───────────────────────────────────────
  @override
  @JsonKey(name: 'auto_archive_invoice')
  bool? get autoArchiveInvoice;
  @override
  @JsonKey(name: 'auto_archive_invoice_cancelled')
  bool? get autoArchiveInvoiceCancelled;
  @override
  @JsonKey(name: 'auto_archive_quote')
  bool? get autoArchiveQuote;
  @override
  @JsonKey(name: 'auto_convert_quote')
  bool? get autoConvertQuote;
  @override
  @JsonKey(name: 'auto_email_invoice')
  bool? get autoEmailInvoice;
  @override
  @JsonKey(name: 'auto_bill_standard_invoices')
  bool? get autoBillStandardInvoices;
  @override
  @JsonKey(name: 'auto_bill')
  String? get autoBill;
  @override
  @JsonKey(name: 'auto_bill_date')
  String? get autoBillDate;
  @override
  @JsonKey(name: 'lock_invoices')
  String? get lockInvoices;
  @override
  @JsonKey(name: 'entity_send_time')
  int? get entitySendTime;
  @override
  @JsonKey(name: 'show_accept_invoice_terms')
  bool? get showAcceptInvoiceTerms;
  @override
  @JsonKey(name: 'show_accept_quote_terms')
  bool? get showAcceptQuoteTerms;
  @override
  @JsonKey(name: 'require_invoice_signature')
  bool? get requireInvoiceSignature;
  @override
  @JsonKey(name: 'require_quote_signature')
  bool? get requireQuoteSignature;
  @override
  @JsonKey(name: 'require_purchase_order_signature')
  bool? get requirePurchaseOrderSignature;
  @override
  @JsonKey(name: 'signature_on_pdf')
  bool? get signatureOnPdf;
  @override
  @JsonKey(name: 'accept_client_input_quote_approval')
  bool? get acceptClientInputQuoteApproval;
  @override
  @JsonKey(name: 'sync_invoice_quote_columns')
  bool? get syncInvoiceQuoteColumns;
  @override
  @JsonKey(name: 'show_shipping_address')
  bool? get showShippingAddress;
  @override
  @JsonKey(name: 'show_paid_stamp')
  bool? get showPaidStamp; // ── PDF / page layout ──────────────────────────────────────────────
  @override
  @JsonKey(name: 'page_size')
  String? get pageSize;
  @override
  @JsonKey(name: 'page_layout')
  String? get pageLayout;
  @override
  @JsonKey(name: 'font_size')
  int? get fontSize;
  @override
  @JsonKey(name: 'primary_font')
  String? get primaryFont;
  @override
  @JsonKey(name: 'secondary_font')
  String? get secondaryFont;
  @override
  @JsonKey(name: 'primary_color')
  String? get primaryColor;
  @override
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor;
  @override
  @JsonKey(name: 'page_numbering')
  bool? get pageNumbering;
  @override
  @JsonKey(name: 'page_numbering_alignment')
  String? get pageNumberingAlignment;
  @override
  @JsonKey(name: 'hide_paid_to_date')
  bool? get hidePaidToDate;
  @override
  @JsonKey(name: 'hide_empty_columns_on_pdf')
  bool? get hideEmptyColumnsOnPdf;
  @override
  @JsonKey(name: 'embed_documents')
  bool? get embedDocuments;
  @override
  @JsonKey(name: 'all_pages_header')
  bool? get allPagesHeader;
  @override
  @JsonKey(name: 'all_pages_footer')
  bool? get allPagesFooter;
  @override
  @JsonKey(name: 'pdf_variables')
  Map<String, List<String>>? get pdfVariables;
  @override
  @JsonKey(name: 'show_pdfhtml_on_mobile')
  bool? get showPdfhtmlOnMobile; // ── Portal ─────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'enable_client_portal')
  bool? get enableClientPortal;
  @override
  @JsonKey(name: 'enable_client_portal_dashboard')
  bool? get enableClientPortalDashboard;
  @override
  @JsonKey(name: 'enable_client_portal_tasks')
  bool? get enableClientPortalTasks;
  @override
  @JsonKey(name: 'show_all_tasks_client_portal')
  String? get showAllTasksClientPortal;
  @override
  @JsonKey(name: 'enable_client_portal_password')
  bool? get enableClientPortalPassword;
  @override
  @JsonKey(name: 'client_portal_terms')
  String? get clientPortalTerms;
  @override
  @JsonKey(name: 'client_portal_privacy_policy')
  String? get clientPortalPrivacyPolicy;
  @override
  @JsonKey(name: 'client_portal_enable_uploads')
  bool? get clientPortalEnableUploads;
  @override
  @JsonKey(name: 'client_portal_allow_under_payment')
  bool? get clientPortalAllowUnderPayment;
  @override
  @JsonKey(name: 'client_portal_under_payment_minimum')
  double? get clientPortalUnderPaymentMinimum;
  @override
  @JsonKey(name: 'client_portal_allow_over_payment')
  bool? get clientPortalAllowOverPayment;
  @override
  @JsonKey(name: 'portal_custom_head')
  String? get portalCustomHead;
  @override
  @JsonKey(name: 'portal_custom_css')
  String? get portalCustomCss;
  @override
  @JsonKey(name: 'portal_custom_footer')
  String? get portalCustomFooter;
  @override
  @JsonKey(name: 'portal_custom_js')
  String? get portalCustomJs;
  @override
  @JsonKey(name: 'client_can_register')
  bool? get clientCanRegister;
  @override
  @JsonKey(name: 'client_initiated_payments')
  bool? get clientInitiatedPayments;
  @override
  @JsonKey(name: 'client_initiated_payments_minimum')
  double? get clientInitiatedPaymentsMinimum;
  @override
  @JsonKey(name: 'enable_client_profile_update')
  bool? get enableClientProfileUpdate;
  @override
  @JsonKey(name: 'client_online_payment_notification')
  bool? get clientOnlinePaymentNotification;
  @override
  @JsonKey(name: 'client_manual_payment_notification')
  bool? get clientManualPaymentNotification;
  @override
  @JsonKey(name: 'vendor_portal_enable_uploads')
  bool? get vendorPortalEnableUploads;
  @override
  @JsonKey(name: 'use_credits_payment')
  String? get useCreditsPayment;
  @override
  @JsonKey(name: 'use_unapplied_payment')
  String? get useUnappliedPayment; // ── Payments / billing ─────────────────────────────────────────────
  @override
  @JsonKey(name: 'payment_terms')
  String? get paymentTerms;
  @override
  @JsonKey(name: 'valid_until')
  String? get validUntil;
  @override
  @JsonKey(name: 'payment_type_id')
  String? get paymentTypeId;
  @override
  @JsonKey(name: 'default_expense_payment_type_id')
  String? get defaultExpensePaymentTypeId;
  @override
  @JsonKey(name: 'company_gateway_ids')
  String? get companyGatewayIds;
  @override
  @JsonKey(name: 'payment_flow')
  String? get paymentFlow;
  @override
  @JsonKey(name: 'unlock_invoice_documents_after_payment')
  bool? get unlockInvoiceDocumentsAfterPayment; // ── Tasks ──────────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'show_task_item_description')
  bool? get showTaskItemDescription;
  @override
  @JsonKey(name: 'allow_billable_task_items')
  bool? get allowBillableTaskItems;
  @override
  @JsonKey(name: 'default_task_rate')
  double? get defaultTaskRate;
  @override
  @JsonKey(name: 'task_round_up')
  bool? get taskRoundUp;
  @override
  @JsonKey(name: 'task_round_to_nearest')
  double? get taskRoundToNearest; // ── e-Invoice ──────────────────────────────────────────────────────
  @override
  @JsonKey(name: 'enable_e_invoice')
  bool? get enableEInvoice;
  @override
  @JsonKey(name: 'e_invoice_type')
  String? get eInvoiceType;
  @override
  @JsonKey(name: 'e_quote_type')
  String? get eQuoteType;
  @override
  @JsonKey(name: 'merge_e_invoice_to_pdf')
  bool? get mergeEInvoiceToPdf;
  @override
  @JsonKey(name: 'skip_automatic_email_with_peppol')
  bool? get skipAutomaticEmailWithPeppol;
  @override
  @JsonKey(name: 'e_invoice_forward_email')
  String? get eInvoiceForwardEmail;
  @override
  @JsonKey(name: 'e_expense_forward_email')
  String? get eExpenseForwardEmail;
  @override
  @JsonKey(name: 'preference_product_notes_for_html_view')
  bool? get preferenceProductNotesForHtmlView; // ── Dashboard / messages ───────────────────────────────────────────
  @override
  @JsonKey(name: 'custom_message_dashboard')
  String? get customMessageDashboard;
  @override
  @JsonKey(name: 'custom_message_unpaid_invoice')
  String? get customMessageUnpaidInvoice;
  @override
  @JsonKey(name: 'custom_message_paid_invoice')
  String? get customMessagePaidInvoice;
  @override
  @JsonKey(name: 'custom_message_unapproved_quote')
  String? get customMessageUnapprovedQuote; // ── Misc ───────────────────────────────────────────────────────────
  @override
  List<dynamic>? get translations;

  /// Create a copy of CompanySettingsApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanySettingsApiImplCopyWith<_$CompanySettingsApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
