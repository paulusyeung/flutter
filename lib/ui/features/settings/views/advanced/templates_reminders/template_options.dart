import 'package:admin/data/models/domain/enabled_modules.dart';

/// One entry in the template-type dropdown on Settings → Templates &
/// Reminders. The full ordered enumeration matches the picker layout in
/// v1 (`admin-portal/lib/ui/settings/templates_and_reminders.dart:374-397`)
/// + React (`react/.../TemplatesAndReminders.tsx:386-398`) and the seven
/// keys that already exist on `CompanySettings`.
///
/// `payment_failed` is intentionally included even though React omits it —
/// the `email_subject_payment_failed` / `email_template_payment_failed`
/// fields are persisted on the company so not surfacing them would leave
/// an inaccessible setting.
class TemplateOption {
  const TemplateOption({
    required this.key,
    required this.labelKey,
    this.moduleGate,
  });

  /// Template id used as the suffix of the wire keys
  /// (`email_subject_${key}` / `email_template_${key}`), with one
  /// exception: `quote_reminder1` uses `email_quote_subject_reminder1` /
  /// `email_quote_template_reminder1` (`quote_` infix), so the screen
  /// looks up the subject/body keys through [subjectKey] / [templateKey]
  /// instead of templating them inline.
  final String key;

  /// Localization key for the user-visible name.
  final String labelKey;

  /// When non-null, the option is filtered out unless the company's
  /// `enabled_modules` bitmask carries the module's flag.
  final EnabledModule? moduleGate;

  /// Wire name for the subject field on `CompanySettings`.
  String get subjectKey => key == 'quote_reminder1'
      ? 'email_quote_subject_reminder1'
      : 'email_subject_$key';

  /// Wire name for the body field on `CompanySettings`.
  String get templateKey => key == 'quote_reminder1'
      ? 'email_quote_template_reminder1'
      : 'email_template_$key';

  /// True when this template is a reminder rule (renders the
  /// enable/days/schedule/late-fee section).
  bool get isReminder => const {
        'reminder1',
        'reminder2',
        'reminder3',
        'reminder_endless',
        'quote_reminder1',
      }.contains(key);
}

const List<TemplateOption> kTemplateOptions = <TemplateOption>[
  TemplateOption(key: 'invoice', labelKey: 'invoice'),
  TemplateOption(
    key: 'quote',
    labelKey: 'quote',
    moduleGate: EnabledModule.quotes,
  ),
  TemplateOption(key: 'payment', labelKey: 'payment'),
  TemplateOption(key: 'payment_partial', labelKey: 'payment_partial'),
  TemplateOption(key: 'payment_failed', labelKey: 'payment_failed'),
  TemplateOption(
    key: 'credit',
    labelKey: 'credit',
    moduleGate: EnabledModule.credits,
  ),
  TemplateOption(
    key: 'purchase_order',
    labelKey: 'purchase_order',
    moduleGate: EnabledModule.purchaseOrders,
  ),
  TemplateOption(key: 'statement', labelKey: 'statement'),
  TemplateOption(key: 'reminder1', labelKey: 'first_reminder'),
  TemplateOption(key: 'reminder2', labelKey: 'second_reminder'),
  TemplateOption(key: 'reminder3', labelKey: 'third_reminder'),
  TemplateOption(key: 'reminder_endless', labelKey: 'endless_reminder'),
  TemplateOption(
    key: 'quote_reminder1',
    labelKey: 'quote_reminder1',
    moduleGate: EnabledModule.quotes,
  ),
  TemplateOption(key: 'custom1', labelKey: 'first_custom'),
  TemplateOption(key: 'custom2', labelKey: 'second_custom'),
  TemplateOption(key: 'custom3', labelKey: 'third_custom'),
];

/// Filter [kTemplateOptions] by the company's enabled-modules bitmask.
List<TemplateOption> visibleTemplateOptions(int enabledModules) {
  return kTemplateOptions
      .where((o) =>
          o.moduleGate == null ||
          isModuleEnabled(enabledModules, o.moduleGate!))
      .toList(growable: false);
}

/// `endless_reminder_frequency_id` options. Mirrors `kFrequencies` from
/// admin-portal `lib/constants.dart:1234` exactly — twelve entries, no
/// "never" sentinel (the disable state is `enable_reminder_endless=false`).
const List<(String, String)> kEndlessReminderFrequencies = <(String, String)>[
  ('1', 'freq_daily'),
  ('2', 'freq_weekly'),
  ('3', 'freq_two_weeks'),
  ('4', 'freq_four_weeks'),
  ('5', 'freq_monthly'),
  ('6', 'freq_two_months'),
  ('7', 'freq_three_months'),
  ('8', 'freq_four_months'),
  ('9', 'freq_six_months'),
  ('10', 'freq_annually'),
  ('11', 'freq_two_years'),
  ('12', 'freq_three_years'),
];
