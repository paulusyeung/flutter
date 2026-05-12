import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/products/view_models/product_list_view_model.dart';

/// Minimal list screen for Products. Uses the [GenericListViewModel] base
/// for pagination + search + state filtering, then renders a simple
/// `ListView`. (The richer column / token-filter chrome from the clients
/// list can be extracted into a shared widget once a third entity lands;
/// today products doesn't need it.)
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final ProductListViewModel _vm;
  late final ScrollController _scroll;
  static const double _loadMoreThresholdPx = 600;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    _vm = ProductListViewModel(
      repo: services.products,
      companyId: companyId,
      navStateDao: services.db.navStateDao,
      userSettings: services.userSettings,
    );
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < _loadMoreThresholdPx) {
      _vm.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('products')),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: context.tr('new_product'),
                onPressed: () => context.go('/products/new'),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (_vm.initialError != null && _vm.items.isEmpty) {
                return ErrorView(
                  message: _vm.initialError!,
                  onRetry: _vm.retryInitial,
                );
              }
              if (_vm.items.isEmpty && _vm.isLoadingPage) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_vm.items.isEmpty) {
                return EmptyState(
                  key: const ValueKey('products_list_empty'),
                  icon: Icons.inventory_2_outlined,
                  title: context.tr('no_products'),
                );
              }
              return RefreshIndicator(
                onRefresh: _vm.refreshAll,
                child: ListView.separated(
                  key: const ValueKey('products_list'),
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
                  itemCount: _vm.items.length + (_vm.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i >= _vm.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(InSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final p = _vm.items[i];
                    return _ProductRow(
                      product: p,
                      onTap: () => context.go('/products/${p.id}'),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final priceFmt = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return ListTile(
      onTap: onTap,
      title: Text(
        product.productKey.isEmpty ? '—' : product.productKey,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: product.notes.isEmpty
          ? null
          : Text(
              product.notes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.ink3),
            ),
      trailing: Text(
        priceFmt.format(product.price.toDouble()),
        style: TextStyle(
          color: tokens.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
