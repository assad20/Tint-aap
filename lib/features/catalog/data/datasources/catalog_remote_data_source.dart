import '../../../../app/config/api_routes.dart';
import '../../../../core/network/api_client.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchBootstrapCatalog() {
    return _apiClient.getMap(ApiRoutes.catalogBootstrap);
  }

  // رئيسيّة المتجر الخام (تحوي hero.slides — بنرات موضع `hero` من الأدمن).
  Future<Map<String, dynamic>> fetchHome() {
    return _apiClient.getMap(ApiRoutes.catalogHome);
  }

  /// تخطيط رئيسيّة التطبيق من لوحة التحكّم (SDUI).
  ///
  /// ‼️ يعود **404** حين لا رئيسيّة منشورة لقناة `app` — وهي حالةٌ طبيعيّة لا
  /// عطل: رئيسيّة كلّ متجرٍ اليوم للويب. والمستودع يترجمها إلى `null`.
  Future<Map<String, dynamic>> fetchAppHomeLayout() {
    return _apiClient.getMap(ApiRoutes.cmsHome);
  }

  /// تنقّل التطبيق من اللوحة (المهمّة 1.6).
  Future<Map<String, dynamic>> fetchAppNavigation() {
    return _apiClient.getMap(ApiRoutes.cmsAppNavigation);
  }

  Future<List<dynamic>> fetchTrendingProducts() {
    return _apiClient.getList(ApiRoutes.catalogTrends);
  }

  // أرفف الاكتشاف مُصفّاةً بتبويب القسم: { tabs, activeCategory, sections }
  Future<Map<String, dynamic>> fetchDiscover(String category) {
    return _apiClient.getMap(
      ApiRoutes.catalogDiscover,
      queryParameters: {'category': category},
    );
  }

  // صفحةٌ من رفٍّ واحد («عرض الكل»).
  Future<Map<String, dynamic>> fetchDiscoverSection(
    String key, {
    required String category,
    required int page,
  }) {
    return _apiClient.getMap(
      '${ApiRoutes.catalogDiscover}/$key',
      queryParameters: {'category': category, 'page': '$page'},
    );
  }

  Future<void> sendProductEvents(List<Map<String, String>> events) {
    return _apiClient.postMap(ApiRoutes.catalogEvents, data: {'events': events});
  }

  // تنقّل المتجر الحقيقيّ (مجموعات المتجر المُدارة): [{id,name,image,href,children}]
  Future<List<dynamic>> fetchNavigation() {
    return _apiClient.getList(ApiRoutes.catalogNavigation);
  }

  // صفحة القسم الخام (تحوي products و heroSlides و heroImage).
  Future<Map<String, dynamic>> fetchCategoryPageRaw(String slug) {
    return _apiClient.getMap('${ApiRoutes.catalogCategories}/$slug');
  }

  /// يجلب منتجاً برمزه الممسوح.
  ///
  /// ‼️ **لا يبتلع الخطأ**: `404` هنا معلومةٌ («لا نبيع هذا») لا عطل، والفرق
  /// بينها وبين انقطاع الشبكة هو الفرق بين رسالتين مختلفتين تماماً للعميل.
  Future<Map<String, dynamic>> fetchProductByBarcode(String code) {
    return _apiClient.getMap('${ApiRoutes.catalogBarcode}/$code');
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
