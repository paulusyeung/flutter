import 'package:flutter/material.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/vendors/widgets/vendor_actions.dart';

/// Thin typedef-like wrapper for the vendor detail-screen action row.
///
/// Wraps [EntityDetailActionsRow] for the [VendorAction] enum so the detail
/// screen body stays a one-liner. Mirror of how the Client detail screen
/// builds its row inline; pulled into a named widget here so the same row
/// can be reused if the actions surface lands in another scaffold (e.g. a
/// dialog or a quick-look popover).
class VendorDetailActionsRow extends StatelessWidget {
  const VendorDetailActionsRow({
    super.key,
    required this.vendor,
    required this.services,
    required this.companyId,
  });

  final Vendor vendor;
  final Services services;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<VendorAction>(
      items: VendorActions.itemsFor(
        context,
        vendor,
        (a) => VendorActions.dispatch(context, services, companyId, vendor, a),
      ),
    );
  }
}
