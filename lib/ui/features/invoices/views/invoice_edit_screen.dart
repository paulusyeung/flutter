import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';

/// M1 stub of the Invoice edit + create screen. Renders a "coming soon"
/// body so the route compiles; the M3 milestone replaces this with the
/// full tabbed layout (Details / Contacts / Items / Notes / PDF / E-Invoice)
/// backed by [InvoiceEditViewModel]'s full setter surface.
class InvoiceEditScreen extends StatelessWidget {
  const InvoiceEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this invoice's fields. Identity-bearing fields (id,
  /// number, timestamps, locked flag, balance) are stripped by the caller.
  final Invoice? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Invoice, InvoiceEditViewModel>(
      existingId: existingId,
      entityTypeName: 'invoice',
      fetchExisting: (ctx, services, companyId, id) =>
          services.invoices.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return InvoiceEditViewModel(
          repo: services.invoices,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_invoice') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_invoice')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => const _InvoiceEditPlaceholder(),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (i) => i.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/invoices/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}

class _InvoiceEditPlaceholder extends StatelessWidget {
  const _InvoiceEditPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(InSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined, size: 48, color: tokens.ink3),
            const SizedBox(height: 12),
            Text(
              context.tr('coming_soon'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Plain English fallback — the long-form copy isn't translated
              // yet; M3 ships the real screen anyway.
              'Invoice editing lands in milestone 3 (line items, '
              'taxes, discounts, custom fields).',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
