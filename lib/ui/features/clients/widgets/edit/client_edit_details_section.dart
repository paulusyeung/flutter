import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_field_pair.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Details" card on the client edit screen — name + identifiers + the four
/// custom value fields. On wide widths fields pair side-by-side; on narrow
/// they stack. Custom value fields stay collapsed by default (they're
/// usually company-renamed and irrelevant when blank); they auto-expand for
/// existing clients that already have any custom value set.
class ClientEditDetailsSection extends StatefulWidget {
  const ClientEditDetailsSection({super.key, required this.vm});

  final ClientEditViewModel vm;

  @override
  State<ClientEditDetailsSection> createState() =>
      _ClientEditDetailsSectionState();
}

class _ClientEditDetailsSectionState extends State<ClientEditDetailsSection> {
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand if any of the four custom values already carries data.
    // Keeps existing clients from "hiding" data behind a toggle the user
    // didn't expect.
    final d = widget.vm.draft;
    if (d.customValue1.isNotEmpty ||
        d.customValue2.isNotEmpty ||
        d.customValue3.isNotEmpty ||
        d.customValue4.isNotEmpty) {
      _showCustom = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final draft = vm.draft;
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientEditFieldPair(
            left: EntityEditField(
              label: context.tr('name'),
              initial: draft.name,
              onChanged: vm.setName,
              autofocus: vm.isCreate,
              errorText: vm.fieldErrorFor('name'),
            ),
            right: EntityEditField(
              label: context.tr('number'),
              initial: draft.number,
              onChanged: vm.setNumber,
              errorText: vm.fieldErrorFor('number'),
            ),
          ),
          ClientEditFieldPair(
            left: EntityEditField(
              label: context.tr('id_number'),
              initial: draft.idNumber,
              onChanged: vm.setIdNumber,
              errorText: vm.fieldErrorFor('id_number'),
            ),
            right: EntityEditField(
              label: context.tr('vat_number'),
              initial: draft.vatNumber,
              onChanged: vm.setVatNumber,
              errorText: vm.fieldErrorFor('vat_number'),
            ),
          ),
          ClientEditFieldPair(
            left: EntityEditField(
              label: context.tr('website'),
              initial: draft.website,
              onChanged: vm.setWebsite,
              keyboardType: TextInputType.url,
              errorText: vm.fieldErrorFor('website'),
            ),
            right: EntityEditField(
              label: context.tr('phone'),
              initial: draft.phone,
              onChanged: vm.setPhone,
              keyboardType: TextInputType.phone,
              errorText: vm.fieldErrorFor('phone'),
            ),
          ),
          if (_showCustom) ...[
            ClientEditFieldPair(
              left: EntityEditField(
                label: context.tr('custom_value1'),
                initial: draft.customValue1,
                onChanged: vm.setCustomValue1,
              ),
              right: EntityEditField(
                label: context.tr('custom_value2'),
                initial: draft.customValue2,
                onChanged: vm.setCustomValue2,
              ),
            ),
            ClientEditFieldPair(
              left: EntityEditField(
                label: context.tr('custom_value3'),
                initial: draft.customValue3,
                onChanged: vm.setCustomValue3,
              ),
              right: EntityEditField(
                label: context.tr('custom_value4'),
                initial: draft.customValue4,
                onChanged: vm.setCustomValue4,
              ),
            ),
          ],
          const SizedBox(height: InSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _showCustom = !_showCustom),
              icon: Icon(
                _showCustom ? Icons.unfold_less : Icons.unfold_more,
                size: 18,
              ),
              label: Text(
                context.tr(
                  _showCustom ? 'hide_custom_fields' : 'show_custom_fields',
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: tokens.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
