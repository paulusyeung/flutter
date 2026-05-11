import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_address_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_contacts_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_details_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_notes_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_standing_card.dart';
import 'package:admin/utils/formatting.dart';

/// Responsive layout for the detail-screen cards, mirroring the v2 mockup's
/// `1fr / 320–360 px` split:
///
/// - ≥1100 px: two columns. Left (`Expanded`) holds Details + Address; right
///   (fixed `_sidebarWidth`) holds Standing + Contacts + Notes.
/// - 600–1099 px: single scrolling column, all cards stacked.
/// - <600 px: same single column.
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

  static const double _twoColumnBreakpoint = 1100;
  static const double _sidebarWidth = 360;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= _twoColumnBreakpoint;
        if (twoCol) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _mainColumn(client)),
              const SizedBox(width: InSpacing.md),
              SizedBox(width: _sidebarWidth, child: _sideColumn(client)),
            ],
          );
        }
        return _stackedColumn(client);
      },
    );
  }

  Widget _mainColumn(Client c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClientDetailDetailsCard(client: c),
        const SizedBox(height: InSpacing.md),
        ClientDetailAddressCard(client: c),
      ],
    );
  }

  Widget _sideColumn(Client c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClientDetailStandingCard(client: c, formatter: formatter),
        const SizedBox(height: InSpacing.md),
        ClientDetailContactsCard(contacts: c.contacts),
        if (c.privateNotes.isNotEmpty || c.publicNotes.isNotEmpty) ...[
          const SizedBox(height: InSpacing.md),
          ClientDetailNotesCard(client: c),
        ],
      ],
    );
  }

  Widget _stackedColumn(Client c) {
    final cards = <Widget>[
      ClientDetailDetailsCard(client: c),
      ClientDetailAddressCard(client: c),
      ClientDetailStandingCard(client: c, formatter: formatter),
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
