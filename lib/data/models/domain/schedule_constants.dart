/// Schedule template + parameter constants. Wire keys exact-match both
/// legacy clients (admin-portal `schedule_model.dart` + React
/// `schedule.ts`); the server validates on these strings.
library;

// ---------- Templates ----------

const String kScheduleTemplateEmailStatement = 'email_statement';
const String kScheduleTemplateEmailRecord = 'email_record';
const String kScheduleTemplateEmailReport = 'email_report';
const String kScheduleTemplateInvoiceOutstandingTasks =
    'invoice_outstanding_tasks';
const String kScheduleTemplatePaymentSchedule = 'payment_schedule';

const List<String> kScheduleTemplates = <String>[
  kScheduleTemplateEmailStatement,
  kScheduleTemplateEmailRecord,
  kScheduleTemplateEmailReport,
  kScheduleTemplateInvoiceOutstandingTasks,
  kScheduleTemplatePaymentSchedule,
];

// ---------- Frequencies ----------

/// String keys match the wire — recurring invoices reuse the same map, so
/// the keys are the integer-as-string ids the server returns.
const Map<String, String> kScheduleFrequencies = <String, String>{
  '1': 'freq_daily',
  '2': 'freq_weekly',
  '3': 'freq_two_weeks',
  '4': 'freq_four_weeks',
  '5': 'freq_monthly',
  '6': 'freq_two_months',
  '7': 'freq_three_months',
  '8': 'freq_four_months',
  '9': 'freq_six_months',
  '10': 'freq_annually',
  '11': 'freq_two_years',
  '12': 'freq_three_years',
};

// ---------- Statement statuses ----------

const String kStatementStatusAll = 'all';
const String kStatementStatusPaid = 'paid';
const String kStatementStatusUnpaid = 'unpaid';

const List<String> kStatementStatuses = <String>[
  kStatementStatusAll,
  kStatementStatusPaid,
  kStatementStatusUnpaid,
];

// ---------- email_record entities + email templates ----------

const List<String> kEmailRecordEntityTypes = <String>[
  'invoice',
  'quote',
  'credit',
  'purchase_order',
];

/// For each entity type, the email-template options available on the
/// `parameters.template` dropdown. The first one in each list is the
/// default. Source: admin-portal `schedule_edit.dart:397‑523`.
const Map<String, List<String>> kEmailRecordTemplatesPerEntity =
    <String, List<String>>{
      'invoice': <String>[
        'initial',
        'reminder1',
        'reminder2',
        'reminder3',
        'reminder_endless',
        'custom1',
        'custom2',
        'custom3',
      ],
      'quote': <String>['initial', 'reminder1', 'custom1', 'custom2', 'custom3'],
      'credit': <String>['initial', 'custom1', 'custom2', 'custom3'],
      'purchase_order': <String>[
        'initial',
        'custom1',
        'custom2',
        'custom3',
      ],
    };

// ---------- email_report ----------

/// All 19 report names the server accepts on `parameters.report_name`.
/// Source: React `ExportType` enum at
/// `/Users/hillel/Code/react/src/common/enums/export-format.ts`.
const List<String> kEmailReportReportNames = <String>[
  'activity',
  'invoice',
  'invoice_item',
  'product_sales',
  'profitloss',
  'client',
  'contact',
  'recurring_invoice',
  'quote',
  'quote_item',
  'credit',
  'document',
  'payment',
  'expense',
  'task',
  'product',
  'vendor',
  'purchase_order',
  'purchase_order_item',
];

/// Field names a per-report-type spec may declare. The edit form renders
/// only the fields named in the active report's set.
enum EmailReportField {
  sendEmail,
  dateRange,
  startDate,
  endDate,
  status,
  documentEmailAttachment,
  pdfEmailAttachment,
  isExpenseBilled,
  isIncomeBilled,
  includeTax,
  includeDeleted,
  productKey,
  clientIdSingular,
  clients,
  vendors,
  projects,
  categories,
  templateId,
  groupBy,
  reportKeys,
}

