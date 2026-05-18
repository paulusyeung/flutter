import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/domain/vendor_contact.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Resolves the vendor's
/// display-name cascade (`name` → first contact name → `no_name_fallback`)
/// and surfaces the vendor number as the optional `#<n>` subtitle.
/// Mirrors `ClientDetailHeader`.
class VendorDetailHeader extends StatelessWidget {
  const VendorDetailHeader({super.key, required this.vendor, this.formatter});

  final Vendor vendor;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Vendor>(
      entity: vendor,
      entityType: EntityType.vendor,
      recordId: vendor.id,
      formatter: formatter,
      project: (context, v) => EntityHeaderFields(
        seedForAvatar: v.id,
        displayName: _displayNameFor(context, v),
        number: v.number.isEmpty ? null : v.number,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
        isDeleted: v.isDeleted,
        isArchived: v.archivedAt != null,
        isDirty: v.isDirty,
      ),
    );
  }

  String _displayNameFor(BuildContext context, Vendor v) {
    if (v.name.isNotEmpty) return v.name;
    final c = _firstContact(v.contacts);
    if (c != null) {
      final composed = ('${c.firstName} ${c.lastName}').trim();
      if (composed.isNotEmpty) return composed;
      if (c.email.isNotEmpty) return c.email;
    }
    return context.tr('no_name_fallback');
  }

  VendorContact? _firstContact(List<VendorContact> contacts) {
    if (contacts.isEmpty) return null;
    for (final c in contacts) {
      if (c.isPrimary) return c;
    }
    return contacts.first;
  }
}
