import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/webhooks/view_models/webhook_edit_view_model.dart';

/// Lightweight key/value editor for the webhook's outgoing HTTP headers.
class WebhookHeadersEditor extends StatefulWidget {
  const WebhookHeadersEditor({required this.vm, super.key});
  final WebhookEditViewModel vm;

  @override
  State<WebhookHeadersEditor> createState() => _WebhookHeadersEditorState();
}

class _WebhookHeadersEditorState extends State<WebhookHeadersEditor> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addHeader() {
    final key = _keyController.text.trim();
    final value = _valueController.text;
    if (key.isEmpty) return;
    widget.vm.addHeader(key, value);
    _keyController.clear();
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final headers = widget.vm.draft.headers;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.tr('no_headers'),
              style: TextStyle(color: tokens.ink2),
            ),
          )
        else
          for (final entry in headers.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              subtitle: Text(entry.value),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => widget.vm.removeHeader(entry.key),
                tooltip: context.tr('remove'),
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyController,
                decoration: InputDecoration(labelText: context.tr('header')),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _valueController,
                decoration: InputDecoration(labelText: context.tr('value')),
                onSubmitted: (_) => _addHeader(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _addHeader,
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              child: Text(context.tr('add')),
            ),
          ],
        ),
      ],
    );
  }
}
