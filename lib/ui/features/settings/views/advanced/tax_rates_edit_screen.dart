import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/tax_rate.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/tax_rate_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// `/settings/tax_rates/new` and `/settings/tax_rates/:id`.
///
/// Edit-or-create form for a single TaxRate. Lifecycle, AppBar, and the
/// archive/restore/delete overflow are owned by
/// [SettingsEntityEditScaffold] — this widget just declares the two form
/// fields and the [canSave] gate. Mirrors [PaymentTermsEditScreen].
class TaxRatesEditScreen extends StatelessWidget {
  const TaxRatesEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.taxRates;

    return SettingsEntityEditScaffold<TaxRate, TaxRateEditViewModel>(
      existingId: existingId,
      backRoute: '/settings/tax_rates',
      createTitleKey: 'new_tax_rate',
      editTitleKey: 'edit_tax_rate',
      wireName: 'tax_rate',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => TaxRateEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
        sync: services.sync,
        connectivity: services.connectivity,
      ),
      isArchivedOf: (t) => t.archivedAt != null,
      isDeletedOf: (t) => t.isDeleted,
      // A nameless rate would render as its UUID in the rate pickers; the
      // percentage itself may legitimately be 0 (tax-exempt rate).
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (context, vm) => [
        FormSection(
          title: context.tr('tax_rate'),
          children: [
            SettingsTextField(
              initialValue: vm.draft.name,
              labelKey: 'name',
              onChanged: vm.setName,
              errorText: vm.fieldErrorFor('name'),
              textInputAction: TextInputAction.next,
              externalSyncKey: vm.original?.id,
            ),
            SettingsTextField(
              initialValue: vm.draft.rate != 0 ? vm.draft.rate.toString() : '',
              labelKey: 'rate',
              onChanged: (v) => vm.setRate(double.tryParse(v) ?? 0),
              errorText: vm.fieldErrorFor('rate'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              externalSyncKey: vm.original?.id,
            ),
          ],
        ),
      ],
    );
  }
}
