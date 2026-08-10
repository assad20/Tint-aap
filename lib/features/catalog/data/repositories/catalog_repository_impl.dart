import '../../../../core/models/app_navigation_model.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/cms_page_model.dart';
import '../../../../core/models/discover_model.dart';
import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/network/api_exception.dart';
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
      // بانرات السلايدر. نُفضّل `mobileImage` — الصورة التي يرفعها الأدمن
      // بمقاس التطبيق — ونسقط على `image` (مقاس سطح المكتب) إن لم تُرفع.
      final banners = <String>[];
      for (final s in (data['heroSlides'] as List<dynamic>?) ?? const []) {
        if (s is! Map) continue;
        final mobile = s['mobileImage'];
        final wide = s['image'];
        final chosen = (mobile is String && mobile.isNotEmpty)
            ? mobile
            : (wide is String && wide.isNotEmpty ? wide : null);
        if (chosen != null) banners.add(chosen);
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
  Future<HomeLayoutFetch> fetchAppHomeLayout() async {
    try {
      final raw = await _remoteDataSource.fetchAppHomeLayout();
      // ‼️ صفحةٌ بلا أقسامٍ **مفهومة** = لا تخطيط. قد تكون كلّ أقسامها أحدث من
      //    هذه النسخة (`minAppVersion`)، والعرض حينها شاشةٌ بيضاء بينما
      //    الرئيسيّة الرسميّة تعمل. وهو **حكمٌ** لا عُطل: يُمحى المخزَّن.
      return CmsPageModel.fromJson(raw).sections.isEmpty
          ? const HomeLayoutFetch.none()
          : HomeLayoutFetch.ok(raw);
    } on ApiException catch (error) {
      /**
       * ‼️ **٤٠٤ حكمٌ لا عُطل.**
       *
       * كان يُجمَع مع الانقطاع تحت `null` ⇒ «أبقِ ما يعمل». فرئيسيّةٌ يحذفها
       * المالك من اللوحة تبقى على كلّ جهازٍ خزّنها **بلا نهاية**: لا صلاحيّة
       * تنتهي ولا شيء يمحوها، وفيها روابط لأقسامٍ وعروضٍ انتهت. والجهاز الذي
       * لم يرَها قطّ يعرض الرسميّة — فيختلف جهازان في المتجر نفسه بلا سببٍ ظاهر.
       *
       * وما عدا ٤٠٤ (500 · مهلة · 502) عُطلٌ مؤقّت ⇒ يبقى المعروض.
       */
      return error.statusCode == 404
          ? const HomeLayoutFetch.none()
          : const HomeLayoutFetch.unavailable();
    } catch (_) {
      // جسمٌ تالف أو خطأ غير متوقّع: لا حكم ⇒ أبقِ المعروض.
      return const HomeLayoutFetch.unavailable();
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchAppNavigation() async {
    try {
      final raw = await _remoteDataSource.fetchAppNavigation();
      // تنقّلٌ بلا عنصرٍ واحد = لا تنقّل: لا نمحو المعروض بفراغٍ وصل من الشبكة.
      return AppNavigationModel.fromJson(raw).isEmpty ? null : raw;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HeroSlideModel>?> fetchHomeHeroSlides() async {
    try {
      final data = await _remoteDataSource.fetchHome();
      final hero = data['hero'];
      if (hero is! Map) return const [];
      final slides = hero['slides'];
      if (slides is! List) return const [];
      return slides
          .whereType<Map<String, dynamic>>()
          .map(HeroSlideModel.fromJson)
          .where((s) => s.image.isNotEmpty)
          .toList();
    } catch (_) {
      // فشل الجلب — لا نُفرّغ السلايدر المعروض. ولا بيانات تجريبيّة في بانر
      // المتجر: صورة أجنبيّة في متجر المالك أسوأ من فراغ.
      return null;
    }
  }

  @override
  Future<DiscoverFeed?> fetchDiscover(String category) async {
    try {
      return DiscoverFeed.fromJson(await _remoteDataSource.fetchDiscover(category));
    } catch (_) {
      // فشل الجلب — لا نُفرّغ الأرفف المعروضة. والفراغ الحقيقيّ يصل كخلاصةٍ
      // بلا أرفف، وهو ما يميّزه المستدعي عن `null`.
      return null;
    }
  }

  @override
  Future<DiscoverSectionPage?> fetchDiscoverSection(
    String key, {
    required String category,
    required int page,
  }) async {
    try {
      final data = await _remoteDataSource.fetchDiscoverSection(
        key,
        category: category,
        page: page,
      );
      return DiscoverSectionPage.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> recordSignal(String productId, ProductSignalType type) async {
    if (productId.isEmpty) return;
    try {
      await _remoteDataSource.sendProductEvents([
        {'productId': productId, 'type': type.wire},
      ]);
    } catch (_) {
      // القياس صامت عمداً: لا رسالة خطأ ولا إعادة محاولة. فشلُه يُفقدنا نقطةً
      // في رفٍّ، بينما إظهاره يُفسد على المستخدم فعلاً نجح فعلاً.
    }
  }

  /// ‼️ بلا تراجُعٍ إلى بيانات تجريبيّة.
  ///
  /// كان البحث يخترع نتائج حين لا يجد الخادم شيئاً أو حين يفشل النداء — فيُقدَّم
  /// للمتسوّق منتجٌ لا وجود له في الكتالوج، **لا يستطيع شراءه أبداً** (الخادم
  /// لا يعرف معرّفه فيرفض الطلب). و«لا نتائج» أصدق من نتيجةٍ مختلَقة.
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final items = await _remoteDataSource.searchProducts(query);
      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      return const <ProductModel>[];
    }
  }
}
