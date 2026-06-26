import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/catalog_repository.dart';

class HomeStoreState {
  const HomeStoreState({
    this.isLoading = true,
    this.activeTopNav = 'الرئيسية',
    this.catalog = const {},
    this.errorMessage,
  });

  final bool isLoading;
  final String activeTopNav;
  final Map<String, List<ProductModel>> catalog;
  final String? errorMessage;

  HomeStoreState copyWith({
    bool? isLoading,
    String? activeTopNav,
    Map<String, List<ProductModel>>? catalog,
    String? errorMessage,
  }) {
    return HomeStoreState(
      isLoading: isLoading ?? this.isLoading,
      activeTopNav: activeTopNav ?? this.activeTopNav,
      catalog: catalog ?? this.catalog,
      errorMessage: errorMessage,
    );
  }

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
      final catalog = await _catalogRepository.fetchBootstrapCatalog();
      emit(
        state.copyWith(
          isLoading: false,
          catalog: catalog,
          errorMessage: null,
        ),
      );
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
  }

  List<ProductModel> productsOf(String key) => state.catalog[key] ?? const [];
}
