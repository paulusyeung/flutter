import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';

/// Edit a single [TaxSubregionApi] entry from Settings → Tax Settings →
/// Calculate Taxes. Mirrors React `EditSubRegionModal.tsx` — four typed
/// inputs (name, rate, reduced rate, VAT number) with Cancel + Save
/// side-by-side per the design system rule for action button pairs.
class SubregionEditDialog extends StatefulWidget {
  const SubregionEditDialog({
    super.key,
    required this.subregionKey,
    required this.initial,
  });

  /// Subregion identifier (state code / country ISO) — shown in the title.
  final String subregionKey;

  /// Current values; closed dialog returns the new subregion via the
  /// `Navigator.pop` result.
  final TaxSubregionApi initial;

  /// Open the dialog and return the edited subregion. `null` on cancel.
  static Future<TaxSubregionApi?> show(
    BuildContext context, {
    required String subregionKey,
    required TaxSubregionApi initial,
  }) {
    return showDialog<TaxSubregionApi>(
      context: context,
      builder: (_) =>
          SubregionEditDialog(subregionKey: subregionKey, initial: initial),
    );
  }

  @override
  State<SubregionEditDialog> createState() => _SubregionEditDialogState();
}

class _SubregionEditDialogState extends State<SubregionEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late final TextEditingController _reducedRate;
  late final TextEditingController _vatNumber;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.taxName);
    _rate = TextEditingController(
      text: widget.initial.taxRate == 0
          ? ''
          : widget.initial.taxRate.toString(),
    );
    _reducedRate = TextEditingController(
      text: widget.initial.reducedTaxRate == 0
          ? ''
          : widget.initial.reducedTaxRate.toString(),
    );
    _vatNumber = TextEditingController(text: widget.initial.vatNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    _reducedRate.dispose();
    _vatNumber.dispose();
    super.dispose();
  }

  void _submit() {
    final next = widget.initial.copyWith(
      taxName: _name.text.trim(),
      taxRate: double.tryParse(_rate.text.trim()) ?? 0,
      reducedTaxRate: double.tryParse(_reducedRate.text.trim()) ?? 0,
      vatNumber: _vatNumber.text.trim(),
    );
    Navigator.of(context).pop(next);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${context.tr('edit')} — ${widget.subregionKey}'),
      content: IntrinsicWidth(
        child: FormSaveScope(
          onSubmit: _submit,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: context.tr('tax_name')),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: InSpacing.md(context)),
              TextField(
                controller: _rate,
                decoration: InputDecoration(labelText: context.tr('tax_rate')),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: InSpacing.md(context)),
              TextField(
                controller: _reducedRate,
                decoration: InputDecoration(
                  labelText: context.tr('reduced_rate'),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: InSpacing.md(context)),
              TextField(
                controller: _vatNumber,
                decoration: InputDecoration(
                  labelText: context.tr('vat_number'),
                ),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      // Cancel + Save side-by-side per § Design system v2. Per-call
      // minimumSize overrides keep them on one row inside
      // `AlertDialog.actions` (the global FilledButton theme defaults to
      // `Size.fromHeight(44)` — i.e. infinite width — which is right for
      // stacked form buttons but wrong here). Spacing is handled by the
      // `AlertDialog`'s internal `OverflowBar`; a manual `SizedBox`
      // between the children is ignored by `OverflowBar`'s layout.
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _submit,
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
