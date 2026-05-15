import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/template_options.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_currency_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/utils/formatting.dart';

/// Reminder-rule fields below the body editor. The shape differs per
/// reminder kind:
///
/// * `reminder1` / `reminder2` / `reminder3` / `quote_reminder1` — enable
///   toggle + days + schedule + late-fee amount + late-fee percent.
/// * `reminder_endless` — enable toggle + frequency dropdown only. The
///   `late_fee_endless_amount` / `late_fee_endless_percent` fields exist
///   on `CompanySettings` but neither v1 nor React surfaces them here, so
///   they're intentionally omitted.
class ReminderRuleSection extends StatelessWidget {
  const ReminderRuleSection({
    super.key,
    required this.template,
    required this.formatter,
    required this.currencyId,
  });

  final TemplateOption template;
  final Formatter formatter;
  final String currencyId;

  @override
  Widget build(BuildContext context) {
    if (template.key == 'reminder_endless') {
      return const _EndlessRuleSection();
    }
    return _ScheduledRuleSection(
      template: template,
      formatter: formatter,
      currencyId: currencyId,
    );
  }
}

class _ScheduledRuleSection extends StatelessWidget {
  const _ScheduledRuleSection({
    required this.template,
    required this.formatter,
    required this.currencyId,
  });

  final TemplateOption template;
  final Formatter formatter;
  final String currencyId;

  bool get _isQuote => template.key == 'quote_reminder1';
  String get _enableKey => _isQuote ? 'enable_quote_reminder1' : 'enable_${template.key}';
  String get _daysKey =>
      _isQuote ? 'quote_num_days_reminder1' : 'num_days_${template.key}';
  String get _scheduleKey =>
      _isQuote ? 'quote_schedule_reminder1' : 'schedule_${template.key}';
  String get _amountKey {
    if (_isQuote) return 'quote_late_fee_amount1';
    final n = template.key.substring(template.key.length - 1);
    return 'late_fee_amount$n';
  }

  String get _percentKey {
    if (_isQuote) return 'quote_late_fee_percent1';
    final n = template.key.substring(template.key.length - 1);
    return 'late_fee_percent$n';
  }

  String get _defaultSchedule => _isQuote ? 'after_quote_date' : 'after_invoice_date';

