import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// One-time display of a freshly-minted API token's raw bearer secret.
/// The server only returns this value once (on the create response). After
/// dismissal the local row carries the masked form and the secret is gone.
class TokenCreatedDialog extends StatelessWidget {
  const TokenCreatedDialog({required this.secret, super.key});
  final String secret;

  static Future<void> show(BuildContext context, String secret) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TokenCreatedDialog(secret: secret),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AlertDialog(
      title: Text(context.tr('token_created_dialog_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('token_created_dialog_body')),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(InRadii.r2),
              border: Border.all(color: tokens.border),
            ),
            child: SelectableText(
              secret,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: secret));
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          child: Text(context.tr('copy_token')),
        ),
        const SizedBox(width: 8),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          child: Text(context.tr('done')),
        ),
      ],
    );
  }
}
