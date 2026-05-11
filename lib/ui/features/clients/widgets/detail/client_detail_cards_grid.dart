import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_address_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_contacts_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_details_card.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_standing_card.dart';
import 'package:admin/utils/formatting.dart';

/// Lays out the four info cards (Details, Address, Contacts, Standing) in a
/// responsive grid:
///   - ≥900 px: single row of equal-width columns (only non-empty cards).
///   - 600–899 px: 2 cards per row (Wrap).
///   - <600 px: single column.
///
/// "Emptiness" is computed up front so the desktop row doesn't reserve an
/// `Expanded` slot for a card whose `build` returns `SizedBox.shrink()`.
/// The Standing card always renders (zero amounts show as "—") so the row
/// never collapses to nothing.
class ClientDetailCardsGrid extends StatelessWidget {
  const ClientDetailCardsGrid({
    super.key,
    required this.client,
    required this.formatter,
  });

  final Client client;
  final Formatter? formatter;

  static const double _desktopBreakpoint = 900;
  static const double _tabletBreakpoint = 600;

  bool get _hasDetails =>
      client.website.isNotEmpty ||
      client.phone.isNotEmpty ||
      client.vatNumber.isNotEmpty ||
      client.idNumber.isNotEmpty ||
      client.customValue1.isNotEmpty ||
      client.customValue2.isNotEmpty ||
      client.customValue3.isNotEmpty ||
      client.customValue4.isNotEmpty;

  bool get _hasAddress =>
      client.address1.isNotEmpty ||
      client.address2.isNotEmpty ||
      client.city.isNotEmpty ||
      client.state.isNotEmpty ||
      client.postalCode.isNotEmpty ||
      client.countryId.isNotEmpty;

  bool get _hasContacts => client.contacts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (_hasDetails) ClientDetailDetailsCard(client: client),
      if (_hasAddress) ClientDetailAddressCard(client: client),
      if (_hasContacts) ClientDetailContactsCard(contacts: client.contacts),
      ClientDetailStandingCard(client: client, formatter: formatter),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= _desktopBreakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: InSpacing.md),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }
        if (w >= _tabletBreakpoint) {
          final childWidth = (w - InSpacing.md) / 2;
          return Wrap(
            spacing: InSpacing.md,
            runSpacing: InSpacing.md,
            children: [
              for (final card in cards)
                SizedBox(width: childWidth, child: card),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: InSpacing.md),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}
