import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// State for the read-only Product detail screen.
class ProductDetailViewModel extends GenericDetailViewModel<Product> {
  ProductDetailViewModel({
    required this.repo,
    required this.companyId,
    required this.id,
  }) {
    bindStream(repo.watch(companyId: companyId, id: id));
  }

  final ProductRepository repo;
  final String companyId;
  final String id;

  Product? get product => item;
}
