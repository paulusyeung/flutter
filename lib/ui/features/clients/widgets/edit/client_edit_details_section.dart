import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Details" card on the client edit screen — name + identifiers + the four
/// custom value fields. Stretches to whichever column it lives in.
class ClientEditDetailsSection extends StatelessWidget {
  const ClientEditDetailsSection({super.key, required this.vm});

  final ClientEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;
    return DashboardCardShell(
      title: context.tr('details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientEditField(
            label: context.tr('name'),
            initial: draft.name,
            onChanged: vm.setName,
            autofocus: vm.isCreate,
          ),
          ClientEditField(
            label: context.tr('number'),
            initial: draft.number,
            onChanged: vm.setNumber,
          ),
          ClientEditField(
            label: context.tr('id_number'),
            initial: draft.idNumber,
            onChanged: vm.setIdNumber,
          ),
          ClientEditField(
            label: context.tr('vat_number'),
            initial: draft.vatNumber,
            onChanged: vm.setVatNumber,
          ),
          ClientEditField(
            label: context.tr('website'),
            initial: draft.website,
            onChanged: vm.setWebsite,
            keyboardType: TextInputType.url,
          ),
          ClientEditField(
            label: context.tr('phone'),
            initial: draft.phone,
            onChanged: vm.setPhone,
            keyboardType: TextInputType.phone,
          ),
          ClientEditField(
            label: context.tr('custom_value1'),
            initial: draft.customValue1,
            onChanged: vm.setCustomValue1,
          ),
          ClientEditField(
            label: context.tr('custom_value2'),
            initial: draft.customValue2,
            onChanged: vm.setCustomValue2,
          ),
          ClientEditField(
            label: context.tr('custom_value3'),
            initial: draft.customValue3,
            onChanged: vm.setCustomValue3,
          ),
          ClientEditField(
            label: context.tr('custom_value4'),
            initial: draft.customValue4,
            onChanged: vm.setCustomValue4,
          ),
        ],
      ),
    );
  }
}
