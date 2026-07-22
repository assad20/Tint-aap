import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';

// صفحة القسم: منتجاته + بانرات السلايدر (heroSlides المُدارة من الأدمن).
class CategoryPageResult {
  const CategoryPageResult({required this.products, required this.banners});
  final List<ProductModel> products;
  final List<String> banners; // روابط صور السلايدر
}

abstract class CatalogRepository {
  Future<Map<String, List<ProductModel>>> fetchBootstrapCatalog();

  Future<List<CategoryModel>> fetchQuickLinks();

  Future<List<String>> fetchSidebarCategories();

  Future<List<ProductModel>> fetchTrendingProducts();

  Future<List<ProductModel>> searchProducts(String query);

  // تنقّل المتجر الحقيقيّ (مجموعات المتجر) + منتجات قسم بالـslug.
  Future<List<CategoryModel>> fetchNavigation();

  Future<List<ProductModel>> fetchCategoryProducts(String slug);

  // منتجات القسم + بانرات السلايدر في نداء واحد.
  Future<CategoryPageResult> fetchCategoryPage(String slug);
}
