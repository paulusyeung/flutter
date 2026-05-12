import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/industry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by this tab. Aggregated into
/// `kSettingsSearchCatalog['company_details']` so the in-app search surfaces
/// these fields. Keep in sync when you add or remove a field below — the
/// `search_catalog_consistency_test` verifies every key here appears as a
/// `context.tr('…')` or `apiKey: '…'` reference in this file.
const kCompanyDetailsDetailsSearchKeys = <String>[
  'name',
  'id_number',
  'vat_number',
  'qr_iban',
  'besr_id',
  'website',
  'email',
  'phone',
  'classification',
  'size',
  'industry',
];

/// "Details" tab of the Company Details settings page. Holds the identity +
/// brand fields that live on `company.settings.*` (name, id_number, etc.)
/// plus the two truly-company-level fields (`size_id`, `industry_id`) that
/// don't pass through the cascade.
///
/// The shell ([CompanyDetailsShell]) owns the AppBar + Save button; this
/// widget is just the form body. Fields are grouped under section headings
/// (Identification / Contact / Business / Custom Fields) so the long form
/// stays scannable.
class CompanyDetailsScreen extends StatelessWidget {
  const CompanyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final draft = vm.draft;
    if (draft == null) return const SizedBox.shrink();
    // Legal entity id != 0 means an Invoice Ninja legal entity is bound
    // server-side and the id_number / vat_number are managed there.
    final legalEntityBound = draft.legalEntityId != 0;
    final isSwiss = draft.settings.countryId == '756';

    final customFieldEditors = _customFieldEditors(context, vm);

    return SettingsFormShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSection(
            title: context.tr('identification'),
            children: [
              OverridableTextField(label: context.tr('name'), apiKey: 'name'),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('id_number'),
                apiKey: 'id_number',
                enabled: !legalEntityBound,
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('vat_number'),
                apiKey: 'vat_number',
                enabled: !legalEntityBound,
              ),
              const SizedBox(height: InSpacing.lg),
              _ClassificationField(),
              if (isSwiss) ...[
                const SizedBox(height: InSpacing.lg),
                OverridableTextField(
                  label: context.tr('qr_iban'),
                  apiKey: 'qr_iban',
                ),
                const SizedBox(height: InSpacing.lg),
                OverridableTextField(
                  label: context.tr('besr_id'),
                  apiKey: 'besr_id',
                ),
              ],
            ],
          ),
          FormSection(
            title: context.tr('contact'),
            children: [
              OverridableTextField(
                label: context.tr('website'),
                apiKey: 'website',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('email'),
                apiKey: 'email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('phone'),
                apiKey: 'phone',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          // size_id and industry_id are truly company-level — they don't pass
          // through the settings cascade, so no PropertyCheckbox wrapper.
          FormSection(
            title: context.tr('business'),
            children: [
              _SizeField(),
              const SizedBox(height: InSpacing.lg),
              _IndustryField(),
            ],
          ),
          if (customFieldEditors.isNotEmpty)
            FormSection(
              title: context.tr('custom_fields'),
              children: customFieldEditors,
            ),
        ],
      ),
    );
  }

  List<Widget> _customFieldEditors(
    BuildContext context,
    CompanyDetailsViewModel vm,
  ) {
    final widgets = <Widget>[];
    for (var i = 1; i <= 4; i++) {
      final key = 'company$i';
      final def = vm.draft?.customFields[key];
      if (def == null || def.isEmpty) continue;
      final label = def.split('|').first;
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: InSpacing.lg));
      }
      widgets.add(OverridableTextField(label: label, apiKey: 'custom_value$i'));
    }
    return widgets;
  }
}

class _ClassificationField extends StatelessWidget {
  static const _options = [
    'individual',
    'business',
    'company',
    'partnership',
    'trust',
    'charity',
    'government',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: context.tr('classification')),
      initialValue: _options.contains(vm.settings.classification)
          ? vm.settings.classification
          : null,
      items: [
        for (final v in _options)
          DropdownMenuItem(value: v, child: Text(context.tr(v))),
      ],
      onChanged: (v) =>
          vm.updateSettings((s) => s.copyWith(classification: v ?? '')),
    );
  }
}

class _SizeField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final statics = context.read<Services>().statics;
    // Size bands are short numeric ranges ("1 - 3", "4 - 10", …) — sort by
    // numeric id so they render in the natural small→large order.
    final sizes = statics.sizes.values.toList()
      ..sort((a, b) => (int.tryParse(a.id) ?? 0) - (int.tryParse(b.id) ?? 0));
    final current = vm.draft?.sizeId ?? '';
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: context.tr('size')),
      initialValue: sizes.any((s) => s.id == current) ? current : null,
      disabledHint: sizes.isEmpty ? Text(context.tr('loading')) : null,
      items: [
        for (final s in sizes)
          DropdownMenuItem(value: s.id, child: Text(s.name)),
      ],
      onChanged: (v) => vm.updateCompany((c) => c.copyWith(sizeId: v ?? '')),
    );
  }
}

class _IndustryField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final statics = context.read<Services>().statics;
    final industries = statics.industries.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = industries
        .where((i) => i.id == (vm.draft?.industryId ?? ''))
        .firstOrNull;
    return SearchableDropdownField<Industry>(
      label: context.tr('industry'),
      items: industries,
      initialValue: current,
      displayString: (i) => i.name,
      idOf: (i) => i.id,
      onChanged: (i) =>
          vm.updateCompany((c) => c.copyWith(industryId: i?.id ?? '')),
    );
  }
}
