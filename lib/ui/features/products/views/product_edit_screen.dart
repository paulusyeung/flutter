import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/edit/entity_edit_scaffold.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';

/// Edit + Create form for a Product.
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({this.existingId, super.key});
  final String? existingId;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  ProductEditViewModel? _vm;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    if (widget.existingId == null) {
      _vm = ProductEditViewModel(repo: services.products, companyId: companyId);
      _loadedExisting = true;
    } else {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    final existing = await services.products
        .watch(companyId: companyId, id: widget.existingId!)
        .first;
    if (!mounted) return;
    setState(() {
      _vm = ProductEditViewModel(
        repo: services.products,
        companyId: companyId,
        existing: existing,
      );
      _loadedExisting = true;
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedExisting || _vm == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingId == null
                ? context.tr('new_product')
                : context.tr('edit'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final vm = _vm!;
    final canSave =
        !vm.isSaving &&
        (vm.isCreate ? vm.draft.productKey.trim().isNotEmpty : vm.isDirty);
    return EntityEditScaffold<Product>(
      vm: vm,
      canSave: canSave,
      titleBuilder: (context) => vm.isCreate
          ? context.tr('new_product')
          : (vm.draft.productKey.isNotEmpty
                ? '${context.tr('edit')} · ${vm.draft.productKey}'
                : context.tr('edit')),
      bodyBuilder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(InSpacing.lg),
        child: DashboardCardShell(
          title: context.tr('details'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              EntityEditField(
                label: context.tr('product'),
                initial: vm.draft.productKey,
                onChanged: vm.setProductKey,
                autofocus: vm.isCreate,
                errorText: vm.fieldErrorFor('product_key'),
              ),
              EntityEditField(
                label: context.tr('price'),
                initial: vm.draft.price.toString(),
                onChanged: vm.setPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: vm.fieldErrorFor('price'),
              ),
              EntityEditField(
                label: context.tr('cost'),
                initial: vm.draft.cost.toString(),
                onChanged: vm.setCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: vm.fieldErrorFor('cost'),
              ),
              EntityEditField(
                label: context.tr('quantity'),
                initial: vm.draft.quantity.toString(),
                onChanged: vm.setQuantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: vm.fieldErrorFor('quantity'),
              ),
              EntityEditField(
                label: context.tr('notes'),
                initial: vm.draft.notes,
                onChanged: vm.setNotes,
                minLines: 2,
                maxLines: null,
              ),
            ],
          ),
        ),
      ),
      resetToEmpty: vm.resetToEmpty,
      onSaved: (context, saved) {
        if (vm.isCreate) {
          context.go('/products/${saved.id}');
        } else {
          context.pop();
        }
      },
    );
  }
}
