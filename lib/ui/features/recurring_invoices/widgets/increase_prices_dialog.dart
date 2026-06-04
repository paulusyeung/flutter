import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/l10n/localization.dart';

/// Prompt for the Increase Prices bulk action: asks for a percentage and
/// returns it (raw numeric string) to the caller, which enqueues
/// `MutationKind.increasePrices` per selected recurring invoice. Returns null
/// on cancel or invalid input.
Future<String?> showIncreasePricesDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _IncreasePricesDialog(),
  );
}

class _IncreasePricesDialog extends StatefulWidget {
  const _IncreasePricesDialog();

  @override
  State<_IncreasePricesDialog> createState() => _IncreasePricesDialogState();
}

class _IncreasePricesDialogState extends State<_IncreasePricesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (num.tryParse(value) == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('increase_prices')),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.tr('percentage_increase'),
            suffixText: '%',
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('cancel')),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: _submit,
              child: Text(context.tr('done')),
            ),
          ],
        ),
      ],
    );
  }
}
