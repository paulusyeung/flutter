import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/quotes/view_models/quote_edit_view_model.dart';
import 'package:admin/ui/features/quotes/widgets/edit/quote_edit_layout.dart';

class QuoteEditScreen extends StatelessWidget {
  const QuoteEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;
  final Quote? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Quote, QuoteEditViewModel>(
      existingId: existingId,
      entityTypeName: 'quote',
      fetchExisting: (ctx, services, companyId, id) =>
          services.quotes.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return QuoteEditViewModel(
          repo: services.quotes,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_quote') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_quote')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => QuoteEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (q) => q.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/quotes/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
