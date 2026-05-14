import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/env.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/data/models/value/timezone.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Localization "Settings" tab — field labels surfaced by the in-app search.
/// Combined with `kLocalizationCustomLabelsSearchKeys` in
/// `settings_search_catalog.dart` under the `localization` section.
const kLocalizationSettingsSearchKeys = <String>[
  'currency',
  'currency_format',
  'language',
  'timezone',
  'date_format',
  'military_time',
  'rappen_rounding',
  'decimal_comma',
  'first_month_of_the_year',
];

/// Settings tab body. Mounted by `LocalizationShell` inside
/// `CascadeTabbedSettingsShell` — the shell owns the cascade VM and provides
/// it via Provider.
///
/// Country lives on Company Details > Address; Payment Terms belongs on
/// Workflow Settings — both are intentionally absent here to match the React
/// app and admin-portal.
///
/// `decimal_comma` and `first_month_of_the_year` are global format choices —
/// they're hidden at group/client scope (the cascade override doesn't make
/// sense per-client). Matches the React app and admin-portal.
class LocalizationSettingsBody extends StatelessWidget {
  const LocalizationSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();

    final currencies = statics.currencies.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final languages = statics.languages.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final timezones = statics.timezones.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final dateFormats = statics.dateFormats.values.toList();

    final isCompanyScope = scope.isCompany;
    // Demo accounts can't change the UI language — would conflict with the
    // hosted demo's tour scripting. React reads this off runtime auth state
    // (`isDemo()`); we only have a build-time flag today (`--dart-define=
    // IN_DEMO_MODE=true`), so dev builds running against demo.invoiceninja.com
    // skip the gate. TODO: swap to a runtime auth-session flag once one exists.
    final showLanguage = !Env.demoMode;

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('region'),
          children: [
            OverridableSearchableDropdownField<Currency>(
              label: context.tr('currency'),
              apiKey: 'currency_id',
              value: host.settings.currencyId,
              items: currencies,
              displayString: (c) => '${c.code} — ${c.name}',
              idOf: (c) => c.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(currencyId: v)),
            ),
            OverridableSwitchField(
              label: context.tr('currency_format'),
              apiKey: 'show_currency_code',
              subtitle: context.tr('show_currency_code'),
            ),
            if (showLanguage)
              OverridableSearchableDropdownField<Language>(
                label: context.tr('language'),
                apiKey: 'language_id',
                value: host.settings.languageId,
                items: languages,
                displayString: (l) => l.name,
                idOf: (l) => l.id,
                onChanged: (v) =>
                    host.updateSettings((s) => s.copyWith(languageId: v)),
              ),
            OverridableSearchableDropdownField<Timezone>(
              label: context.tr('timezone'),
              apiKey: 'timezone_id',
              value: host.settings.timezoneId,
              items: timezones,
              displayString: (t) => t.name,
              idOf: (t) => t.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(timezoneId: v)),
            ),
            OverridableSearchableDropdownField<DatetimeFormat>(
              label: context.tr('date_format'),
              apiKey: 'date_format_id',
              value: host.settings.dateFormatId,
              items: dateFormats,
              displayString: _dateFormatPreview,
              idOf: (f) => f.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(dateFormatId: v)),
            ),
          ],
        ),
        FormSection(
          title: context.tr('format'),
          children: [
            OverridableSwitchField(
              label: context.tr('military_time'),
              apiKey: 'military_time',
            ),
            OverridableSwitchField(
              label: context.tr('rappen_rounding'),
              apiKey: 'enable_rappen_rounding',
            ),
            if (isCompanyScope) ...[
              OverridableSwitchField(
                label: context.tr('decimal_comma'),
                apiKey: 'use_comma_as_decimal_place',
                subtitle: context.tr('use_comma_as_decimal_place'),
              ),
              OverridableDropdownField<String>(
                label: context.tr('first_month_of_the_year'),
                apiKey: 'first_month_of_year',
                value: host.settings.firstMonthOfYear,
                items: _monthOptions(context),
                onChanged: (v) =>
                    host.updateSettings((s) => s.copyWith(firstMonthOfYear: v)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _dateFormatPreview(DatetimeFormat f) {
    if (f.format.isEmpty) return f.id;
    try {
      return DateFormat(f.format).format(DateTime.now());
    } catch (_) {
      return f.format;
    }
  }

  List<DropdownMenuItem<String>> _monthOptions(BuildContext context) {
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return [
      for (var i = 0; i < months.length; i++)
        DropdownMenuItem<String>(
          value: '${i + 1}',
          child: Text(context.tr(months[i])),
        ),
    ];
  }
}
