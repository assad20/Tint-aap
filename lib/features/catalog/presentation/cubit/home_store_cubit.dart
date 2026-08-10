import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/app_navigation_model.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/cms_page_model.dart';
import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/catalog_repository.dart';

const kHomeNav = 'الرئيسية';

class HomeStoreState {
  const HomeStoreState({
    this.isLoading = true,
    this.activeTopNav = kHomeNav,
    this.catalog = const {},
    this.topNav = const [],
    this.heroSlides = const [],
    this.categoryProducts = const [],
    this.categoryBanners = const [],
    this.isCategoryLoading = false,
    this.homeLayout,
    this.appNavigation,
    this.errorMessage,
  });

  final bool isLoading;
  final String activeTopNav;
  final Map<String, List<ProductModel>> catalog;
  // تنقّل المتجر الحقيقيّ (مجموعات المتجر) — أسماء الأقسام الفعليّة.
  final List<CategoryModel> topNav;
  // شرائح سلايدر الرئيسيّة (بنرات موضع `hero` من الأدمن).
  final List<HeroSlideModel> heroSlides;
  // منتجات القسم المختار (فارغة على «الرئيسية»).
  final List<ProductModel> categoryProducts;
  // بنرات القسم المختار (موضع `category:<slug>`) — تُعرض أعلى الشاشة كما في
  // تبويب «الأقسام»، فاختيار قسم من القائمة العلويّة يُظهر سلايدره أيضاً.
  final List<String> categoryBanners;
  final bool isCategoryLoading;

  /// تخطيط الرئيسيّة من اللوحة (SDUI). `null` ⇒ تُعرَض **الرئيسيّة الرسميّة**
  /// المكتوبة في التطبيق — وهي ملاذُ الرجوع لا شاشةٌ فارغة.
  final CmsPageModel? homeLayout;

  /// تنقّل التطبيق من اللوحة (المهمّة 3.6). `null` = يبقى التنقّل القائم.
  final AppNavigationModel? appNavigation;

  final String? errorMessage;

  HomeStoreState copyWith({
    bool? isLoading,
    String? activeTopNav,
    Map<String, List<ProductModel>>? catalog,
    List<CategoryModel>? topNav,
    List<HeroSlideModel>? heroSlides,
    List<ProductModel>? categoryProducts,
    List<String>? categoryBanners,
    bool? isCategoryLoading,
    CmsPageModel? homeLayout,
    AppNavigationModel? appNavigation,
    String? errorMessage,
    /// ‼️ **المحو يحتاج عَلَماً صريحاً**: `homeLayout: null` لا تُميَّز عن «لم
    /// يُمرَّر»، وهي القاعدة التي تحمي المعروض من الانقطاع. فبلا هذا العَلَم لا
    /// سبيل إلى العودة للرئيسيّة الرسميّة بعد حذف رئيسيّة اللوحة.
    bool clearHomeLayout = false,
  }) {
    return HomeStoreState(
      isLoading: isLoading ?? this.isLoading,
      activeTopNav: activeTopNav ?? this.activeTopNav,
      catalog: catalog ?? this.catalog,
      topNav: topNav ?? this.topNav,
      heroSlides: heroSlides ?? this.heroSlides,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      categoryBanners: categoryBanners ?? this.categoryBanners,
      isCategoryLoading: isCategoryLoading ?? this.isCategoryLoading,
      homeLayout: clearHomeLayout ? null : (homeLayout ?? this.homeLayout),
      appNavigation: appNavigation ?? this.appNavigation,
      errorMessage: errorMessage,
    );
  }

  // أسماء التبويبات: «الرئيسية» + أقسام المتجر الحقيقيّة.
  List<String> get navLabels => [kHomeNav, ...topNav.map((c) => c.name)];

  List<ProductModel> productsOf(String key) => catalog[key] ?? const [];
}

class HomeStoreCubit extends Cubit<HomeStoreState> {
  HomeStoreCubit({
    required CatalogRepository catalogRepository,
    required AppPreferences appPreferences,
  })  : _catalogRepository = catalogRepository,
        _appPreferences = appPreferences,
        super(HomeStoreState(activeTopNav: appPreferences.activeHomeNav));

  final CatalogRepository _catalogRepository;
  final AppPreferences _appPreferences;