  List<DropdownMenuItem<String>> _scheduleItems(BuildContext context) {
    if (_isQuote) {
      return <DropdownMenuItem<String>>[
        DropdownMenuItem(
          value: 'after_quote_date',
          child: Text(context.tr('after_quote_date')),
        ),
        DropdownMenuItem(
          value: 'before_valid_until_date',
          child: Text(context.tr('before_valid_until_date')),
        ),
        DropdownMenuItem(
          value: 'after_valid_until_date',
          child: Text(context.tr('after_valid_until_date')),
        ),
      ];
    }
    return <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'after_invoice_date',
        child: Text(context.tr('after_invoice_date')),
      ),
      DropdownMenuItem(
        value: 'before_due_date',
        child: Text(context.tr('before_due_date')),
      ),
      DropdownMenuItem(
        value: 'after_due_date',
        child: Text(context.tr('after_due_date')),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final schedule = _readSchedule(host.settings);

    return FormSection(
      title: context.tr('reminders'),
      children: [
        _SendEmailField(apiKey: _enableKey, onEnable: () => _onEnable(host)),
        OverridableTextField(
          label: context.tr('days'),
          apiKey: _daysKey,
          keyboardType: TextInputType.number,
        ),
        OverridableDropdownField<String>(
          label: context.tr('schedule'),
          apiKey: _scheduleKey,
          value: schedule,
          items: _scheduleItems(context),
          onChanged: (v) =>
              host.updateSettings((s) => _writeSchedule(s, v)),
        ),
        OverridableCurrencyField(
          label: context.tr('late_fee_amount'),
          apiKey: _amountKey,
          formatter: formatter,
          currencyId: currencyId,
        ),
        OverridableTextField(
          label: context.tr('late_fee_percent'),
          apiKey: _percentKey,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  String? _readSchedule(CompanySettings s) {
    return _isQuote ? s.quoteScheduleReminder1 : _readScheduleByKey(s);
  }

  String? _readScheduleByKey(CompanySettings s) {
    switch (template.key) {
      case 'reminder1':
        return s.scheduleReminder1;
      case 'reminder2':
        return s.scheduleReminder2;
      case 'reminder3':
        return s.scheduleReminder3;
      default:
        return null;
    }
  }

  CompanySettings _writeSchedule(CompanySettings s, String? v) {
    if (_isQuote) return s.copyWith(quoteScheduleReminder1: v);
    switch (template.key) {
      case 'reminder1':
        return s.copyWith(scheduleReminder1: v);
      case 'reminder2':
        return s.copyWith(scheduleReminder2: v);
      case 'reminder3':
        return s.copyWith(scheduleReminder3: v);
      default:
        return s;
    }
  }

  /// Auto-default the schedule on first enable. React's
  /// `TemplatesAndReminders.tsx:242` forces `'disabled'` as a sentinel for
  /// the off state; we have a separate enable bool, so an empty schedule
  /// when the user flips the toggle on is a bug-shaped default. Seed it
  /// with `after_invoice_date` (or `after_quote_date`) so the rule does
  /// something meaningful on first save.
  void _onEnable(SettingsDraftHost host) {
    final current = _readSchedule(host.settings);
    if (current == null || current.isEmpty) {
      host.updateSettings((s) => _writeSchedule(s, _defaultSchedule));
    }
  }
}

class _EndlessRuleSection extends StatelessWidget {
  const _EndlessRuleSection();

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    return FormSection(
      title: context.tr('reminders'),
      children: [
        const OverridableSwitchField(
          label: 'Send Email',
          apiKey: 'enable_reminder_endless',
        ),
        OverridableDropdownField<String>(
          label: context.tr('frequency'),
          apiKey: 'endless_reminder_frequency_id',
          value: host.settings.endlessReminderFrequencyId == '0'
              ? null
              : host.settings.endlessReminderFrequencyId,
          items: [
            for (final entry in kEndlessReminderFrequencies)
              DropdownMenuItem<String>(
                value: entry.$1,
                child: Text(context.tr(entry.$2)),
              ),
          ],
          onChanged: (v) =>
              host.updateSettings((s) => s.copyWith(endlessReminderFrequencyId: v)),
        ),
      ],
    );
  }
}

/// `OverridableSwitchField` whose `onChanged` first calls [onEnable] when
/// the user flips it on. Reuses the underlying widget for visual + cascade
/// parity; the side-effect hook gives us a place to auto-seed the
/// dependent schedule field.
class _SendEmailField extends StatelessWidget {
  const _SendEmailField({required this.apiKey, required this.onEnable});

  final String apiKey;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    return _SwitchWrapper(
      apiKey: apiKey,
      label: context.tr('send_email'),
      onTurnedOn: () {
        // Allow the underlying switch to commit its update first, then
        // seed any dependent default. addPostFrameCallback dodges the
        // notifyListeners → setState reentry guard.
        WidgetsBinding.instance.addPostFrameCallback((_) => onEnable());
      },
      host: host,
    );
  }
}

class _SwitchWrapper extends StatelessWidget {
  const _SwitchWrapper({
    required this.apiKey,
    required this.label,
    required this.host,
    required this.onTurnedOn,
  });

  final String apiKey;
  final String label;
  final SettingsDraftHost host;
  final VoidCallback onTurnedOn;

  @override
  Widget build(BuildContext context) {
    // Listen to the same source as OverridableSwitchField so we know when
    // the toggle flipped on. Cheaper than subclassing the widget.
    return _OnEnableListener(
      apiKey: apiKey,
      onEnable: onTurnedOn,
      child: OverridableSwitchField(label: label, apiKey: apiKey),
    );
  }
}

class _OnEnableListener extends StatefulWidget {
  const _OnEnableListener({
    required this.apiKey,
    required this.onEnable,
    required this.child,
  });

  final String apiKey;
  final VoidCallback onEnable;
  final Widget child;

  @override
  State<_OnEnableListener> createState() => _OnEnableListenerState();
}

class _OnEnableListenerState extends State<_OnEnableListener> {
  bool? _last;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final raw = host.settings.toJson()[widget.apiKey];
    final bool value = raw == true || raw == 'true';
    if (_last != null && _last == false && value) {
      // false → true transition: fire the side-effect.
      widget.onEnable();
    }
    _last = value;
    return widget.child;
  }
}
