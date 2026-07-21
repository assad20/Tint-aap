import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';

class CategoriesState {
  const CategoriesState({
    this.isLoading = true,
    this.categories = const [],
    this.selected,
    this.products = const [],
    this.isProductsLoading = false,
  });

  final bool isLoading;
  // أقسام المتجر الحقيقيّة (/catalog/navigation).
  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final List<ProductModel> products;
  final bool isProductsLoading;

  CategoriesState copyWith({
    bool? isLoading,
    List<CategoryModel>? categories,
    CategoryModel? selected,
    List<ProductModel>? products,
    bool? isProductsLoading,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      selected: selected ?? this.selected,
      products: products ?? this.products,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
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
    final cats = await _repository.fetchNavigation();
    emit(state.copyWith(isLoading: false, categories: cats));
    if (cats.isNotEmpty) {
      await select(cats.first);
    }
  }

  Future<void> select(CategoryModel category) async {
    emit(state.copyWith(
      selected: category,
      isProductsLoading: true,
      products: const [],
    ));
    final products = await _repository.fetchCategoryProducts(category.id);
    if (state.selected?.id != category.id) return; // تغيّر الاختيار أثناء الجلب
    emit(state.copyWith(isProductsLoading: false, products: products));
  }
}
