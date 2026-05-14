import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/localization_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Localization settings page. Renders the same form at both company and
/// client scope — at client scope each field is wrapped in
/// [OverridableField] with a checkbox; at company scope the wrapper hides
/// itself and the field renders unwrapped (see `OverridableField.build`).
///
/// The VM is picked at construction time based on
/// [SettingsLevelController.level]:
/// * company → [LocalizationViewModel] (subclass of
///   [SettingsDraftViewModel]) which loads + saves via the
///   [CompanyRepository].
/// * client → [ClientSettingsDraftViewModel] which loads the company
///   defaults + per-client overrides and saves through
///   [ClientRepository] (outbox-aware).
class LocalizationScreen extends StatefulWidget {
  const LocalizationScreen({super.key});

  @override
  State<LocalizationScreen> createState() => _LocalizationScreenState();
}

class _LocalizationScreenState extends State<LocalizationScreen> {
  SettingsDraftHost? _vm;
  late final Services _services;
  late final String _companyId;
  late final SettingsLevel _level;
  late final String? _clientId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    final scope = _services.settingsLevel;
    _level = scope.level;
    _clientId = scope.targetId;
    final vm = _buildVm();
    _vm = vm;
    // Kick the initial load on both VMs the same way.
    if (vm is LocalizationViewModel) {
      vm.load();
    } else if (vm is ClientSettingsDraftViewModel) {
      vm.load();
    }
  }

  SettingsDraftHost _buildVm() {
    if (_level == SettingsLevel.client && _clientId != null) {
      return ClientSettingsDraftViewModel(
        repo: _services.clients,
        db: _services.db,
        companyId: _companyId,
        clientId: _clientId,
      );
    }
    return LocalizationViewModel(
      repo: _services.company,
      companyId: _companyId,
    );
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const SizedBox.shrink();
    return SettingsPageScaffold<SettingsDraftHost>(
      titleKey: 'localization',
      viewModel: vm,
      body: _LocalizationBody(statics: _services.statics),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              const SizedBox(height: InSpacing.lg),
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
              const SizedBox(height: InSpacing.lg),
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
      ),
    );
  }
}
