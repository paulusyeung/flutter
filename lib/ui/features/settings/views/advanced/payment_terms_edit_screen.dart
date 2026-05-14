import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/payment_term.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/payment_term_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// `/settings/payment_terms/new` and `/settings/payment_terms/:id`.
///
/// Edit-or-create form for a single PaymentTerm. Lifecycle, AppBar, and
/// the archive/restore/delete overflow are owned by
/// [SettingsEntityEditScaffold] — this widget just declares the two
/// form fields and the [canSave] gate.
class PaymentTermsEditScreen extends StatelessWidget {
  const PaymentTermsEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.paymentTerms;

    return SettingsEntityEditScaffold<PaymentTerm, PaymentTermEditViewModel>(
      existingId: existingId,
      backRoute: '/settings/payment_terms',
      createTitleKey: 'new_payment_term',
      editTitleKey: 'edit_payment_term',
      wireName: 'payment_term',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => PaymentTermEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
      ),
      isArchivedOf: (t) => t.archivedAt != null,
      isDeletedOf: (t) => t.isDeleted,
      // Block Save when num_days is zero — a zero-day term is meaningless
      // (server would reject it) and would render as "0 days" everywhere.
      canSave: (vm) =>
          !vm.isSaving &&
          vm.isDirty &&
          vm.draft.name.trim().isNotEmpty &&
          vm.draft.numDays > 0,
      bodyBuilder: (context, vm) => [
        FormSection(
          title: context.tr('payment_term'),
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
              initialValue: vm.draft.numDays > 0
                  ? vm.draft.numDays.toString()
                  : '',
              labelKey: 'number_of_days',
              onChanged: (v) => vm.setNumDays(int.tryParse(v) ?? 0),
              errorText: vm.fieldErrorFor('num_days'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              externalSyncKey: vm.original?.id,
            ),
          ],
        ),
      ],
    );
  }
}
