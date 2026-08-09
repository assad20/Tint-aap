import '../../../../core/models/category_model.dart';
import '../../../../core/models/discover_model.dart';
import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/models/product_model.dart';

// صفحة القسم: منتجاته + بانرات السلايدر (heroSlides المُدارة من الأدمن).
class CategoryPageResult {
  const CategoryPageResult({required this.products, required this.banners});
  final List<ProductModel> products;
  final List<String> banners; // روابط صور السلايدر
}

abstract class CatalogRepository {
  Future<Map<String, List<ProductModel>>> fetchBootstrapCatalog();

  // ‼️ أُزيلت `fetchQuickLinks` و`fetchSidebarCategories`: لم يكن لهما مُستدعٍ
  // واحد، وكانتا تُعيدان `FakeSeedData` — بابٌ مفتوحٌ لتسرّب بياناتٍ مخترعة
  // إلى الواجهة متى استُعملتا. التنقّل الحقيقيّ يأتي من `/catalog/navigation`.

  Future<List<ProductModel>> fetchTrendingProducts();

  Future<List<ProductModel>> searchProducts(String query);

  // تنقّل المتجر الحقيقيّ (مجموعات المتجر).
  Future<List<CategoryModel>> fetchNavigation();

  // منتجات القسم + بانرات السلايدر في نداء واحد.
  Future<CategoryPageResult> fetchCategoryPage(String slug);

  // شرائح سلايدر الرئيسيّة (بنرات موضع `hero` المُدارة من استوديو البنرات).
  // `null` = تعذّر الجلب (أبقِ المعروض)، بينما `[]` = لا بنرات مُعرَّفة فعلاً
  // (أخفِ السلايدر). التفريق ضروريّ وإلّا بقيت بنراتٌ حُذفت من اللوحة ظاهرةً.
  Future<List<HeroSlideModel>?> fetchHomeHeroSlides();

  /// تخطيط رئيسيّة التطبيق من اللوحة (SDUI) — **خاماً كما وصل**.
  ///
  /// `null` = **لا تخطيط لهذه القناة** (404) أو تعذّر الجلب ⇒ يبقى المعروض.
  ///
  /// ‼️ يُعيد الخام لا `CmsPageModel`: الطبقة العليا تحتاجه نصّاً لتخزّنه، وحارس
  /// `minAppVersion` يجب أن يُعاد تطبيقه عند كلّ قراءة لا أن يُجمَّد في الكاش.
  Future<Map<String, dynamic>?> fetchAppHomeLayout();

  /// تنقّل التطبيق من اللوحة — **خاماً** للسبب نفسه: يُخزَّن ويُعاد تحليله.
  /// `null` = تعذّر الجلب ⇒ يبقى المعروض.
  Future<Map<String, dynamic>?> fetchAppNavigation();

  // أرفف الاكتشاف لقسمٍ بعينه ('all' = الكلّ).
  // `null` = تعذّر الجلب (أبقِ المعروض)، بينما خلاصةٌ بلا أرفف = لا إشارات بعد.
  Future<DiscoverFeed?> fetchDiscover(String category);

  // صفحةٌ من رفٍّ واحد للتمرير اللانهائيّ في «عرض الكل».
  Future<DiscoverSectionPage?> fetchDiscoverSection(
    String key, {
    required String category,
    required int page,
  });

  // تسجيل تفاعل. لا يرمي أبداً: فشل قياسٍ لا يجوز أن يُفسد فعل المستخدم.
  Future<void> recordSignal(String productId, ProductSignalType type);
}
