import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';

/// Resolves the client display name from the local Drift cache and
/// renders it as a `Text`. Falls back to the raw `clientId` while the
/// watch is empty (first sync hasn't landed for this client) or when
/// the client isn't in the cache.
///
/// Drift watch streams dedupe identical queries, so N rows each rendering
/// a label for the same `clientId` share one underlying subscription.
class ClientNameLabel extends StatelessWidget {
  const ClientNameLabel({
    super.key,
    required this.clientId,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String clientId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (clientId.isEmpty) {
      return Text(
        '—',
        style: style ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _text(clientId);
    }
    return StreamBuilder<Client?>(
      stream: services.clients.watch(companyId: companyId, id: clientId),
      builder: (context, snapshot) {
        final client = snapshot.data;
        final name = client == null || client.displayName.isEmpty
            ? clientId
            : client.displayName;
        return _text(name);
      },
    );
  }

  Widget _text(String text) =>
      Text(text, maxLines: maxLines, overflow: overflow, style: style);
}
