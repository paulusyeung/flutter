import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/group_setting_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// `/settings/group_settings/new` and `/settings/group_settings/:id`.
///
/// Edit-or-create form for a group. Lifecycle, AppBar, and the
/// archive/restore/delete overflow are owned by
/// [SettingsEntityEditScaffold] — this widget just declares the four
/// form fields (name + three cascade-override dropdowns).
class GroupSettingsEditScreen extends StatelessWidget {
  const GroupSettingsEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.groupSettings;

    return SettingsEntityEditScaffold<GroupSetting, GroupSettingEditViewModel>(
      existingId: existingId,
      backRoute: '/settings/group_settings',
      createTitleKey: 'new_group',
      editTitleKey: 'edit_group',
      wireName: 'group',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => GroupSettingEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
        sync: services.sync,
        connectivity: services.connectivity,
      ),
      isArchivedOf: (g) => g.archivedAt != null,
      isDeletedOf: (g) => g.isDeleted,
      // Gated on both `isSaving` (mutually exclusive submits) and `isDirty`
      // (a no-op save would still enqueue an outbox row and bump
      // `updated_at`).
      canSave: (vm) => !vm.isSaving && vm.isDirty,
      bodyBuilder: (context, vm) => [
        FormSection(
          title: context.tr('group'),
          children: [
            SettingsTextField(
              initialValue: vm.draft.name,
              labelKey: 'name',
              onChanged: vm.setName,
              errorText: vm.fieldErrorFor('name'),
              textInputAction: TextInputAction.next,
              externalSyncKey: vm.original?.id,
            ),
            _CurrencyField(vm: vm),
            _LanguageField(vm: vm),
            _CountryField(vm: vm),
          ],
        ),
      ],
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final currencies = statics.currencies.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.currencyId == null
        ? null
        : statics.currency(vm.draft.currencyId!);
    return SearchableDropdownField<Currency>(
      label: context.tr('currency'),
      items: currencies,
      initialValue: current,
      displayString: (c) => '${c.code} — ${c.name}',
      idOf: (c) => c.id,
      onChanged: (c) => vm.setCascadeOverride('currency_id', c?.id),
    );
  }
}

class _LanguageField extends StatelessWidget {
  const _LanguageField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final languages = statics.languages.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.languageId == null
        ? null
        : statics.language(vm.draft.languageId!);
    return SearchableDropdownField<Language>(
      label: context.tr('language'),
      items: languages,
      initialValue: current,
      displayString: (l) => l.name,
      idOf: (l) => l.id,
      onChanged: (l) => vm.setCascadeOverride('language_id', l?.id),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final countries = statics.countries.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.countryId == null
        ? null
        : statics.country(vm.draft.countryId!);
    return SearchableDropdownField<Country>(
      label: context.tr('country'),
      items: countries,
      initialValue: current,
      displayString: (c) => c.name,
      idOf: (c) => c.id,
      onChanged: (c) => vm.setCascadeOverride('country_id', c?.id),
    );
  }
}
