// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_settings_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompanySettingsApiImpl _$$CompanySettingsApiImplFromJson(
  Map<String, dynamic> json,
) => _$CompanySettingsApiImpl(
  id: json['id'] as String?,
  name: json['name'] as String?,
  companyLogo: json['company_logo'] as String?,
  companyLogoSize: json['company_logo_size'] as String?,
  website: json['website'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  address1: json['address1'] as String?,
  address2: json['address2'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  postalCode: json['postal_code'] as String?,
  countryId: json['country_id'] as String?,
  vatNumber: json['vat_number'] as String?,
  idNumber: json['id_number'] as String?,
  classification: json['classification'] as String?,
  qrIban: json['qr_iban'] as String?,
  besrId: json['besr_id'] as String?,
  customValue1: json['custom_value1'] as String?,
  customValue2: json['custom_value2'] as String?,
  customValue3: json['custom_value3'] as String?,
  customValue4: json['custom_value4'] as String?,
  timezoneId: json['timezone_id'] as String?,
  dateFormatId: json['date_format_id'] as String?,
  languageId: json['language_id'] as String?,
  currencyId: json['currency_id'] as String?,
  militaryTime: json['military_time'] as bool?,
  showCurrencyCode: json['show_currency_code'] as bool?,
  useCommaAsDecimalPlace: json['use_comma_as_decimal_place'] as bool?,
  firstMonthOfYear: json['first_month_of_year'] as String?,
  invoiceTerms: json['invoice_terms'] as String?,
  invoiceFooter: json['invoice_footer'] as String?,
  quoteTerms: json['quote_terms'] as String?,
  quoteFooter: json['quote_footer'] as String?,
  creditTerms: json['credit_terms'] as String?,
  creditFooter: json['credit_footer'] as String?,
  purchaseOrderTerms: json['purchase_order_terms'] as String?,
  purchaseOrderFooter: json['purchase_order_footer'] as String?,
  purchaseOrderPublicNotes: json['purchase_order_public_notes'] as String?,
  invoiceLabels: json['invoice_labels'] as String?,
  invoiceDesignId: json['invoice_design_id'] as String?,
  quoteDesignId: json['quote_design_id'] as String?,
  creditDesignId: json['credit_design_id'] as String?,
  purchaseOrderDesignId: json['purchase_order_design_id'] as String?,
  statementDesignId: json['statement_design_id'] as String?,
  deliveryNoteDesignId: json['delivery_note_design_id'] as String?,
  paymentReceiptDesignId: json['payment_receipt_design_id'] as String?,
  paymentRefundDesignId: json['payment_refund_design_id'] as String?,
  portalDesignId: json['portal_design_id'] as String?,
  invoiceNumberPattern: json['invoice_number_pattern'] as String?,
  invoiceNumberCounter: (json['invoice_number_counter'] as num?)?.toInt(),
  recurringInvoiceNumberPattern:
      json['recurring_invoice_number_pattern'] as String?,
  recurringInvoiceNumberCounter:
      (json['recurring_invoice_number_counter'] as num?)?.toInt(),
  quoteNumberPattern: json['quote_number_pattern'] as String?,
  quoteNumberCounter: (json['quote_number_counter'] as num?)?.toInt(),
  recurringQuoteNumberPattern:
      json['recurring_quote_number_pattern'] as String?,
  recurringQuoteNumberCounter: (json['recurring_quote_number_counter'] as num?)
      ?.toInt(),
  clientNumberPattern: json['client_number_pattern'] as String?,
  clientNumberCounter: (json['client_number_counter'] as num?)?.toInt(),
  creditNumberPattern: json['credit_number_pattern'] as String?,
  creditNumberCounter: (json['credit_number_counter'] as num?)?.toInt(),
  taskNumberPattern: json['task_number_pattern'] as String?,
  taskNumberCounter: (json['task_number_counter'] as num?)?.toInt(),
  expenseNumberPattern: json['expense_number_pattern'] as String?,
  expenseNumberCounter: (json['expense_number_counter'] as num?)?.toInt(),
  recurringExpenseNumberPattern:
      json['recurring_expense_number_pattern'] as String?,
  recurringExpenseNumberCounter:
      (json['recurring_expense_number_counter'] as num?)?.toInt(),
  vendorNumberPattern: json['vendor_number_pattern'] as String?,
  vendorNumberCounter: (json['vendor_number_counter'] as num?)?.toInt(),
  ticketNumberPattern: json['ticket_number_pattern'] as String?,
  ticketNumberCounter: (json['ticket_number_counter'] as num?)?.toInt(),
  paymentNumberPattern: json['payment_number_pattern'] as String?,
  paymentNumberCounter: (json['payment_number_counter'] as num?)?.toInt(),
  projectNumberPattern: json['project_number_pattern'] as String?,
  projectNumberCounter: (json['project_number_counter'] as num?)?.toInt(),
  purchaseOrderNumberPattern: json['purchase_order_number_pattern'] as String?,
  purchaseOrderNumberCounter: (json['purchase_order_number_counter'] as num?)
      ?.toInt(),
  sharedInvoiceQuoteCounter: json['shared_invoice_quote_counter'] as bool?,
  sharedInvoiceCreditCounter: json['shared_invoice_credit_counter'] as bool?,
  recurringNumberPrefix: json['recurring_number_prefix'] as String?,
  resetCounterFrequencyId: (json['reset_counter_frequency_id'] as num?)
      ?.toInt(),
  resetCounterDate: json['reset_counter_date'] as String?,
  counterPadding: (json['counter_padding'] as num?)?.toInt(),
  counterNumberApplied: json['counter_number_applied'] as String?,
  quoteNumberApplied: json['quote_number_applied'] as String?,
  taxName1: json['tax_name1'] as String?,
  taxRate1: (json['tax_rate1'] as num?)?.toDouble(),
  taxName2: json['tax_name2'] as String?,
  taxRate2: (json['tax_rate2'] as num?)?.toDouble(),
  taxName3: json['tax_name3'] as String?,
  taxRate3: (json['tax_rate3'] as num?)?.toDouble(),
  invoiceTaxes: (json['invoice_taxes'] as num?)?.toInt(),
  inclusiveTaxes: json['inclusive_taxes'] as bool?,
  enableRappenRounding: json['enable_rappen_rounding'] as bool?,
  emailSendingMethod: json['email_sending_method'] as String?,
  gmailSendingUserId: json['gmail_sending_user_id'] as String?,
  replyToEmail: json['reply_to_email'] as String?,
  replyToName: json['reply_to_name'] as String?,
  bccEmail: json['bcc_email'] as String?,
  emailFromName: json['email_from_name'] as String?,
  customSendingEmail: json['custom_sending_email'] as String?,
  emailStyle: json['email_style'] as String?,
  emailStyleCustom: json['email_style_custom'] as String?,
  emailSignature: json['email_signature'] as String?,
  enableEmailMarkup: json['enable_email_markup'] as bool?,
  showEmailFooter: json['show_email_footer'] as bool?,
  pdfEmailAttachment: json['pdf_email_attachment'] as bool?,
  ublEmailAttachment: json['ubl_email_attachment'] as bool?,
  documentEmailAttachment: json['document_email_attachment'] as bool?,
  sendEmailOnMarkPaid: json['send_email_on_mark_paid'] as bool?,
  paymentEmailAllContacts: json['payment_email_all_contacts'] as bool?,
  postmarkSecret: json['postmark_secret'] as String?,
  mailgunSecret: json['mailgun_secret'] as String?,
  mailgunDomain: json['mailgun_domain'] as String?,
  mailgunEndpoint: json['mailgun_endpoint'] as String?,
  brevoSecret: json['brevo_secret'] as String?,
  sesSecretKey: json['ses_secret_key'] as String?,
  sesAccessKey: json['ses_access_key'] as String?,
  sesRegion: json['ses_region'] as String?,
  sesTopicArn: json['ses_topic_arn'] as String?,
  sesFromAddress: json['ses_from_address'] as String?,
  emailSubjectInvoice: json['email_subject_invoice'] as String?,
  emailSubjectQuote: json['email_subject_quote'] as String?,
  emailSubjectCredit: json['email_subject_credit'] as String?,
  emailSubjectPayment: json['email_subject_payment'] as String?,
  emailSubjectPaymentPartial: json['email_subject_payment_partial'] as String?,
  emailSubjectStatement: json['email_subject_statement'] as String?,
  emailSubjectPurchaseOrder: json['email_subject_purchase_order'] as String?,
  emailSubjectReminder1: json['email_subject_reminder1'] as String?,
  emailSubjectReminder2: json['email_subject_reminder2'] as String?,
  emailSubjectReminder3: json['email_subject_reminder3'] as String?,
  emailSubjectReminderEndless:
      json['email_subject_reminder_endless'] as String?,
  emailSubjectCustom1: json['email_subject_custom1'] as String?,
  emailSubjectCustom2: json['email_subject_custom2'] as String?,
  emailSubjectCustom3: json['email_subject_custom3'] as String?,
  emailTemplateInvoice: json['email_template_invoice'] as String?,
  emailTemplateQuote: json['email_template_quote'] as String?,
  emailTemplateCredit: json['email_template_credit'] as String?,
  emailTemplatePayment: json['email_template_payment'] as String?,
  emailTemplatePaymentPartial:
      json['email_template_payment_partial'] as String?,
  emailTemplateStatement: json['email_template_statement'] as String?,
  emailTemplatePurchaseOrder: json['email_template_purchase_order'] as String?,
  emailTemplateReminder1: json['email_template_reminder1'] as String?,
  emailTemplateReminder2: json['email_template_reminder2'] as String?,
  emailTemplateReminder3: json['email_template_reminder3'] as String?,
  emailTemplateReminderEndless:
      json['email_template_reminder_endless'] as String?,
  emailTemplateCustom1: json['email_template_custom1'] as String?,
  emailTemplateCustom2: json['email_template_custom2'] as String?,
  emailTemplateCustom3: json['email_template_custom3'] as String?,
  sendReminders: json['send_reminders'] as bool?,
  enableReminder1: json['enable_reminder1'] as bool?,
  enableReminder2: json['enable_reminder2'] as bool?,
  enableReminder3: json['enable_reminder3'] as bool?,
  enableReminderEndless: json['enable_reminder_endless'] as bool?,
  numDaysReminder1: (json['num_days_reminder1'] as num?)?.toInt(),
  numDaysReminder2: (json['num_days_reminder2'] as num?)?.toInt(),
  numDaysReminder3: (json['num_days_reminder3'] as num?)?.toInt(),
  scheduleReminder1: json['schedule_reminder1'] as String?,
  scheduleReminder2: json['schedule_reminder2'] as String?,
  scheduleReminder3: json['schedule_reminder3'] as String?,
  reminderSendTime: (json['reminder_send_time'] as num?)?.toInt(),
  lateFeeAmount1: (json['late_fee_amount1'] as num?)?.toDouble(),
  lateFeeAmount2: (json['late_fee_amount2'] as num?)?.toDouble(),
  lateFeeAmount3: (json['late_fee_amount3'] as num?)?.toDouble(),
  lateFeePercent1: (json['late_fee_percent1'] as num?)?.toDouble(),
  lateFeePercent2: (json['late_fee_percent2'] as num?)?.toDouble(),
  lateFeePercent3: (json['late_fee_percent3'] as num?)?.toDouble(),
  endlessReminderFrequencyId: json['endless_reminder_frequency_id'] as String?,
  lateFeeEndlessAmount: (json['late_fee_endless_amount'] as num?)?.toDouble(),
  lateFeeEndlessPercent: (json['late_fee_endless_percent'] as num?)?.toDouble(),
  autoArchiveInvoice: json['auto_archive_invoice'] as bool?,
  autoArchiveInvoiceCancelled: json['auto_archive_invoice_cancelled'] as bool?,
  autoArchiveQuote: json['auto_archive_quote'] as bool?,
  autoConvertQuote: json['auto_convert_quote'] as bool?,
  autoEmailInvoice: json['auto_email_invoice'] as bool?,
  autoBillStandardInvoices: json['auto_bill_standard_invoices'] as bool?,
  autoBill: json['auto_bill'] as String?,
  autoBillDate: json['auto_bill_date'] as String?,
  lockInvoices: json['lock_invoices'] as String?,
  entitySendTime: (json['entity_send_time'] as num?)?.toInt(),
  showAcceptInvoiceTerms: json['show_accept_invoice_terms'] as bool?,
  showAcceptQuoteTerms: json['show_accept_quote_terms'] as bool?,
  requireInvoiceSignature: json['require_invoice_signature'] as bool?,
  requireQuoteSignature: json['require_quote_signature'] as bool?,
  requirePurchaseOrderSignature:
      json['require_purchase_order_signature'] as bool?,
  signatureOnPdf: json['signature_on_pdf'] as bool?,
  acceptClientInputQuoteApproval:
      json['accept_client_input_quote_approval'] as bool?,
  syncInvoiceQuoteColumns: json['sync_invoice_quote_columns'] as bool?,
  showShippingAddress: json['show_shipping_address'] as bool?,
  showPaidStamp: json['show_paid_stamp'] as bool?,
  pageSize: json['page_size'] as String?,
  pageLayout: json['page_layout'] as String?,
  fontSize: (json['font_size'] as num?)?.toInt(),
  primaryFont: json['primary_font'] as String?,
  secondaryFont: json['secondary_font'] as String?,
  primaryColor: json['primary_color'] as String?,
  secondaryColor: json['secondary_color'] as String?,
  pageNumbering: json['page_numbering'] as bool?,
  pageNumberingAlignment: json['page_numbering_alignment'] as String?,
  hidePaidToDate: json['hide_paid_to_date'] as bool?,
  hideEmptyColumnsOnPdf: json['hide_empty_columns_on_pdf'] as bool?,
  embedDocuments: json['embed_documents'] as bool?,
  allPagesHeader: json['all_pages_header'] as bool?,
  allPagesFooter: json['all_pages_footer'] as bool?,
  pdfVariables: (json['pdf_variables'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  showPdfhtmlOnMobile: json['show_pdfhtml_on_mobile'] as bool?,
  enableClientPortal: json['enable_client_portal'] as bool?,
  enableClientPortalDashboard: json['enable_client_portal_dashboard'] as bool?,
  enableClientPortalTasks: json['enable_client_portal_tasks'] as bool?,
  showAllTasksClientPortal: json['show_all_tasks_client_portal'] as String?,
  enableClientPortalPassword: json['enable_client_portal_password'] as bool?,
  clientPortalTerms: json['client_portal_terms'] as String?,
  clientPortalPrivacyPolicy: json['client_portal_privacy_policy'] as String?,
  clientPortalEnableUploads: json['client_portal_enable_uploads'] as bool?,
  clientPortalAllowUnderPayment:
      json['client_portal_allow_under_payment'] as bool?,
  clientPortalUnderPaymentMinimum:
      (json['client_portal_under_payment_minimum'] as num?)?.toDouble(),
  clientPortalAllowOverPayment:
      json['client_portal_allow_over_payment'] as bool?,
  portalCustomHead: json['portal_custom_head'] as String?,
  portalCustomCss: json['portal_custom_css'] as String?,
  portalCustomFooter: json['portal_custom_footer'] as String?,
  portalCustomJs: json['portal_custom_js'] as String?,
  clientCanRegister: json['client_can_register'] as bool?,
  clientInitiatedPayments: json['client_initiated_payments'] as bool?,
  clientInitiatedPaymentsMinimum:
      (json['client_initiated_payments_minimum'] as num?)?.toDouble(),
  enableClientProfileUpdate: json['enable_client_profile_update'] as bool?,
  clientOnlinePaymentNotification:
      json['client_online_payment_notification'] as bool?,
  clientManualPaymentNotification:
      json['client_manual_payment_notification'] as bool?,
  vendorPortalEnableUploads: json['vendor_portal_enable_uploads'] as bool?,
  useCreditsPayment: json['use_credits_payment'] as String?,
  useUnappliedPayment: json['use_unapplied_payment'] as String?,
  paymentTerms: json['payment_terms'] as String?,
  validUntil: json['valid_until'] as String?,
  paymentTypeId: json['payment_type_id'] as String?,
  defaultExpensePaymentTypeId:
      json['default_expense_payment_type_id'] as String?,
  companyGatewayIds: json['company_gateway_ids'] as String?,
  paymentFlow: json['payment_flow'] as String?,
  unlockInvoiceDocumentsAfterPayment:
      json['unlock_invoice_documents_after_payment'] as bool?,
  showTaskItemDescription: json['show_task_item_description'] as bool?,
  allowBillableTaskItems: json['allow_billable_task_items'] as bool?,
  defaultTaskRate: (json['default_task_rate'] as num?)?.toDouble(),
  taskRoundUp: json['task_round_up'] as bool?,
  taskRoundToNearest: (json['task_round_to_nearest'] as num?)?.toDouble(),
  enableEInvoice: json['enable_e_invoice'] as bool?,
  eInvoiceType: json['e_invoice_type'] as String?,
  eQuoteType: json['e_quote_type'] as String?,
  mergeEInvoiceToPdf: json['merge_e_invoice_to_pdf'] as bool?,
  skipAutomaticEmailWithPeppol:
      json['skip_automatic_email_with_peppol'] as bool?,
  eInvoiceForwardEmail: json['e_invoice_forward_email'] as String?,
  eExpenseForwardEmail: json['e_expense_forward_email'] as String?,
  preferenceProductNotesForHtmlView:
      json['preference_product_notes_for_html_view'] as bool?,
  customMessageDashboard: json['custom_message_dashboard'] as String?,
  customMessageUnpaidInvoice: json['custom_message_unpaid_invoice'] as String?,
  customMessagePaidInvoice: json['custom_message_paid_invoice'] as String?,
  customMessageUnapprovedQuote:
      json['custom_message_unapproved_quote'] as String?,
  translations: json['translations'] as List<dynamic>?,
);

Map<String, dynamic> _$$CompanySettingsApiImplToJson(
  _$CompanySettingsApiImpl instance,
) => <String, dynamic>{
  if (instance.id case final value?) 'id': value,
  if (instance.name case final value?) 'name': value,
  if (instance.companyLogo case final value?) 'company_logo': value,
  if (instance.companyLogoSize case final value?) 'company_logo_size': value,
  if (instance.website case final value?) 'website': value,
  if (instance.phone case final value?) 'phone': value,
  if (instance.email case final value?) 'email': value,
  if (instance.address1 case final value?) 'address1': value,
  if (instance.address2 case final value?) 'address2': value,
  if (instance.city case final value?) 'city': value,
  if (instance.state case final value?) 'state': value,
  if (instance.postalCode case final value?) 'postal_code': value,
  if (instance.countryId case final value?) 'country_id': value,
  if (instance.vatNumber case final value?) 'vat_number': value,
  if (instance.idNumber case final value?) 'id_number': value,
  if (instance.classification case final value?) 'classification': value,
  if (instance.qrIban case final value?) 'qr_iban': value,
  if (instance.besrId case final value?) 'besr_id': value,
  if (instance.customValue1 case final value?) 'custom_value1': value,
  if (instance.customValue2 case final value?) 'custom_value2': value,
  if (instance.customValue3 case final value?) 'custom_value3': value,
  if (instance.customValue4 case final value?) 'custom_value4': value,
  if (instance.timezoneId case final value?) 'timezone_id': value,
  if (instance.dateFormatId case final value?) 'date_format_id': value,
  if (instance.languageId case final value?) 'language_id': value,
  if (instance.currencyId case final value?) 'currency_id': value,
  if (instance.militaryTime case final value?) 'military_time': value,
  if (instance.showCurrencyCode case final value?) 'show_currency_code': value,
  if (instance.useCommaAsDecimalPlace case final value?)
    'use_comma_as_decimal_place': value,
  if (instance.firstMonthOfYear case final value?) 'first_month_of_year': value,
  if (instance.invoiceTerms case final value?) 'invoice_terms': value,
  if (instance.invoiceFooter case final value?) 'invoice_footer': value,
  if (instance.quoteTerms case final value?) 'quote_terms': value,
  if (instance.quoteFooter case final value?) 'quote_footer': value,
  if (instance.creditTerms case final value?) 'credit_terms': value,
  if (instance.creditFooter case final value?) 'credit_footer': value,
  if (instance.purchaseOrderTerms case final value?)
    'purchase_order_terms': value,
  if (instance.purchaseOrderFooter case final value?)
    'purchase_order_footer': value,
  if (instance.purchaseOrderPublicNotes case final value?)
    'purchase_order_public_notes': value,
  if (instance.invoiceLabels case final value?) 'invoice_labels': value,
  if (instance.invoiceDesignId case final value?) 'invoice_design_id': value,
  if (instance.quoteDesignId case final value?) 'quote_design_id': value,
  if (instance.creditDesignId case final value?) 'credit_design_id': value,
  if (instance.purchaseOrderDesignId case final value?)
    'purchase_order_design_id': value,
  if (instance.statementDesignId case final value?)
    'statement_design_id': value,
  if (instance.deliveryNoteDesignId case final value?)
    'delivery_note_design_id': value,
  if (instance.paymentReceiptDesignId case final value?)
    'payment_receipt_design_id': value,
  if (instance.paymentRefundDesignId case final value?)
    'payment_refund_design_id': value,
  if (instance.portalDesignId case final value?) 'portal_design_id': value,
  if (instance.invoiceNumberPattern case final value?)
    'invoice_number_pattern': value,
  if (instance.invoiceNumberCounter case final value?)
    'invoice_number_counter': value,
  if (instance.recurringInvoiceNumberPattern case final value?)
    'recurring_invoice_number_pattern': value,
  if (instance.recurringInvoiceNumberCounter case final value?)
    'recurring_invoice_number_counter': value,
  if (instance.quoteNumberPattern case final value?)
    'quote_number_pattern': value,
  if (instance.quoteNumberCounter case final value?)
    'quote_number_counter': value,
  if (instance.recurringQuoteNumberPattern case final value?)
    'recurring_quote_number_pattern': value,
  if (instance.recurringQuoteNumberCounter case final value?)
    'recurring_quote_number_counter': value,
  if (instance.clientNumberPattern case final value?)
    'client_number_pattern': value,
  if (instance.clientNumberCounter case final value?)
    'client_number_counter': value,
  if (instance.creditNumberPattern case final value?)
    'credit_number_pattern': value,
  if (instance.creditNumberCounter case final value?)
    'credit_number_counter': value,
  if (instance.taskNumberPattern case final value?)
    'task_number_pattern': value,
  if (instance.taskNumberCounter case final value?)
    'task_number_counter': value,
  if (instance.expenseNumberPattern case final value?)
    'expense_number_pattern': value,
  if (instance.expenseNumberCounter case final value?)
    'expense_number_counter': value,
  if (instance.recurringExpenseNumberPattern case final value?)
    'recurring_expense_number_pattern': value,
  if (instance.recurringExpenseNumberCounter case final value?)
    'recurring_expense_number_counter': value,
  if (instance.vendorNumberPattern case final value?)
    'vendor_number_pattern': value,
  if (instance.vendorNumberCounter case final value?)
    'vendor_number_counter': value,
  if (instance.ticketNumberPattern case final value?)
    'ticket_number_pattern': value,
  if (instance.ticketNumberCounter case final value?)
    'ticket_number_counter': value,
  if (instance.paymentNumberPattern case final value?)
    'payment_number_pattern': value,
  if (instance.paymentNumberCounter case final value?)
    'payment_number_counter': value,
  if (instance.projectNumberPattern case final value?)
    'project_number_pattern': value,
  if (instance.projectNumberCounter case final value?)
    'project_number_counter': value,
  if (instance.purchaseOrderNumberPattern case final value?)
    'purchase_order_number_pattern': value,
  if (instance.purchaseOrderNumberCounter case final value?)
    'purchase_order_number_counter': value,
  if (instance.sharedInvoiceQuoteCounter case final value?)
    'shared_invoice_quote_counter': value,
  if (instance.sharedInvoiceCreditCounter case final value?)
    'shared_invoice_credit_counter': value,
  if (instance.recurringNumberPrefix case final value?)
    'recurring_number_prefix': value,
  if (instance.resetCounterFrequencyId case final value?)
    'reset_counter_frequency_id': value,
  if (instance.resetCounterDate case final value?) 'reset_counter_date': value,
  if (instance.counterPadding case final value?) 'counter_padding': value,
  if (instance.counterNumberApplied case final value?)
    'counter_number_applied': value,
  if (instance.quoteNumberApplied case final value?)
    'quote_number_applied': value,
  if (instance.taxName1 case final value?) 'tax_name1': value,
  if (instance.taxRate1 case final value?) 'tax_rate1': value,
  if (instance.taxName2 case final value?) 'tax_name2': value,
  if (instance.taxRate2 case final value?) 'tax_rate2': value,
  if (instance.taxName3 case final value?) 'tax_name3': value,
  if (instance.taxRate3 case final value?) 'tax_rate3': value,
  if (instance.invoiceTaxes case final value?) 'invoice_taxes': value,
  if (instance.inclusiveTaxes case final value?) 'inclusive_taxes': value,
  if (instance.enableRappenRounding case final value?)
    'enable_rappen_rounding': value,
  if (instance.emailSendingMethod case final value?)
    'email_sending_method': value,
  if (instance.gmailSendingUserId case final value?)
    'gmail_sending_user_id': value,
  if (instance.replyToEmail case final value?) 'reply_to_email': value,
  if (instance.replyToName case final value?) 'reply_to_name': value,
  if (instance.bccEmail case final value?) 'bcc_email': value,
  if (instance.emailFromName case final value?) 'email_from_name': value,
  if (instance.customSendingEmail case final value?)
    'custom_sending_email': value,
  if (instance.emailStyle case final value?) 'email_style': value,
  if (instance.emailStyleCustom case final value?) 'email_style_custom': value,
  if (instance.emailSignature case final value?) 'email_signature': value,
  if (instance.enableEmailMarkup case final value?)
    'enable_email_markup': value,
  if (instance.showEmailFooter case final value?) 'show_email_footer': value,
  if (instance.pdfEmailAttachment case final value?)
    'pdf_email_attachment': value,
  if (instance.ublEmailAttachment case final value?)
    'ubl_email_attachment': value,
  if (instance.documentEmailAttachment case final value?)
    'document_email_attachment': value,
  if (instance.sendEmailOnMarkPaid case final value?)
    'send_email_on_mark_paid': value,
  if (instance.paymentEmailAllContacts case final value?)
    'payment_email_all_contacts': value,
  if (instance.postmarkSecret case final value?) 'postmark_secret': value,
  if (instance.mailgunSecret case final value?) 'mailgun_secret': value,
  if (instance.mailgunDomain case final value?) 'mailgun_domain': value,
  if (instance.mailgunEndpoint case final value?) 'mailgun_endpoint': value,
  if (instance.brevoSecret case final value?) 'brevo_secret': value,
  if (instance.sesSecretKey case final value?) 'ses_secret_key': value,
  if (instance.sesAccessKey case final value?) 'ses_access_key': value,
  if (instance.sesRegion case final value?) 'ses_region': value,
  if (instance.sesTopicArn case final value?) 'ses_topic_arn': value,
  if (instance.sesFromAddress case final value?) 'ses_from_address': value,
  if (instance.emailSubjectInvoice case final value?)
    'email_subject_invoice': value,
  if (instance.emailSubjectQuote case final value?)
    'email_subject_quote': value,
  if (instance.emailSubjectCredit case final value?)
    'email_subject_credit': value,
  if (instance.emailSubjectPayment case final value?)
    'email_subject_payment': value,
  if (instance.emailSubjectPaymentPartial case final value?)
    'email_subject_payment_partial': value,
  if (instance.emailSubjectStatement case final value?)
    'email_subject_statement': value,
  if (instance.emailSubjectPurchaseOrder case final value?)
    'email_subject_purchase_order': value,
  if (instance.emailSubjectReminder1 case final value?)
    'email_subject_reminder1': value,
  if (instance.emailSubjectReminder2 case final value?)
    'email_subject_reminder2': value,
  if (instance.emailSubjectReminder3 case final value?)
    'email_subject_reminder3': value,
  if (instance.emailSubjectReminderEndless case final value?)
    'email_subject_reminder_endless': value,
  if (instance.emailSubjectCustom1 case final value?)
    'email_subject_custom1': value,
  if (instance.emailSubjectCustom2 case final value?)
    'email_subject_custom2': value,
  if (instance.emailSubjectCustom3 case final value?)
    'email_subject_custom3': value,
  if (instance.emailTemplateInvoice case final value?)
    'email_template_invoice': value,
  if (instance.emailTemplateQuote case final value?)
    'email_template_quote': value,
  if (instance.emailTemplateCredit case final value?)
    'email_template_credit': value,
  if (instance.emailTemplatePayment case final value?)
    'email_template_payment': value,
  if (instance.emailTemplatePaymentPartial case final value?)
    'email_template_payment_partial': value,
  if (instance.emailTemplateStatement case final value?)
    'email_template_statement': value,
  if (instance.emailTemplatePurchaseOrder case final value?)
    'email_template_purchase_order': value,
  if (instance.emailTemplateReminder1 case final value?)
    'email_template_reminder1': value,
  if (instance.emailTemplateReminder2 case final value?)
    'email_template_reminder2': value,
  if (instance.emailTemplateReminder3 case final value?)
    'email_template_reminder3': value,
  if (instance.emailTemplateReminderEndless case final value?)
    'email_template_reminder_endless': value,
  if (instance.emailTemplateCustom1 case final value?)
    'email_template_custom1': value,
  if (instance.emailTemplateCustom2 case final value?)
    'email_template_custom2': value,
  if (instance.emailTemplateCustom3 case final value?)
    'email_template_custom3': value,
  if (instance.sendReminders case final value?) 'send_reminders': value,
  if (instance.enableReminder1 case final value?) 'enable_reminder1': value,
  if (instance.enableReminder2 case final value?) 'enable_reminder2': value,
  if (instance.enableReminder3 case final value?) 'enable_reminder3': value,
  if (instance.enableReminderEndless case final value?)
    'enable_reminder_endless': value,
  if (instance.numDaysReminder1 case final value?) 'num_days_reminder1': value,
  if (instance.numDaysReminder2 case final value?) 'num_days_reminder2': value,
  if (instance.numDaysReminder3 case final value?) 'num_days_reminder3': value,
  if (instance.scheduleReminder1 case final value?) 'schedule_reminder1': value,
  if (instance.scheduleReminder2 case final value?) 'schedule_reminder2': value,
  if (instance.scheduleReminder3 case final value?) 'schedule_reminder3': value,
  if (instance.reminderSendTime case final value?) 'reminder_send_time': value,
  if (instance.lateFeeAmount1 case final value?) 'late_fee_amount1': value,
  if (instance.lateFeeAmount2 case final value?) 'late_fee_amount2': value,
  if (instance.lateFeeAmount3 case final value?) 'late_fee_amount3': value,
  if (instance.lateFeePercent1 case final value?) 'late_fee_percent1': value,
  if (instance.lateFeePercent2 case final value?) 'late_fee_percent2': value,
  if (instance.lateFeePercent3 case final value?) 'late_fee_percent3': value,
  if (instance.endlessReminderFrequencyId case final value?)
    'endless_reminder_frequency_id': value,
  if (instance.lateFeeEndlessAmount case final value?)
    'late_fee_endless_amount': value,
  if (instance.lateFeeEndlessPercent case final value?)
    'late_fee_endless_percent': value,
  if (instance.autoArchiveInvoice case final value?)
    'auto_archive_invoice': value,
  if (instance.autoArchiveInvoiceCancelled case final value?)
    'auto_archive_invoice_cancelled': value,
  if (instance.autoArchiveQuote case final value?) 'auto_archive_quote': value,
  if (instance.autoConvertQuote case final value?) 'auto_convert_quote': value,
  if (instance.autoEmailInvoice case final value?) 'auto_email_invoice': value,
  if (instance.autoBillStandardInvoices case final value?)
    'auto_bill_standard_invoices': value,
  if (instance.autoBill case final value?) 'auto_bill': value,
  if (instance.autoBillDate case final value?) 'auto_bill_date': value,
  if (instance.lockInvoices case final value?) 'lock_invoices': value,
  if (instance.entitySendTime case final value?) 'entity_send_time': value,
  if (instance.showAcceptInvoiceTerms case final value?)
    'show_accept_invoice_terms': value,
  if (instance.showAcceptQuoteTerms case final value?)
    'show_accept_quote_terms': value,
  if (instance.requireInvoiceSignature case final value?)
    'require_invoice_signature': value,
  if (instance.requireQuoteSignature case final value?)
    'require_quote_signature': value,
  if (instance.requirePurchaseOrderSignature case final value?)
    'require_purchase_order_signature': value,
  if (instance.signatureOnPdf case final value?) 'signature_on_pdf': value,
  if (instance.acceptClientInputQuoteApproval case final value?)
    'accept_client_input_quote_approval': value,
  if (instance.syncInvoiceQuoteColumns case final value?)
    'sync_invoice_quote_columns': value,
  if (instance.showShippingAddress case final value?)
    'show_shipping_address': value,
  if (instance.showPaidStamp case final value?) 'show_paid_stamp': value,
  if (instance.pageSize case final value?) 'page_size': value,
  if (instance.pageLayout case final value?) 'page_layout': value,
  if (instance.fontSize case final value?) 'font_size': value,
  if (instance.primaryFont case final value?) 'primary_font': value,
  if (instance.secondaryFont case final value?) 'secondary_font': value,
  if (instance.primaryColor case final value?) 'primary_color': value,
  if (instance.secondaryColor case final value?) 'secondary_color': value,
  if (instance.pageNumbering case final value?) 'page_numbering': value,
  if (instance.pageNumberingAlignment case final value?)
    'page_numbering_alignment': value,
  if (instance.hidePaidToDate case final value?) 'hide_paid_to_date': value,
  if (instance.hideEmptyColumnsOnPdf case final value?)
    'hide_empty_columns_on_pdf': value,
  if (instance.embedDocuments case final value?) 'embed_documents': value,
  if (instance.allPagesHeader case final value?) 'all_pages_header': value,
  if (instance.allPagesFooter case final value?) 'all_pages_footer': value,
  if (instance.pdfVariables case final value?) 'pdf_variables': value,
  if (instance.showPdfhtmlOnMobile case final value?)
    'show_pdfhtml_on_mobile': value,
  if (instance.enableClientPortal case final value?)
    'enable_client_portal': value,
  if (instance.enableClientPortalDashboard case final value?)
    'enable_client_portal_dashboard': value,
  if (instance.enableClientPortalTasks case final value?)
    'enable_client_portal_tasks': value,
  if (instance.showAllTasksClientPortal case final value?)
    'show_all_tasks_client_portal': value,
  if (instance.enableClientPortalPassword case final value?)
    'enable_client_portal_password': value,
  if (instance.clientPortalTerms case final value?)
    'client_portal_terms': value,
  if (instance.clientPortalPrivacyPolicy case final value?)
    'client_portal_privacy_policy': value,
  if (instance.clientPortalEnableUploads case final value?)
    'client_portal_enable_uploads': value,
  if (instance.clientPortalAllowUnderPayment case final value?)
    'client_portal_allow_under_payment': value,
  if (instance.clientPortalUnderPaymentMinimum case final value?)
    'client_portal_under_payment_minimum': value,
  if (instance.clientPortalAllowOverPayment case final value?)
    'client_portal_allow_over_payment': value,
  if (instance.portalCustomHead case final value?) 'portal_custom_head': value,
  if (instance.portalCustomCss case final value?) 'portal_custom_css': value,
  if (instance.portalCustomFooter case final value?)
    'portal_custom_footer': value,
  if (instance.portalCustomJs case final value?) 'portal_custom_js': value,
  if (instance.clientCanRegister case final value?)
    'client_can_register': value,
  if (instance.clientInitiatedPayments case final value?)
    'client_initiated_payments': value,
  if (instance.clientInitiatedPaymentsMinimum case final value?)
    'client_initiated_payments_minimum': value,
  if (instance.enableClientProfileUpdate case final value?)
    'enable_client_profile_update': value,
  if (instance.clientOnlinePaymentNotification case final value?)
    'client_online_payment_notification': value,
  if (instance.clientManualPaymentNotification case final value?)
    'client_manual_payment_notification': value,
  if (instance.vendorPortalEnableUploads case final value?)
    'vendor_portal_enable_uploads': value,
  if (instance.useCreditsPayment case final value?)
    'use_credits_payment': value,
  if (instance.useUnappliedPayment case final value?)
    'use_unapplied_payment': value,
  if (instance.paymentTerms case final value?) 'payment_terms': value,
  if (instance.validUntil case final value?) 'valid_until': value,
  if (instance.paymentTypeId case final value?) 'payment_type_id': value,
  if (instance.defaultExpensePaymentTypeId case final value?)
    'default_expense_payment_type_id': value,
  if (instance.companyGatewayIds case final value?)
    'company_gateway_ids': value,
  if (instance.paymentFlow case final value?) 'payment_flow': value,
  if (instance.unlockInvoiceDocumentsAfterPayment case final value?)
    'unlock_invoice_documents_after_payment': value,
  if (instance.showTaskItemDescription case final value?)
    'show_task_item_description': value,
  if (instance.allowBillableTaskItems case final value?)
    'allow_billable_task_items': value,
  if (instance.defaultTaskRate case final value?) 'default_task_rate': value,
  if (instance.taskRoundUp case final value?) 'task_round_up': value,
  if (instance.taskRoundToNearest case final value?)
    'task_round_to_nearest': value,
  if (instance.enableEInvoice case final value?) 'enable_e_invoice': value,
  if (instance.eInvoiceType case final value?) 'e_invoice_type': value,
  if (instance.eQuoteType case final value?) 'e_quote_type': value,
  if (instance.mergeEInvoiceToPdf case final value?)
    'merge_e_invoice_to_pdf': value,
  if (instance.skipAutomaticEmailWithPeppol case final value?)
    'skip_automatic_email_with_peppol': value,
  if (instance.eInvoiceForwardEmail case final value?)
    'e_invoice_forward_email': value,
  if (instance.eExpenseForwardEmail case final value?)
    'e_expense_forward_email': value,
  if (instance.preferenceProductNotesForHtmlView case final value?)
    'preference_product_notes_for_html_view': value,
  if (instance.customMessageDashboard case final value?)
    'custom_message_dashboard': value,
  if (instance.customMessageUnpaidInvoice case final value?)
    'custom_message_unpaid_invoice': value,
  if (instance.customMessagePaidInvoice case final value?)
    'custom_message_paid_invoice': value,
  if (instance.customMessageUnapprovedQuote case final value?)
    'custom_message_unapproved_quote': value,
  if (instance.translations case final value?) 'translations': value,
};
