import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Thin wrapper over [EntityDetailHeader] — resolves the client's display
/// name cascade (`displayName` → `name` → `no_name_fallback`) and surfaces
/// the client number as the optional `#<n>` subtitle.
class ClientDetailHeader extends StatelessWidget {
  const ClientDetailHeader({super.key, required this.client, this.formatter});

  final Client client;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeader(
      seedForAvatar: client.id,
      displayName: _displayName(context, client),
      number: client.number.isEmpty ? null : client.number,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
      isDeleted: client.isDeleted,
      isArchived: client.archivedAt != null,
      isDirty: client.isDirty,
      formatter: formatter,
    );
  }
}

String _displayName(BuildContext context, Client c) {
  if (c.displayName.isNotEmpty) return c.displayName;
  if (c.name.isNotEmpty) return c.name;
  return context.tr('no_name_fallback');
}
