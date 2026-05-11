import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

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
              OverridableTextField(
                label: context.tr('name'),
                apiKey: 'name',
                read: (vm) => vm.settings.name,
                write: (vm, v) => vm.updateSettings((s) => s.copyWith(name: v)),
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('id_number'),
                apiKey: 'id_number',
                enabled: !legalEntityBound,
                read: (vm) => vm.settings.idNumber,
                write: (vm, v) =>
                    vm.updateSettings((s) => s.copyWith(idNumber: v)),
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('vat_number'),
                apiKey: 'vat_number',
                enabled: !legalEntityBound,
                read: (vm) => vm.settings.vatNumber,
                write: (vm, v) =>
                    vm.updateSettings((s) => s.copyWith(vatNumber: v)),
              ),
              const SizedBox(height: InSpacing.lg),
              _ClassificationField(),
              if (isSwiss) ...[
                const SizedBox(height: InSpacing.lg),
                OverridableTextField(
                  label: context.tr('qr_iban'),
                  apiKey: 'qr_iban',
                  read: (vm) => vm.settings.qrIban,
                  write: (vm, v) =>
                      vm.updateSettings((s) => s.copyWith(qrIban: v)),
                ),
                const SizedBox(height: InSpacing.lg),
                OverridableTextField(
                  label: context.tr('besr_id'),
                  apiKey: 'besr_id',
                  read: (vm) => vm.settings.besrId,
                  write: (vm, v) =>
                      vm.updateSettings((s) => s.copyWith(besrId: v)),
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
                read: (vm) => vm.settings.website,
                write: (vm, v) =>
                    vm.updateSettings((s) => s.copyWith(website: v)),
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('email'),
                apiKey: 'email',
                keyboardType: TextInputType.emailAddress,
                read: (vm) => vm.settings.email,
                write: (vm, v) =>
                    vm.updateSettings((s) => s.copyWith(email: v)),
              ),
              const SizedBox(height: InSpacing.lg),
              OverridableTextField(
                label: context.tr('phone'),
                apiKey: 'phone',
                keyboardType: TextInputType.phone,
                read: (vm) => vm.settings.phone,
                write: (vm, v) =>
                    vm.updateSettings((s) => s.copyWith(phone: v)),
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
      widgets.add(
        OverridableTextField(
          label: label,
          apiKey: 'custom_value$i',
          read: (vm) => switch (i) {
            1 => vm.settings.customValue1,
            2 => vm.settings.customValue2,
            3 => vm.settings.customValue3,
            _ => vm.settings.customValue4,
          },
          write: (vm, v) => vm.updateSettings(
            (s) => switch (i) {
              1 => s.copyWith(customValue1: v),
              2 => s.copyWith(customValue2: v),
              3 => s.copyWith(customValue3: v),
              _ => s.copyWith(customValue4: v),
            },
          ),
        ),
      );
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
      decoration: InputDecoration(
        labelText: context.tr('classification'),
        border: const OutlineInputBorder(),
      ),
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

class _SizeField extends StatefulWidget {
  @override
  State<_SizeField> createState() => _SizeFieldState();
}

class _SizeFieldState extends State<_SizeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CompanyDetailsViewModel>();
    _controller = TextEditingController(text: vm.draft?.sizeId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final vmValue = vm.draft?.sizeId ?? '';
    if (_controller.text != vmValue) {
      _controller.value = TextEditingValue(
        text: vmValue,
        selection: TextSelection.collapsed(offset: vmValue.length),
      );
    }
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr('size'),
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => vm.updateCompany((c) => c.copyWith(sizeId: v)),
    );
  }
}

class _IndustryField extends StatefulWidget {
  @override
  State<_IndustryField> createState() => _IndustryFieldState();
}

class _IndustryFieldState extends State<_IndustryField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CompanyDetailsViewModel>();
    _controller = TextEditingController(text: vm.draft?.industryId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final vmValue = vm.draft?.industryId ?? '';
    if (_controller.text != vmValue) {
      _controller.value = TextEditingValue(
        text: vmValue,
        selection: TextSelection.collapsed(offset: vmValue.length),
      );
    }
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr('industry'),
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => vm.updateCompany((c) => c.copyWith(industryId: v)),
    );
  }
}
