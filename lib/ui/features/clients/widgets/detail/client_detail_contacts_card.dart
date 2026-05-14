import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/url_safety.dart';

/// "Contacts" card on the client detail screen. Shows the first 3 contacts
/// inline. Extra contacts surface via "+N more":
///   - ≥[Breakpoints.wide] screen width (tablet/desktop): expands inline within the same card.
///   - below: opens a bottom sheet listing every contact.
///
/// Hides entirely when the client has no contacts (matches the React
/// "hide-if-empty" behavior).
///
/// The wide/narrow decision uses `MediaQuery.sizeOf(context).width` rather than
/// `LayoutBuilder`. The grid above this card uses `IntrinsicHeight` so cards
/// align to equal heights on desktop; `IntrinsicHeight` queries children for
/// intrinsic sizes, and `LayoutBuilder` cannot answer those queries (it needs
/// real constraints first). `MediaQuery` is an inherited-widget lookup, so it
/// answers fine during the intrinsic pass.
class ClientDetailContactsCard extends StatefulWidget {
  const ClientDetailContactsCard({super.key, required this.contacts});

  final List<Contact> contacts;

  @override
  State<ClientDetailContactsCard> createState() =>
      _ClientDetailContactsCardState();
}

class _ClientDetailContactsCardState extends State<ClientDetailContactsCard> {
  static const int _inlineLimit = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.contacts.isEmpty) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    final all = widget.contacts;
    final showAll = _expanded || all.length <= _inlineLimit;
    final visible = showAll ? all : all.take(_inlineLimit).toList();
    final hiddenCount = all.length - visible.length;

    return DashboardCardShell(
      title: context.tr('contacts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DetailRowStack(children: visible.map(_ContactRow.new).toList()),
          if (hiddenCount > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  if (wide) {
                    setState(() => _expanded = true);
                  } else {
                    _openSheet(context);
                  }
                },
                icon: const Icon(Icons.unfold_more, size: 16),
                label: Text(
                  context.tr('plus_n_more', {'count': '$hiddenCount'}),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = sheetContext.inTheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              InSpacing.lg(context),
              InSpacing.sm,
              InSpacing.lg(context),
              InSpacing.lg(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: InSpacing.sm),
                  child: Text(
                    sheetContext.tr('contacts'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(
                          color: tokens.ink,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: DetailRowStack(
                      children: widget.contacts.map(_ContactRow.new).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.contact);
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final name = ('${contact.firstName} ${contact.lastName}').trim();
    final title = name.isNotEmpty
        ? name
        : (contact.email.isNotEmpty
              ? contact.email
              : context.tr('no_name_fallback'));
    final subtitle = [
      if (contact.email.isNotEmpty && contact.email != title) contact.email,
      if (contact.phone.isNotEmpty) contact.phone,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                ],
                if (contact.link.isNotEmpty) ...[
                  const SizedBox(height: InSpacing.xs),
                  Wrap(
                    spacing: InSpacing.sm,
                    children: [
                      TextButton.icon(
                        style: _portalButtonStyle,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(context.tr('view_portal')),
                        onPressed: () => _openPortal(context, contact.link),
                      ),
                      TextButton.icon(
                        style: _portalButtonStyle,
                        icon: const Icon(Icons.content_copy, size: 14),
                        label: Text(context.tr('copy_link')),
                        onPressed: () => _copyPortal(context, contact.link),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (contact.isPrimary)
            Padding(
              padding: const EdgeInsets.only(left: InSpacing.sm, top: 2),
              child: Icon(Icons.star, size: 14, color: tokens.accent),
            ),
        ],
      ),
    );
  }
}

final ButtonStyle _portalButtonStyle = TextButton.styleFrom(
  minimumSize: const Size(0, 32),
  padding: const EdgeInsets.symmetric(horizontal: 8),
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

Future<void> _openPortal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorMessage =
      Localization.of(context)?.lookup('failed_to_open_url') ??
      'failed_to_open_url';
  // Portal link is server-supplied — reject anything other than http/https
  // (no javascript:, file:, intent:, mailto:, tel: …) before launching.
  if (isSafeWebUrl(url)) {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {
      /* fall through to error toast */
    }
  }
  if (messenger == null) return;
  // ignore: use_build_context_synchronously
  Notify.error(messenger.context, errorMessage, messenger: messenger);
}

Future<void> _copyPortal(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  Notify.success(context, context.tr('link_copied'));
}
