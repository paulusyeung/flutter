import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/features/bank_accounts/view_models/bank_account_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// `/settings/bank_accounts/new` and `/settings/bank_accounts/:id/edit`.
///
/// Edit-or-create form for a single BankAccount. The OAuth Connect flow
/// (Yodlee/Nordigen) lives separately; this form is for manual entries
/// and for editing the local mutable fields (name, sync_from, auto_sync)
/// of an existing connection.
class BankAccountEditScreen extends StatelessWidget {
  const BankAccountEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.bankAccounts;

    return SettingsEntityEditScaffold<
      BankAccount,
      BankAccountEditViewModel
    >(
      existingId: existingId,
      backRoute: '/settings/bank_accounts',
      createTitleKey: 'new_bank_account',
      editTitleKey: 'edit_bank_account',
      wireName: 'bank_account',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => BankAccountEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
      ),
      isArchivedOf: (a) => a.archivedAt != null,
      isDeletedOf: (a) => a.isDeleted,
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (context, vm) => [
        if (vm.draft.needsReconnect) _ReconnectBanner(account: vm.draft),
        FormSection(
          title: context.tr('bank_account'),
          children: [
            SettingsTextField(
              initialValue: vm.draft.name,
              labelKey: 'name',
              onChanged: vm.setName,
              errorText: vm.fieldErrorFor('bank_account_name'),
              textInputAction: TextInputAction.next,
              externalSyncKey: vm.original?.id,
            ),
            InDateField(
              value: vm.draft.fromDate?.toDateTime(),
              labelText: context.tr('sync_from'),
              clearable: true,
              onChanged: (dt) => vm.setFromDate(
                dt == null ? null : Date(dt.year, dt.month, dt.day),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('auto_sync')),
              value: vm.draft.autoSync,
              onChanged: vm.setAutoSync,
            ),
          ],
        ),
      ],
    );
  }
}

/// Inline warning rendered above the form when the bank integration's
/// upstream provider has dropped the connection. The Reconnect action is
/// stubbed until the Yodlee/Nordigen OAuth flow lands — the button is
/// disabled with a "Coming soon" tooltip so the affordance is visible
/// without misrepresenting the current capability.
class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner({required this.account});

  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.overdueSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
        border: Border.all(color: tokens.overdue.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.link_off, color: tokens.overdue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('reconnect_bank_account_help'),
              style: TextStyle(color: tokens.ink, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: context.tr('coming_soon'),
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.tr('reconnect')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
