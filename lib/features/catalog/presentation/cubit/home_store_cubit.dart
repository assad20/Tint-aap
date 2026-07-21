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
    emit(state.copyWith(isLoading: true));
    try {
      // الأقسام الحقيقيّة والكتالوج معاً.
      final results = await Future.wait([
        _catalogRepository.fetchBootstrapCatalog(),
        _catalogRepository.fetchNavigation(),
      ]);
      final catalog = results[0] as Map<String, List<ProductModel>>;
      final nav = results[1] as List<CategoryModel>;
      emit(
        state.copyWith(
          isLoading: false,
          catalog: catalog,
          topNav: nav,
          errorMessage: null,
        ),
      );
      // إن كان التبويب المحفوظ قسماً حقيقيّاً، حمّل منتجاته.
      if (state.activeTopNav != kHomeNav) {
        await _loadCategory(state.activeTopNav);
      }
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
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
