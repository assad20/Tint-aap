import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/category_model.dart';
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
    this.categoryProducts = const [],
    this.isCategoryLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String activeTopNav;
  final Map<String, List<ProductModel>> catalog;
  // تنقّل المتجر الحقيقيّ (مجموعات المتجر) — أسماء الأقسام الفعليّة.
  final List<CategoryModel> topNav;
  // منتجات القسم المختار (فارغة على «الرئيسية»).
  final List<ProductModel> categoryProducts;
  final bool isCategoryLoading;
  final String? errorMessage;

  HomeStoreState copyWith({
    bool? isLoading,
    String? activeTopNav,
    Map<String, List<ProductModel>>? catalog,
    List<CategoryModel>? topNav,
    List<ProductModel>? categoryProducts,
    bool? isCategoryLoading,
    String? errorMessage,
  }) {
    return HomeStoreState(
      isLoading: isLoading ?? this.isLoading,
      activeTopNav: activeTopNav ?? this.activeTopNav,
      catalog: catalog ?? this.catalog,
      topNav: topNav ?? this.topNav,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      isCategoryLoading: isCategoryLoading ?? this.isCategoryLoading,
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
    if (cached != null) {
      emit(state.copyWith(
        isLoading: true, // المحتوى ظاهر؛ مؤشّر تحديث خفيف فقط
        catalog: cached.$1,
        topNav: cached.$2,
      ));
    } else {
      emit(state.copyWith(isLoading: true));
    }
    // ② تحديث من الشبكة.
    try {
      final results = await Future.wait([
        _catalogRepository.fetchBootstrapCatalog(),
        _catalogRepository.fetchNavigation(),
      ]);
      final catalog = results[0] as Map<String, List<ProductModel>>;
      final nav = results[1] as List<CategoryModel>;
      final gotData = catalog.isNotEmpty || nav.isNotEmpty;
      if (gotData) {
        emit(state.copyWith(
          isLoading: false,
          catalog: catalog,
          topNav: nav,
          errorMessage: null,
        ));
        await _saveSnapshot(catalog, nav);
      } else {
        // لا بيانات جديدة (فشل/فارغ): أبقِ المعروض (الكاش أو الفارغ)، لا تُفرّغه.
        emit(state.copyWith(
          isLoading: false,
          errorMessage: cached == null ? 'تعذّر تحميل الكتالوج' : null,
        ));
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

  // قراءة لقطة الرئيسيّة المحفوظة (كتالوج + تنقّل). null إن لا لقطة/تلفت.
  (Map<String, List<ProductModel>>, List<CategoryModel>)? _readCachedSnapshot() {
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
      if (catalog.isEmpty && nav.isEmpty) return null;
      return (catalog, nav);
    } catch (_) {
      return null; // كاش تحسينيّ فقط — تجاهل أيّ تلف
    }
  }

  Future<void> _saveSnapshot(
    Map<String, List<ProductModel>> catalog,
    List<CategoryModel> nav,
  ) async {
    try {
      final payload = {
        'catalog': catalog.map(
          (k, v) => MapEntry(k, v.map((p) => p.toJson()).toList()),
        ),
        'nav': nav.map((c) => c.toJson()).toList(),
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
      emit(state.copyWith(categoryProducts: const [], isCategoryLoading: false));
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
      emit(state.copyWith(categoryProducts: const [], isCategoryLoading: false));
      return;
    }
    emit(state.copyWith(isCategoryLoading: true));
    final products = await _catalogRepository.fetchCategoryProducts(slug);
    // نتجاهل النتيجة إن تغيّر التبويب أثناء الجلب.
    if (state.activeTopNav != name) return;
    emit(state.copyWith(categoryProducts: products, isCategoryLoading: false));
  }

  List<ProductModel> productsOf(String key) => state.catalog[key] ?? const [];
}
