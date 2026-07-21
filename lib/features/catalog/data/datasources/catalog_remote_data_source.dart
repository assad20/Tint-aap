import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchBootstrapCatalog() {
    return _apiClient.getMap(ApiRoutes.catalogBootstrap);
  }

  Future<List<dynamic>> fetchTrendingProducts() {
    return _apiClient.getList(ApiRoutes.catalogTrends);
  }

  // تنقّل المتجر الحقيقيّ (مجموعات المتجر المُدارة): [{id,name,image,href,children}]
  Future<List<dynamic>> fetchNavigation() {
    return _apiClient.getList(ApiRoutes.catalogNavigation);
  }

  // منتجات قسم بالـslug: الوسيط يُعيد CategoryPageData؛ نُخرج products ونطابق
  // category الذي يقرأه ProductModel (categorySlug → category).
  Future<List<dynamic>> fetchCategoryProducts(String slug) async {
    final data = await _apiClient.getMap('${ApiRoutes.catalogCategories}/$slug');
    final items = data['products'];
    if (items is! List) return const <dynamic>[];
    return items.map((e) {
      if (e is Map<String, dynamic> && e['category'] == null && e['categorySlug'] != null) {
        return {...e, 'category': e['categorySlug']};
      }
      return e;
    }).toList();
  }

  Future<List<dynamic>> searchProducts(String query) async {
    // الوسيط يُعيد { query, count, items:[card] } (كائن لا مصفوفة)، والبطاقة تحمل
    // categorySlug؛ نُخرج items ونطابق category الذي يقرأه ProductModel.
    final data = await _apiClient.getMap(
      ApiRoutes.catalogSearch,
      queryParameters: {'q': query},
    );
    final items = data['items'];
    if (items is! List) return const <dynamic>[];
    return items.map((e) {
      if (e is Map<String, dynamic> && e['category'] == null && e['categorySlug'] != null) {
        return {...e, 'category': e['categorySlug']};
      }
      return e;
    }).toList();
  }
}
