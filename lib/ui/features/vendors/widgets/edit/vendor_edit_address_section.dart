import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_edit_view_model.dart';
import 'package:admin/ui/features/vendors/widgets/edit/vendor_edit_country_field.dart';
import 'package:admin/ui/features/vendors/widgets/edit/vendor_edit_field_pair.dart';

/// "Address" card on the vendor edit screen. Fields pair on wide widths and
/// stack on narrow. Mirror of `ClientEditAddressSection`.
class VendorEditAddressSection extends StatelessWidget {
  const VendorEditAddressSection({super.key, required this.vm});

  final VendorEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;
    return DashboardCardShell(
      title: context.tr('address'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EntityEditField(
            label: context.tr('address1'),
            initial: draft.address1,
            onChanged: vm.setAddress1,
          ),
          EntityEditField(
            label: context.tr('address2'),
            initial: draft.address2,
            onChanged: vm.setAddress2,
          ),
          VendorEditFieldPair(
            left: EntityEditField(
              label: context.tr('city'),
              initial: draft.city,
              onChanged: vm.setCity,
            ),
            right: EntityEditField(
              label: context.tr('state'),
              initial: draft.state,
              onChanged: vm.setState,
            ),
          ),
          VendorEditFieldPair(
            left: EntityEditField(
              label: context.tr('postal_code'),
              initial: draft.postalCode,
              onChanged: vm.setPostalCode,
            ),
            right: VendorEditCountryField(
              initial: draft.countryId,
              onChanged: vm.setCountryId,
            ),
          ),
        ],
      ),
    );
  }
}
