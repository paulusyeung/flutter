import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/localization_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Localization settings page. Cascade-aware: at company scope every field
/// is editable; at client scope each field renders inside an override
/// checkbox so the user can opt in to overriding the inherited value.
///
/// VM-picking, lifecycle, and company-switch handling are owned by
/// [CascadeSettingsScaffold] — this widget just declares which company-VM
/// to use and renders the form body.
class LocalizationScreen extends StatelessWidget {
  const LocalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return CascadeSettingsScaffold(
      titleKey: 'localization',
      companyVmFactory: ({required repo, required companyId}) =>
          LocalizationViewModel(repo: repo, companyId: companyId),
      body: _LocalizationBody(statics: services.statics),
    );
  }
}

class _LocalizationBody extends StatelessWidget {
  const _LocalizationBody({required this.statics});

  final StaticsRepository statics;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final currencies = statics.currencies.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final languages = statics.languages.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final countries = statics.countries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
            OverridableSearchableDropdownField<Country>(
              label: context.tr('country'),
              apiKey: 'country_id',
              value: host.settings.countryId,
              items: countries,
              displayString: (c) => c.name,
              idOf: (c) => c.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(countryId: v)),
            ),
          ],
        ),
        FormSection(
          title: context.tr('defaults'),
          children: [
            OverridableTextField(
              label: context.tr('payment_terms'),
              apiKey: 'payment_terms',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ],
    );
  }
}
