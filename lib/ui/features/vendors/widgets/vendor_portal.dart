import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/utils/url_safety.dart';

/// Build the vendor-portal silent auto-login URL from a contact's portal
/// [contactLink]. The server returns a ready `vendor/key_login/<key>` URL that
/// already authenticates; append `silent=true` to skip the portal landing
/// (mirrors `clientPortalUrl`). Returns `''` when [contactLink] is empty — that
/// contact has no portal yet (e.g. an unsynced `tmp_` vendor).
String vendorPortalUrl({required String contactLink}) {
  if (contactLink.isEmpty) return '';
  final sep = contactLink.contains('?') ? '&' : '?';
  return '$contactLink${sep}silent=true';
}

/// Validate ([isSafeWebUrl] — http/https only) and launch [url] in the external
/// browser, surfacing a toast on failure. Mirror of `launchClientPortal`.
Future<void> launchVendorPortal(BuildContext context, String url) async {
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
