import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Resolves the client display name from the local Drift cache and
/// renders it as a `Text` (or a link when [link]). Falls back to the
/// raw `clientId` while the watch is empty; on a cache miss it triggers
/// a lazy per-id hydrate (`ClientRepository.ensureLoaded`) so the name
/// resolves even when the client isn't on the prefetched first page.
///
/// Drift dedupes identical watch queries (and the repo dedupes the
/// hydrate fetch), so N rows for the same client share one subscription
/// and one network call.
class ClientNameLabel extends StatefulWidget {
  const ClientNameLabel({
    super.key,
    required this.clientId,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.link = false,
  });

  final String clientId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  /// When true the resolved name renders as a hover-underlined link to
  /// the client's full-screen view. Off by default so non-list usages
  /// (detail headers, pickers) stay plain text.
  final bool link;

  @override
  State<ClientNameLabel> createState() => _ClientNameLabelState();
}

class _ClientNameLabelState extends State<ClientNameLabel> {
  @override
  void initState() {
    super.initState();
    _ensure();
  }

  @override
  void didUpdateWidget(ClientNameLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) _ensure();
  }

  /// Lazily hydrate the referenced client into Drift if it isn't cached
  /// (paginated lists prefetch only page 1). No-op / deduped / negative-
  /// cached in the repo, so it's safe to fire unconditionally here.
  void _ensure() {
    final id = widget.clientId;
    if (id.isEmpty) return;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) return;
    services.clients.ensureLoaded(companyId: companyId, id: id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (widget.clientId.isEmpty) {
      return Text(
        '—',
        style: widget.style ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _text(context, widget.clientId);
    }
    return StreamBuilder<Client?>(
      stream: services.clients.watch(
        companyId: companyId,
        id: widget.clientId,
      ),
      builder: (context, snapshot) {
        final client = snapshot.data;
        final name = client == null || client.displayName.isEmpty
            ? widget.clientId
            : client.displayName;
        return _text(context, name);
      },
    );
  }

  Widget _text(BuildContext context, String text) => linkOrText(
    link: widget.link,
    label: text,
    onTap: widget.link
        ? () => goEntityFullDetail(context, '/clients', widget.clientId)
        : null,
    style: widget.style,
    maxLines: widget.maxLines,
    overflow: widget.overflow,
  );
}
