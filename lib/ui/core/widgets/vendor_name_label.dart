import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';

/// Resolves the vendor display name from the local Drift cache and
/// renders it as a `Text`. Falls back to the raw `vendorId` while the
/// watch is empty (first sync hasn't landed for this vendor) or when
/// the vendor isn't in the cache.
///
/// Mirrors `ClientNameLabel` — Drift dedupes identical watch queries so
/// N rows for the same vendor share one underlying subscription.
class VendorNameLabel extends StatelessWidget {
  const VendorNameLabel({
    super.key,
    required this.vendorId,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String vendorId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (vendorId.isEmpty) {
      return Text(
        '—',
        style: style ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _text(vendorId);
    }
    return StreamBuilder<Vendor?>(
      stream: services.vendors.watch(companyId: companyId, id: vendorId),
      builder: (context, snapshot) {
        final vendor = snapshot.data;
        final name = vendor == null || vendor.name.isEmpty
            ? vendorId
            : vendor.name;
        return _text(name);
      },
    );
  }

  Widget _text(String text) =>
      Text(text, maxLines: maxLines, overflow: overflow, style: style);
}
