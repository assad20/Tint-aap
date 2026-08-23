import 'dart:async';
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
    this.activeCategorySlug = '',
    this.openableExtras = const {},
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

  /// مُعرّف القسم المعروض فعلاً — وقد **لا يساوي** [activeTopNav].
  ///
  /// ‼️ فتحُ قسمٍ ابن («قهوة») يُبرز أباه في الشريط («سوبر ماركت») ويعرض
  /// منتجات الابن. فالاسم المُبرَز مرساةٌ للعميل، وهذا المُعرّف هو المعروض —
  /// وحارسُ الجلب يُقارن به لا بالاسم، وإلّا لأسقط نتيجةً صحيحة لأنّ الاسم
  /// لم يتغيّر بين ابنَين لأبٍ واحد.
  final String activeCategorySlug;

  /// أقسامٌ **خارج شجرة التنقّل** ثبت أنّها تُفتَح — مُعرّفها ← اسمها المعروض.
  ///
  /// ‼️ لوحةُ الإدارة تسمح بإخفاء قسمٍ **من القائمة وحدها** وبيعُه قائم. وقسمٌ
  /// كهذا لا يصل شجرة التنقّل، فوضعُه في شبكة الرئيسيّة كان يُنتج مربّعاً
  /// صامتاً — نفس العطل الذي أُصلح، من بابٍ آخر.
  final Map<String, String> openableExtras;

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
    String? activeCategorySlug,
    Map<String, String>? openableExtras,
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
      activeCategorySlug: activeCategorySlug ?? this.activeCategorySlug,
      openableExtras: openableExtras ?? this.openableExtras,
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
    await _refreshFromNetwork(hasVisibleContent: cached != null);
  }

  /// سحبٌ للتحديث — **بلا `isLoading`**.
  ///
  /// ‼️ **ولهذا لم تُستدعَ `bootstrap` نفسها.** الرئيسيّة تستبدل محتواها كلّه
  /// بدوّارةٍ ما دام `isLoading` مرفوعاً (`home_page.dart`)، فلو نادى السحبُ
  /// الإقلاعَ لاختفت الصفحة تحت إصبع المستخدم لحظةَ سحبها ثمّ عادت — وهو أسوأ
  /// ممّا لو لم يُحدَّث شيء. و`RefreshIndicator` يرسم مؤشّره بنفسه، فمؤشّرٌ
  /// ثانٍ زيادةٌ لا فائدة فيها.
  ///
  /// ‼️ **ولا تُقرأ اللقطة المخزَّنة هنا.** قراءتها في الإقلاع تُخفي بُعد الخادم؛
  /// وقراءتها في التحديث تعني إحلال **الأقدم** محلّ المعروض قبل وصول الأحدث.
  ///
  /// **ولماذا وُجد هذا أصلاً:** `bootstrap()` تُنادى مرّةً واحدة عند إنشاء
  /// التطبيق (`main.dart`) — فمن كان تطبيقه مفتوحاً لا يرى صفحةً نُشرت للتوّ من
  /// اللوحة حتّى يُغلقه ويفتحه. والسحب يجعل التحديث بيده.
  Future<void> refresh() => _refreshFromNetwork(hasVisibleContent: true);

  /// الجلب المشترك بين الإقلاع والسحب.
  ///
  /// `hasVisibleContent` تحكم رسالة الخطأ وحدها: من يرى محتوًى معروضاً لا يُصدَم
  /// برسالة فشلٍ تحته — يبقى ما يراه، ويُعاد المحاولة. ومن لا يرى شيئاً يجب أن
  /// يُخبَر لئلّا ينتظر أمام فراغ.
  Future<void> _refreshFromNetwork({required bool hasVisibleContent}) async {
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
          errorMessage: hasVisibleContent ? null : 'تعذّر تحميل الكتالوج',
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
      // ‼️ **بعد وصول التخطيط والتنقّل معاً** — يحتاج الاثنين ليعرف ما ينقص.
      unawaited(_probeExtraCategories());
    } catch (error) {
      // خطأ غير متوقّع: أبقِ اللقطة المعروضة إن وُجدت.
      emit(state.copyWith(
        isLoading: false,
        errorMessage: hasVisibleContent ? null : error.toString(),
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
        activeCategorySlug: '',
        isCategoryLoading: false,
      ));
    } else {
      await _loadCategory(value);
    }
  }

  /// هل يستطيع التطبيق فتح هذا القسم؟ — **سؤالٌ بلا أثر**.
  ///
  /// ‼️ يُسأل قبل رسم الزرّ (انظر `tapFor`)، فلا يجوز أن يُبدّل حالةً ولا أن
  /// يجلب شيئاً.
  bool canOpenCategory(String id) {
    final target = id.trim();
    if (target.isEmpty) return false;
    if (state.topNav.any((c) => c.id == target)) return true;
    if (_pathToCategory(target).isNotEmpty) return true;
    // قسمٌ مخفيٌّ من القائمة وثبت بالفحص أنّه يُفتَح.
    return state.openableExtras.containsKey(target);
  }

  /// يفتح قسماً بمعرّفه **أيّاً كان موضعه في الشجرة** — أباً كان أو ابناً.
  ///
  /// ‼️ **العلّة التي عالجها**: كان البحث في `topNav` وحدها — وهي المستوى
  /// الأعلى فقط. فتسعةٌ من اثني عشر قسماً في شبكة الرئيسيّة («قهوة» ·
  /// «منتجات ورقيّة» · «الصحة العامة» …) أبناءٌ لا تظهر هناك، فيعود المُنفِّذ
  /// `false` ⇒ **لا يُركَّب `onTap` أصلاً** ⇒ يُضغط المربّع ولا يحدث شيء، بلا
  /// خطأٍ ولا سطر سجلّ. (بلاغ المالك بالتشغيل — والدليل أنّ «ديرما رولر»
  /// كانت تعمل وحدها لأنّها في الشريط.)
  ///
  /// ‼️ **والشريط يُبرز الأب**: «قهوة» ليست فيه، فيُضاء «سوبر ماركت» وتُعرض
  /// منتجات «قهوة». وإبرازُ لا شيء كان يترك العميل بلا مرساة.
  Future<bool> openCategoryById(String id) async {
    final target = id.trim();
    if (target.isEmpty) return false;

    // قسمٌ في الشريط يُفتَح بمساره القديم كما هو — لا نُغيّر ما يعمل.
    for (final category in state.topNav) {
      if (category.id == target) {
        await setActiveTopNav(category.name);
        return true;
      }
    }

    final path = _pathToCategory(target);
    if (path.isEmpty) {
      // ‼️ **خارج الشجرة**: لا أبَ يُبرَز، فيُعرَض اسم القسم نفسه في الشريط.
      //    ولن يُضيء تبويباً — وهذا أصدق من إضاءة تبويبٍ لا علاقة له بالمعروض.
      final label = state.openableExtras[target];
      if (label == null) return false;
      await _appPreferences.setActiveHomeNav(label);
      emit(state.copyWith(activeTopNav: label, activeCategorySlug: target));
      await _fetchCategoryPage(target);
      return true;
    }

    // الجذر يُبرَز باسمه في الشريط إن كان له نظير هناك، وإلّا بعنوانه كما هو.
    final root = path.first;
    final barName = state.topNav
        .firstWhere(
          (c) => c.id == root.id || c.id == root.actionValue,
          orElse: () => CategoryModel(id: '', name: root.label, image: ''),
        )
        .name;

    await _appPreferences.setActiveHomeNav(barName);
    emit(state.copyWith(activeTopNav: barName, activeCategorySlug: target));
    await _fetchCategoryPage(target);
    return true;
  }

  /// يفحص أقسام تخطيط الرئيسيّة التي **ليست في شجرة التنقّل**، ويُثبت ما
  /// يُفتَح منها فعلاً.
  ///
  /// ‼️ **يُسأل الكتالوج مرّةً لا عند كلّ نقرة**: المُنفِّذ يُسأل قبل رسم الزرّ
  /// وهو نداءٌ متزامن، فلا مكان لفحصٍ شبكيّ فيه. والفحص هنا **مجّانيّ في
  /// الحالة الشائعة**: متجرٌ كلّ أقسامه في القائمة لا يُنتج نداءً واحداً.
  Future<void> _probeExtraCategories() async {
    final layout = state.homeLayout;
    if (layout == null) return;

    final candidates = <String, String>{};
    for (final section in layout.sections) {
      for (final item in section.items) {
        final action = item['action'];
        String id = '';
        if (action is Map && action['type']?.toString() == 'category') {
          id = action['value']?.toString().trim() ?? '';
        }
        if (id.isEmpty) {
          final href = item['href']?.toString() ?? '';
          const prefix = '/category/';
          if (href.startsWith(prefix)) id = href.substring(prefix.length).trim();
        }
        if (id.isEmpty) continue;
        if (state.topNav.any((c) => c.id == id)) continue;
        if (_pathToCategory(id).isNotEmpty) continue;
        if (state.openableExtras.containsKey(id)) continue;

        final label = (item['name'] ?? item['title'] ?? item['label'])
                ?.toString()
                .trim() ??
            '';
        candidates[id] = label.isEmpty ? id : label;
      }
    }
    if (candidates.isEmpty) return;

    // ‼️ سقفٌ صريح: تخطيطٌ مُفسَد لا يُطلق عشرات النداءات عند كلّ إقلاع.
    final probes = candidates.entries.take(12);
    final confirmed = <String, String>{};
    for (final entry in probes) {
      try {
        final page = await _catalogRepository.fetchCategoryPage(entry.key);
        if (page.products.isNotEmpty || page.banners.isNotEmpty) {
          confirmed[entry.key] = entry.value;
        }
      } catch (_) {
        // قسمٌ لا يردّ ⇒ يبقى صامتاً كما كان. ولا يُرمى: هذا فحصٌ خلفيّ.
      }
    }
    if (confirmed.isEmpty || isClosed) return;
    emit(state.copyWith(
      openableExtras: {...state.openableExtras, ...confirmed},
    ));
  }

  /// مسار القسم من جذر شجرة التنقّل إليه — فارغٌ إن لم يكن فيها.
  List<AppNavItem> _pathToCategory(String id) {
    final roots = state.appNavigation?.drawer ?? const <AppNavItem>[];
    final trail = <AppNavItem>[];

    List<AppNavItem>? walk(List<AppNavItem> nodes) {
      for (final node in nodes) {
        trail.add(node);
        final isTarget = node.id == id ||
            (node.actionType == 'category' && node.actionValue == id);
        if (isTarget) return List<AppNavItem>.of(trail);
        final found = walk(node.children);
        if (found != null) return found;
        trail.removeLast();
      }
      return null;
    }

    return walk(roots) ?? const <AppNavItem>[];
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
        activeCategorySlug: '',
        isCategoryLoading: false,
      ));
      return;
    }
    emit(state.copyWith(activeCategorySlug: slug));
    await _fetchCategoryPage(slug);
  }

  Future<void> _fetchCategoryPage(String slug) async {
    emit(state.copyWith(isCategoryLoading: true));
    // fetchCategoryPage لا fetchCategoryProducts: الأخيرة ترمي بنرات القسم،
    // فكان اختيار قسم من القائمة العلويّة يعرض شبكةً بلا سلايدر بينما تبويب
    // «الأقسام» يعرضه — والبنرات نفسها مربوطة بالأقسام أصلاً من اللوحة.
    final page = await _catalogRepository.fetchCategoryPage(slug);
    // نتجاهل النتيجة إن تغيّر القسم المطلوب أثناء الجلب.
    if (state.activeCategorySlug != slug) return;
    emit(state.copyWith(
      categoryProducts: page.products,
      categoryBanners: page.banners,
      isCategoryLoading: false,
    ));
  }

  List<ProductModel> productsOf(String key) => state.catalog[key] ?? const [];
}
