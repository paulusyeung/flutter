import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Resolves the client's
/// display-name cascade (`displayName` → `name` → `no_name_fallback`) and
/// surfaces the client number as the optional `#<n>` subtitle.
class ClientDetailHeader extends StatelessWidget {
  const ClientDetailHeader({super.key, required this.client, this.formatter});

  final Client client;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Client>(
      entity: client,
      entityType: EntityType.client,
      recordId: client.id,
      formatter: formatter,
      project: (context, c) => EntityHeaderFields(
        seedForAvatar: c.id,
        displayName: c.displayName.isNotEmpty
            ? c.displayName
            : (c.name.isNotEmpty ? c.name : context.tr('no_name_fallback')),
        number: c.number.isEmpty ? null : c.number,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        isDeleted: c.isDeleted,
        isArchived: c.archivedAt != null,
        isDirty: c.isDirty,
      ),
    );
  }
}
