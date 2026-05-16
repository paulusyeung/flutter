import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

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
    this.link = false,
  });

  final String vendorId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  /// When true the resolved name renders as a hover-underlined link to
  /// the vendor's full-screen view. Off by default.
  final bool link;

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
      return _text(context, vendorId);
    }
    return StreamBuilder<Vendor?>(
      stream: services.vendors.watch(companyId: companyId, id: vendorId),
      builder: (context, snapshot) {
        final vendor = snapshot.data;
        final name = vendor == null || vendor.name.isEmpty
            ? vendorId
            : vendor.name;
        return _text(context, name);
      },
    );
  }

  Widget _text(BuildContext context, String text) => linkOrText(
    link: link,
    label: text,
    onTap: link
        ? () => goEntityFullDetail(context, '/vendors', vendorId)
        : null,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
  );
}
