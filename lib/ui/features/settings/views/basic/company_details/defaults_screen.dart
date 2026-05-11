import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';

/// "Defaults" tab — the eight pairs of terms/footer fields applied by
/// default to every newly-created invoice, quote, credit, and purchase
/// order. Plain `maxLines: 6` text fields for now — a real markdown editor
/// is a follow-up.
class CompanyDetailsDefaultsScreen extends StatelessWidget {
  const CompanyDetailsDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    if (vm.draft == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          label: context.tr('invoice'),
          children: [
            OverridableTextField(
              label: context.tr('terms'),
              apiKey: 'invoice_terms',
              maxLines: 6,
              read: (vm) => vm.settings.invoiceTerms,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(invoiceTerms: v)),
            ),
            const SizedBox(height: 12),
            OverridableTextField(
              label: context.tr('footer'),
              apiKey: 'invoice_footer',
              maxLines: 6,
              read: (vm) => vm.settings.invoiceFooter,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(invoiceFooter: v)),
            ),
          ],
        ),
        _Section(
          label: context.tr('quote'),
          children: [
            OverridableTextField(
              label: context.tr('terms'),
              apiKey: 'quote_terms',
              maxLines: 6,
              read: (vm) => vm.settings.quoteTerms,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(quoteTerms: v)),
            ),
            const SizedBox(height: 12),
            OverridableTextField(
              label: context.tr('footer'),
              apiKey: 'quote_footer',
              maxLines: 6,
              read: (vm) => vm.settings.quoteFooter,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(quoteFooter: v)),
            ),
          ],
        ),
        _Section(
          label: context.tr('credit'),
          children: [
            OverridableTextField(
              label: context.tr('terms'),
              apiKey: 'credit_terms',
              maxLines: 6,
              read: (vm) => vm.settings.creditTerms,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(creditTerms: v)),
            ),
            const SizedBox(height: 12),
            OverridableTextField(
              label: context.tr('footer'),
              apiKey: 'credit_footer',
              maxLines: 6,
              read: (vm) => vm.settings.creditFooter,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(creditFooter: v)),
            ),
          ],
        ),
        _Section(
          label: context.tr('purchase_order'),
          children: [
            OverridableTextField(
              label: context.tr('terms'),
              apiKey: 'purchase_order_terms',
              maxLines: 6,
              read: (vm) => vm.settings.purchaseOrderTerms,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(purchaseOrderTerms: v)),
            ),
            const SizedBox(height: 12),
            OverridableTextField(
              label: context.tr('footer'),
              apiKey: 'purchase_order_footer',
              maxLines: 6,
              read: (vm) => vm.settings.purchaseOrderFooter,
              write: (vm, v) =>
                  vm.updateSettings((s) => s.copyWith(purchaseOrderFooter: v)),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
