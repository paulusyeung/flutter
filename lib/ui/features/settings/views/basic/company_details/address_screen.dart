import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// "Address" tab — every field on the company's mailing address. All are
/// settings keys, so all support the override-checkbox flow.
class CompanyDetailsAddressScreen extends StatelessWidget {
  const CompanyDetailsAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    if (vm.draft == null) return const SizedBox.shrink();

    return SettingsFormShell(
      child: FormSection(
        title: context.tr('address'),
        children: [
          OverridableTextField(
            label: context.tr('address1'),
            apiKey: 'address1',
            read: (vm) => vm.settings.address1,
            write: (vm, v) => vm.updateSettings((s) => s.copyWith(address1: v)),
          ),
          const SizedBox(height: InSpacing.lg),
          OverridableTextField(
            label: context.tr('address2'),
            apiKey: 'address2',
            read: (vm) => vm.settings.address2,
            write: (vm, v) => vm.updateSettings((s) => s.copyWith(address2: v)),
          ),
          const SizedBox(height: InSpacing.lg),
          OverridableTextField(
            label: context.tr('city'),
            apiKey: 'city',
            read: (vm) => vm.settings.city,
            write: (vm, v) => vm.updateSettings((s) => s.copyWith(city: v)),
          ),
          const SizedBox(height: InSpacing.lg),
          OverridableTextField(
            label: context.tr('state'),
            apiKey: 'state',
            read: (vm) => vm.settings.state,
            write: (vm, v) => vm.updateSettings((s) => s.copyWith(state: v)),
          ),
          const SizedBox(height: InSpacing.lg),
          OverridableTextField(
            label: context.tr('postal_code'),
            apiKey: 'postal_code',
            read: (vm) => vm.settings.postalCode,
            write: (vm, v) =>
                vm.updateSettings((s) => s.copyWith(postalCode: v)),
          ),
          const SizedBox(height: InSpacing.lg),
          _CountryField(),
        ],
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final statics = context.read<Services>().statics;
    final countries = statics.countries.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = statics.country(vm.settings.countryId ?? '');
    return SearchableDropdownField<Country>(
      label: context.tr('country'),
      items: countries,
      initialValue: current,
      displayString: (c) => c.name,
      idOf: (c) => c.id,
      onChanged: (c) =>
          vm.updateSettings((s) => s.copyWith(countryId: c?.id ?? '')),
    );
  }
}
