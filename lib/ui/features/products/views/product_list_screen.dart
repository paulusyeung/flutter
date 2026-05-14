import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/products/view_models/product_list_view_model.dart';
import 'package:admin/ui/features/products/widgets/product_list_tile.dart';
import 'package:admin/ui/features/products/widgets/product_token_search_field.dart';

/// Products list screen — pure config + per-entity widgets. Mirrors
/// [ClientListScreen]; the screen-level chrome lives in
/// [EntityListScreenScaffold].
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Product, ProductListViewModel>(
      titleKey: 'products',
      newRoute: '/products/new',
      newLabelKey: 'new_product',
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitleKey: 'no_products',
      buildVm: (services, companyId) => ProductListViewModel(
        repo: services.products,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(
          id: ProductFieldIds.productKey,
          label: context.tr('product_key'),
        ),
        SortOption(id: ProductFieldIds.price, label: context.tr('price')),
        SortOption(id: ProductFieldIds.cost, label: context.tr('cost')),
        SortOption(id: ProductFieldIds.quantity, label: context.tr('quantity')),
        SortOption(
          id: ProductFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          ProductTokenSearchField(vm: vm, wide: wide),
      tileBuilder: (context, vm, product, index, options) => ProductListTile(
        product: product,
        columns: options.wide ? vm.columns : const [],
        wide: options.wide,
        isLast: options.isLast,
        selecting: options.selecting,
        selected: vm.isSelected(product.id),
        onTap: options.selecting
            ? () => vm.toggleSelected(product.id)
            : () => context.go('/products/${product.id}'),
        onLongPress: () => vm.toggleSelected(product.id),
        onSelectTap: () => vm.toggleSelected(product.id),
        onAction: options.selecting
            ? null
            : (action) => _onAction(context, vm, product, action),
      ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_product',
          pluralSuccessKey: 'archived_products',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_product',
          pluralSuccessKey: 'restored_products',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    ProductListViewModel vm,
    Product product,
    ProductRowAction action,
  ) async {
    final repo = vm.repo;
    switch (action) {
      case ProductRowAction.view:
        context.go('/products/${product.id}');
      case ProductRowAction.edit:
        context.go('/products/${product.id}/edit');
      case ProductRowAction.archive:
        await _runMutation(
          context,
          () => repo.archive(companyId: vm.companyId, id: product.id),
          successMsg: context.tr('archived_product'),
        );
      case ProductRowAction.restore:
        await _runMutation(
          context,
          () => repo.restore(companyId: vm.companyId, id: product.id),
          successMsg: context.tr('restored_product'),
        );
    }
  }

  Future<void> _runMutation(
    BuildContext context,
    Future<void> Function() op, {
    required String successMsg,
  }) async {
    try {
      await op();
      if (!context.mounted) return;
      Notify.success(context, successMsg);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr('could_not_save'), error: e);
    }
  }
}
