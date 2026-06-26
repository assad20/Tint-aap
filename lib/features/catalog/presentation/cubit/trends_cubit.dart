import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';

class TrendsState {
  const TrendsState({
    this.isLoading = true,
    this.products = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<ProductModel> products;
  final String? errorMessage;

  TrendsState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    String? errorMessage,
  }) {
    return TrendsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }
}

class TrendsCubit extends Cubit<TrendsState> {
  TrendsCubit({required CatalogRepository repository})
      : _repository = repository,
        super(const TrendsState());

  final CatalogRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final products = await _repository.fetchTrendingProducts();
    emit(state.copyWith(isLoading: false, products: products));
  }
}
