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
        return const {}; // بلا وهم — فارغ يعني فارغ (يبقى الكاش المعروض)
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
      return const {}; // بلا وهم عند فشل الشبكة
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
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return const <ProductModel>[]; // بلا وهم — تُعاد المحاولة عند فتح التبويب
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
  Future<CategoryPageResult> fetchCategoryPage(String slug) async {
    try {
      final data = await _remoteDataSource.fetchCategoryPageRaw(slug);
      // المنتجات
      final rawItems = (data['products'] as List<dynamic>?) ?? const [];
      final products = rawItems.whereType<Map<String, dynamic>>().map((e) {
        if (e['category'] == null && e['categorySlug'] != null) {
          return {...e, 'category': e['categorySlug']};
        }
        return e;
      }).map(ProductModel.fromJson).toList();
      // بانرات السلايدر (heroSlides[].image)، وإلا heroImage كبانر واحد.
      final banners = <String>[];
      for (final s in (data['heroSlides'] as List<dynamic>?) ?? const []) {
        if (s is Map && s['image'] is String && (s['image'] as String).isNotEmpty) {
          banners.add(s['image'] as String);
        }
      }
      if (banners.isEmpty &&
          data['heroImage'] is String &&
          (data['heroImage'] as String).isNotEmpty) {
        banners.add(data['heroImage'] as String);
      }
      return CategoryPageResult(products: products, banners: banners);
    } catch (_) {
      return const CategoryPageResult(products: [], banners: []);
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
