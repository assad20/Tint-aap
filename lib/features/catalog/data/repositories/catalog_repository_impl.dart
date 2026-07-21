import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required CatalogRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CatalogRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, List<ProductModel>>> fetchBootstrapCatalog() async {
    try {
      final data = await _remoteDataSource.fetchBootstrapCatalog();
      final catalog = (data['catalog'] as Map<String, dynamic>? ?? {});
      if (catalog.isEmpty) {
        return FakeSeedData.productsByCategory;
      }

      return catalog.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList(),
        ),
      );
    } catch (_) {
      return FakeSeedData.productsByCategory;
    }
  }

  @override
  Future<List<CategoryModel>> fetchQuickLinks() async {
    return FakeSeedData.quickLinks;
  }

  @override
  Future<List<String>> fetchSidebarCategories() async {
    return FakeSeedData.sidebarCategories;
  }

  @override
  Future<List<ProductModel>> fetchTrendingProducts() async {
    try {
      final items = await _remoteDataSource.fetchTrendingProducts();
      if (items.isEmpty) {
        return FakeSeedData.topTrending;
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return FakeSeedData.topTrending;
    }
  }

  @override
  Future<List<CategoryModel>> fetchNavigation() async {
    try {
      final items = await _remoteDataSource.fetchNavigation();
      return items
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } catch (_) {
      return const <CategoryModel>[];
    }
  }

  @override
  Future<List<ProductModel>> fetchCategoryProducts(String slug) async {
    try {
      final items = await _remoteDataSource.fetchCategoryProducts(slug);
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return const <ProductModel>[];
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final items = await _remoteDataSource.searchProducts(query);
      if (items.isEmpty) {
        return FakeSeedData.searchProducts(query);
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return FakeSeedData.searchProducts(query);
    }
  }
}
