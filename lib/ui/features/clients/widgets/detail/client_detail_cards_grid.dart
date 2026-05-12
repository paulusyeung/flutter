import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_address_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_contacts_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_details_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_notes_card.dart';
import 'package:admin/utils/formatting.dart';

/// Responsive grid for the client detail body cards.
///
/// - **≥1100 px**: three equal-width columns — Details · Address · Contacts —
///   with Notes spanning the full width on a second row when it has content.
///   If Contacts is empty, drops to two equal-width columns so Details and
///   Address don't get stretched by a zero-width sibling.
/// - **<1100 px**: single scrolling column, all cards stacked.
///
/// The KPI/Standing card has moved up into `ClientDetailKpiStrip` (rendered
/// by the screen above this grid), so this widget no longer owns it.
///
/// Cards return `SizedBox.shrink()` from `build` when they have no data, so
/// empty cards collapse out of the layout naturally.
class ClientDetailCardsGrid extends StatelessWidget {
  const ClientDetailCardsGrid({
    super.key,
    required this.client,
    required this.formatter,
  });

  final Client client;
  final Formatter? formatter;

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        if (wide) return _wide(client);
        return _stacked(client);
      },
    );
  }

  Widget _wide(Client c) {
    final hasContacts = c.contacts.isNotEmpty;
    final hasNotes = c.privateNotes.isNotEmpty || c.publicNotes.isNotEmpty;
    final columns = <Widget>[
      Expanded(child: ClientDetailDetailsCard(client: c)),
      const SizedBox(width: InSpacing.md),
      Expanded(child: ClientDetailAddressCard(client: c)),
      if (hasContacts) ...[
        const SizedBox(width: InSpacing.md),
        Expanded(child: ClientDetailContactsCard(contacts: c.contacts)),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columns,
          ),
        ),
        if (hasNotes) ...[
          const SizedBox(height: InSpacing.md),
          ClientDetailNotesCard(client: c),
        ],
      ],
    );
  }

  Widget _stacked(Client c) {
    final cards = <Widget>[
      ClientDetailDetailsCard(client: c),
      ClientDetailAddressCard(client: c),
      ClientDetailContactsCard(contacts: c.contacts),
      if (c.privateNotes.isNotEmpty || c.publicNotes.isNotEmpty)
        ClientDetailNotesCard(client: c),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: InSpacing.md),
          cards[i],
        ],
      ],
    );
  }
}