  Future<void> bootstrap() async {
    // ① لقطة محفوظة → عرض لحظيّ للرئيسيّة بينما نُحدّث في الخلفيّة (يُخفي بُعد الخادم).
    final cached = _readCachedSnapshot();
    // ‼️ التخطيط المخزَّن يُقرأ ويُعرض قبل أيّ نداء شبكة (2.11): بدونه ترى العينُ
    //    الرئيسيّةَ القديمة ثمّ تقفز إلى تخطيط اللوحة بعد رحلةٍ كاملة.
    final cachedLayout = _readCachedLayout();
    if (cached != null || cachedLayout != null) {
      emit(state.copyWith(
        isLoading: true, // المحتوى ظاهر؛ مؤشّر تحديث خفيف فقط
        catalog: cached?.$1,
        topNav: cached?.$2,
        heroSlides: cached?.$3,
        homeLayout: cachedLayout,
        appNavigation: _readCachedNavigation(),
      ));
    } else {
      emit(state.copyWith(isLoading: true));
    }
    // ② تحديث من الشبكة.
    try {
      final results = await Future.wait([
        _catalogRepository.fetchBootstrapCatalog(),
        _catalogRepository.fetchNavigation(),
        _catalogRepository.fetchHomeHeroSlides(),
        // ‼️ **بالتوازي لا بالتسلسل**: التخطيط نداءٌ رابع في نفس الرحلة، وجعلُه
        //    متسلسلاً يُضيف رحلةً كاملة إلى زمن الإقلاع — والخدمة والقاعدة في
        //    منطقتين (~70ms للرحلة الواحدة).
        _catalogRepository.fetchAppHomeLayout(),
        _catalogRepository.fetchAppNavigation(),
      ]);
      final catalog = results[0] as Map<String, List<ProductModel>>;
      final nav = results[1] as List<CategoryModel>;
      // null = تعذّر الجلب → أبقِ المعروض؛ [] = لا بنرات معرّفة → أخفِ السلايدر.
      final slides = results[2] as List<HeroSlideModel>? ?? state.heroSlides;
      /**
       * ‼️ **ثلاث حالاتٍ لا اثنتان** (انظر `HomeLayoutFetch`):
       *
       * - `ok` ⇒ اعرضه وخزّنه.
       * - `none` ⇒ **الخادم قال لا**: امحُ المخزَّن وارجع إلى الرئيسيّة الرسميّة.
       *   وهذه هي حال «حذفتُ رئيسيّة اللوحة».
       * - `unavailable` ⇒ لا حكم: أبقِ المعروض، فانقطاعُ شبكةٍ لا يجوز أن يُرمى
       *   بالمستخدم إلى الرئيسيّة القديمة بعد أن رأى الجديدة.
       */
      final layoutFetch = results[3] as HomeLayoutFetch;
      final rawLayout = layoutFetch.raw;
      final layout = rawLayout == null ? null : CmsPageModel.fromJson(rawLayout);
      final dropLayout = layoutFetch.status == HomeLayoutStatus.none;
      final rawNav = results[4] as Map<String, dynamic>?;
      final appNav = rawNav == null ? null : AppNavigationModel.fromJson(rawNav);
      final gotData = catalog.isNotEmpty || nav.isNotEmpty;
      if (gotData) {
        emit(state.copyWith(
          isLoading: false,
          catalog: catalog,
          topNav: nav,
          heroSlides: slides,
          homeLayout: layout,
          clearHomeLayout: dropLayout,
          appNavigation: appNav,
          errorMessage: null,
        ));
        await _saveSnapshot(catalog, nav, slides);
      } else {
        // لا بيانات جديدة (فشل/فارغ): أبقِ المعروض (الكاش أو الفارغ)، لا تُفرّغه.
        // ‼️ والتخطيط يُمرَّر هنا أيضاً: هو نداءٌ مستقلّ، وقد ينجح بينما يفشل
        //    الكتالوج — فربطُ مصيره بمصير الكتالوج يُضيّع تخطيطاً وصل سليماً.
        emit(state.copyWith(
          isLoading: false,
          homeLayout: layout,
          clearHomeLayout: dropLayout,
          appNavigation: appNav,
          errorMessage: cached == null ? 'تعذّر تحميل الكتالوج' : null,
        ));
      }

      // ‼️ خارج الفرعين للسبب نفسه.
      if (rawLayout != null) {
        await _saveLayout(rawLayout);
      } else if (dropLayout) {
        // ‼️ **والمحو من القرص لا من الحالة وحدها**: لو بقي المخزَّن لعادت
        //    الرئيسيّة المحذوفة عند الإقلاع التالي قبل وصول أيّ ردّ — فتومض
        //    ثمّ تختفي، أو تبقى كما هي إن كان الجهاز بلا شبكة.
        await _clearLayout();
      }
      if (rawNav != null) {
        await _saveNavigation(rawNav);
      }
      if (state.activeTopNav != kHomeNav) {
        await _loadCategory(state.activeTopNav);
      }
    } catch (error) {
      // خطأ غير متوقّع: أبقِ اللقطة المعروضة إن وُجدت.
      emit(state.copyWith(
        isLoading: false,
        errorMessage: cached == null ? error.toString() : null,
      ));
    }
  }

