import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/utils/url_safety.dart';

/// Build the client-portal silent auto-login URL for a contact's portal
/// [contactLink]. Mirrors admin-portal (`ClientContactEntity.silentLink`)
/// and React (`useActions`): append `silent=true` (skip the portal login
/// screen) and the client's [clientHash] (auth token). Returns `''` when
/// [contactLink] is empty — that contact has no portal yet (e.g. an unsynced
/// `tmp_` client), so callers should treat empty as "no portal".
String clientPortalUrl({
  required String contactLink,
  required String clientHash,
}) {
  if (contactLink.isEmpty) return '';
  final sep = contactLink.contains('?') ? '&' : '?';
  final base = '$contactLink${sep}silent=true';
  return clientHash.isEmpty ? base : '$base&client_hash=$clientHash';
}

/// Validate ([isSafeWebUrl] — http/https only, no `javascript:`/`file:`/…) and
/// launch [url] in the external browser, surfacing a toast on failure. Shared
/// by the contacts-card *View Portal* button and the top-level Client Portal
/// action so both build + open the portal the same way.
Future<void> launchClientPortal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorMessage =
      Localization.of(context)?.lookup('failed_to_open_url') ??
      'failed_to_open_url';
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
