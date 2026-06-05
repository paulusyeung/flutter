import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/domain/columns/column_cells.dart';

/// Resolves a billing-doc party's (client *or* vendor) `currency_id` from the
/// local Drift cache and rebuilds [builder] with it — `null` until it resolves,
/// or when no party is set (→ company-default currency).
///
/// Mirrors [ClientNameLabel] / [VendorNameLabel]: it watches the very same
/// `(companyId, partyId)` row those labels already watch, so Drift dedupes the
/// underlying query — a money cell adds **no** extra DB work on top of the
/// name cell in the same row — and it lazily hydrates an off-page party via
/// `ensureLoaded` (paginated lists prefetch only page 1).
///
/// Exactly one of [clientId] / [vendorId] should be non-empty.
class PartyCurrencyBuilder extends StatefulWidget {
  const PartyCurrencyBuilder({
    super.key,
    this.clientId,
    this.vendorId,
    required this.builder,
  });

  final String? clientId;
  final String? vendorId;

  /// Rebuilt with the resolved party currency id (or `null`).
  final Widget Function(BuildContext context, String? currencyId) builder;

  @override
  State<PartyCurrencyBuilder> createState() => _PartyCurrencyBuilderState();
}

class _PartyCurrencyBuilderState extends State<PartyCurrencyBuilder> {
  @override
  void initState() {
    super.initState();
    _ensure();
  }

  @override
  void didUpdateWidget(PartyCurrencyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId ||
        oldWidget.vendorId != widget.vendorId) {
      _ensure();
    }
  }

  void _ensure() {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) return;
    final vendorId = widget.vendorId ?? '';
    final clientId = widget.clientId ?? '';
    if (vendorId.isNotEmpty) {
      services.vendors.ensureLoaded(companyId: companyId, id: vendorId);
    } else if (clientId.isNotEmpty) {
      services.clients.ensureLoaded(companyId: companyId, id: clientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    final vendorId = widget.vendorId ?? '';
    final clientId = widget.clientId ?? '';
    if (companyId == null ||
        companyId.isEmpty ||
        (vendorId.isEmpty && clientId.isEmpty)) {
      return widget.builder(context, null);
    }
    if (vendorId.isNotEmpty) {
      return StreamBuilder<Vendor?>(
        stream: services.vendors.watch(companyId: companyId, id: vendorId),
        builder: (context, snap) =>
            widget.builder(context, snap.data?.currencyId),
      );
    }
    return StreamBuilder<Client?>(
      stream: services.clients.watch(companyId: companyId, id: clientId),
      builder: (context, snap) =>
          widget.builder(context, snap.data?.currencyId),
    );
  }
}

/// Money cell for a billing-doc list column that renders in the document's own
/// party currency (client or vendor) instead of the company default. Resolves
/// the party currency via [PartyCurrencyBuilder] then delegates to [cellMoney]
/// — so the zero→em-dash convention, the currency precision, and the no-scope
/// fallback all stay identical to every other money column.
Widget cellPartyMoney(
  Decimal value,
  BuildContext context, {
  String? clientId,
  String? vendorId,
  bool cents = true,
}) {
  // Zero renders as an em-dash regardless of currency — skip the party stream
  // entirely (common for all-zero balance columns).
  if (value == Decimal.zero) return cellMoney(value, context, cents: cents);
  final hasVendor = vendorId != null && vendorId.isNotEmpty;
  final hasClient = clientId != null && clientId.isNotEmpty;
  if (!hasVendor && !hasClient) return cellMoney(value, context, cents: cents);
  return PartyCurrencyBuilder(
    clientId: clientId,
    vendorId: vendorId,
    builder: (context, currencyId) => cellMoney(
      value,
      context,
      cents: cents,
      clientCurrencyId: hasClient ? currencyId : null,
      vendorCurrencyId: hasVendor ? currencyId : null,
    ),
  );
}