  // قراءة لقطة الرئيسيّة المحفوظة (كتالوج + تنقّل + شرائح). null إن لا لقطة/تلفت.
  (
    Map<String, List<ProductModel>>,
    List<CategoryModel>,
    List<HeroSlideModel>,
  )? _readCachedSnapshot() {
    final raw = _appPreferences.cachedHomeSnapshot;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final catalog = (decoded['catalog'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList(),
        ),
      );
      final nav = (decoded['nav'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
      // مضافة لاحقاً — لقطة قديمة بلا `slides` تُقرأ بلا كسر.
      final slides = ((decoded['slides'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HeroSlideModel.fromJson)
          .toList();
      if (catalog.isEmpty && nav.isEmpty) return null;
      return (catalog, nav, slides);
    } catch (_) {
      return null; // كاش تحسينيّ فقط — تجاهل أيّ تلف
    }
  }

  /// يقرأ التخطيط المخزَّن ويُعيد تحليله — فيُعاد تطبيق حارس `minAppVersion`
  /// بنسخة التطبيق **الحاليّة** لا بالتي خزّنته.
  CmsPageModel? _readCachedLayout() {
    final raw = _appPreferences.cachedHomeLayout;
    if (raw == null || raw.isEmpty) return null;
    try {
      final page = CmsPageModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return page.sections.isEmpty ? null : page;
    } catch (_) {
      return null; // كاش تحسينيّ — تجاهل أيّ تلف
    }
  }

  /// يقرأ التنقّل المخزَّن ويُعيد تحليله (المهمّة 3.6) — فيعمل التطبيق بلا شبكة.
  AppNavigationModel? _readCachedNavigation() {
    final raw = _appPreferences.cachedAppNavigation;
    if (raw == null || raw.isEmpty) return null;
    try {
      final nav = AppNavigationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return nav.isEmpty ? null : nav;
    } catch (_) {
      return null; // كاش تحسينيّ — تجاهل أيّ تلف
    }
  }

  Future<void> _saveNavigation(Map<String, dynamic> raw) async {
    try {
      await _appPreferences.setCachedAppNavigation(jsonEncode(raw));
    } catch (_) {
      // تجاهل: الكاش تحسينيّ لا يؤثّر على العمل.
    }
  }

  Future<void> _saveLayout(Map<String, dynamic> raw) async {
    try {
      await _appPreferences.setCachedHomeLayout(jsonEncode(raw));
    } catch (_) {
      // تجاهل: الكاش تحسينيّ لا يؤثّر على العمل.
    }
  }

  /// يمحو التخطيط المخزَّن حين **يقول الخادم إنّه لم يعد موجوداً**.
  ///
  /// ‼️ لا يُستدعى عند فشل الجلب أبداً — وإلّا أفرغ انقطاعٌ عابر كاشَ من رأى
  /// تخطيط اللوحة، وهو نقيض الغرض من تخزينه.
  Future<void> _clearLayout() async {
    try {
      await _appPreferences.clearCachedHomeLayout();
    } catch (_) {
      // تجاهل: الحالة في الذاكرة مُحيت أصلاً، والقرص يُصحَّح في الإقلاع التالي.
    }
  }

  Future<void> _saveSnapshot(
    Map<String, List<ProductModel>> catalog,
    List<CategoryModel> nav,
    List<HeroSlideModel> slides,
  ) async {
    try {
      final payload = {
        'catalog': catalog.map(
          (k, v) => MapEntry(k, v.map((p) => p.toJson()).toList()),
        ),
        'nav': nav.map((c) => c.toJson()).toList(),
        'slides': slides.map((s) => s.toJson()).toList(),
      };
      await _appPreferences.setCachedHomeSnapshot(jsonEncode(payload));
    } catch (_) {
      // تجاهل: الكاش تحسينيّ لا يؤثّر على العمل.
    }
  }

  Future<void> setActiveTopNav(String value) async {
    await _appPreferences.setActiveHomeNav(value);
    emit(state.copyWith(activeTopNav: value));
    if (value == kHomeNav) {
      emit(state.copyWith(
        categoryProducts: const [],
        categoryBanners: const [],
        isCategoryLoading: false,
      ));
    } else {
      await _loadCategory(value);
    }
  }

  Future<void> _loadCategory(String name) async {
    final slug = state.topNav
        .firstWhere(
          (c) => c.name == name,
          orElse: () => const CategoryModel(id: '', name: '', image: ''),
        )
        .id;
    if (slug.isEmpty) {
      emit(state.copyWith(
        categoryProducts: const [],
        categoryBanners: const [],
        isCategoryLoading: false,
      ));
      return;
    }
    emit(state.copyWith(isCategoryLoading: true));
    // fetchCategoryPage لا fetchCategoryProducts: الأخيرة ترمي بنرات القسم،
    // فكان اختيار قسم من القائمة العلويّة يعرض شبكةً بلا سلايدر بينما تبويب
    // «الأقسام» يعرضه — والبنرات نفسها مربوطة بالأقسام أصلاً من اللوحة.
    final page = await _catalogRepository.fetchCategoryPage(slug);
    // نتجاهل النتيجة إن تغيّر التبويب أثناء الجلب.
    if (state.activeTopNav != name) return;
    emit(state.copyWith(
      categoryProducts: page.products,
      categoryBanners: page.banners,
      isCategoryLoading: false,
    ));
  }

  List<ProductModel> productsOf(String key) => state.catalog[key] ?? const [];
}