/// Per-report-type field spec. Mirrors React `EmailReport.tsx:60‑208`.
/// Every report carries `sendEmail` and most carry `dateRange`; the
/// distinguishing fields are domain-specific (invoices add `status`,
/// expenses add `is_expense_billed`, profit-and-loss adds
/// `is_income_billed`, etc.).
const Map<String, Set<EmailReportField>> kEmailReportFieldsByReport =
    <String, Set<EmailReportField>>{
      'activity': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
      },
      'invoice': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.clients,
        EmailReportField.documentEmailAttachment,
        EmailReportField.pdfEmailAttachment,
        EmailReportField.includeDeleted,
      },
      'invoice_item': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.clients,
        EmailReportField.productKey,
        EmailReportField.includeDeleted,
      },
      'product_sales': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
        EmailReportField.productKey,
      },
      'profitloss': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.isIncomeBilled,
        EmailReportField.isExpenseBilled,
        EmailReportField.includeTax,
      },
      'client': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clientIdSingular,
        EmailReportField.includeDeleted,
      },
      'contact': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
      },
      'recurring_invoice': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.clients,
      },
      'quote': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.clients,
        EmailReportField.documentEmailAttachment,
        EmailReportField.pdfEmailAttachment,
      },
      'quote_item': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
        EmailReportField.productKey,
      },
      'credit': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.clients,
      },
      'document': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
      },
      'payment': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
        EmailReportField.includeDeleted,
      },
      'expense': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
        EmailReportField.vendors,
        EmailReportField.projects,
        EmailReportField.categories,
        EmailReportField.isExpenseBilled,
        EmailReportField.includeDeleted,
      },
      'task': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.clients,
        EmailReportField.projects,
      },
      'product': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.productKey,
      },
      'vendor': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.vendors,
      },
      'purchase_order': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.status,
        EmailReportField.vendors,
        EmailReportField.documentEmailAttachment,
        EmailReportField.pdfEmailAttachment,
      },
      'purchase_order_item': <EmailReportField>{
        EmailReportField.sendEmail,
        EmailReportField.dateRange,
        EmailReportField.startDate,
        EmailReportField.endDate,
        EmailReportField.vendors,
        EmailReportField.productKey,
      },
    };

/// Categorize each report for grouped typeahead rendering (UX D in the
/// plan). Returns the localization key for the group label.
String emailReportCategoryOf(String reportName) {
  switch (reportName) {
    case 'invoice':
    case 'invoice_item':
    case 'recurring_invoice':
    case 'quote':
    case 'quote_item':
    case 'credit':
      return 'invoices';
    case 'payment':
    case 'product_sales':
    case 'profitloss':
      return 'financial';
    case 'client':
    case 'contact':
      return 'clients';
    case 'product':
      return 'products';
    case 'expense':
    case 'vendor':
    case 'purchase_order':
    case 'purchase_order_item':
      return 'vendors';
    case 'task':
      return 'tasks';
    default:
      return 'other';
  }
}

// ---------- Date-range options (shared with reports / statements) ----------

/// Date-range options that both the schedule editor and the dashboard
/// filters share. Keys are the wire strings the server expects on
/// `parameters.date_range`.
const List<String> kScheduleDateRangeOptions = <String>[
  'last7_days',
  'last30_days',
  'last365_days',
  'this_month',
  'last_month',
  'this_quarter',
  'last_quarter',
  'this_year',
  'last_year',
  'all_time',
  'custom',
];

// ---------- Remaining cycles ----------

/// The "endless" sentinel the server treats as "no fixed end".
const int kScheduleRemainingCyclesEndless = -1;

/// Inclusive max for the cycle dropdown (matches admin-portal which goes
/// 0..60).
const int kScheduleRemainingCyclesMax = 60;
