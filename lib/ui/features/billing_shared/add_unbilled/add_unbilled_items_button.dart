import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/billing_shared/add_unbilled/add_unbilled_items_sheet.dart';

/// "Add unbilled items" trigger for a billing-doc editor. Disabled (with an
/// explanatory tooltip) until a client is chosen — the sheet's fetch is
/// scoped to `client_id`. On confirm, hands the converted [LineItem]s to
/// [onAdd]; the caller appends them to the draft's line items.
class AddUnbilledItemsButton extends StatelessWidget {
  const AddUnbilledItemsButton({
    super.key,
    required this.companyId,
    required this.clientId,
    required this.onAdd,
  });

  final String companyId;
  final String clientId;
  final void Function(List<LineItem> added) onAdd;

  @override
  Widget build(BuildContext context) {
    final enabled = clientId.isNotEmpty;
    final button = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
      onPressed: enabled ? () => _open(context) : null,
      icon: const Icon(Icons.playlist_add, size: 18),
      label: Text(context.tr('add_unbilled_items')),
    );
    if (enabled) return button;
    return Tooltip(
      message: context.tr('please_select_a_client'),
      child: button,
    );
  }

  Future<void> _open(BuildContext context) async {
    final formatter = context.read<Services>().formatterIfReady(companyId);
    final added = await showAddUnbilledItemsSheet(
      context,
      companyId: companyId,
      clientId: clientId,
      formatter: formatter,
    );
    if (added != null && added.isNotEmpty) onAdd(added);
  }
}
