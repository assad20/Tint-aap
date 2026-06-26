import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';

class CategoriesState {
  const CategoriesState({
    this.isLoading = true,
    this.sidebar = const [],
    this.catalog = const {},
    this.selectedCategory = 'الفساتين',
  });

  final bool isLoading;
  final List<String> sidebar;
  final Map<String, List<ProductModel>> catalog;
  final String selectedCategory;

  CategoriesState copyWith({
    bool? isLoading,
    List<String>? sidebar,
    Map<String, List<ProductModel>>? catalog,
    String? selectedCategory,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      sidebar: sidebar ?? this.sidebar,
      catalog: catalog ?? this.catalog,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({required CatalogRepository repository})
      : _repository = repository,
        super(const CategoriesState());

  final CatalogRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final sidebar = await _repository.fetchSidebarCategories();
    final catalog = await _repository.fetchBootstrapCatalog();
    emit(
      state.copyWith(
        isLoading: false,
        sidebar: sidebar,
        catalog: catalog,
      ),
    );
  }

  void select(String category) {
    emit(state.copyWith(selectedCategory: category));
  }
}
