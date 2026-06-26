import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/catalog_repository.dart';

class SearchState {
  const SearchState({
    this.isLoading = false,
    this.query = '',
    this.results = const [],
  });

  final bool isLoading;
  final String query;
  final List<ProductModel> results;

  SearchState copyWith({
    bool? isLoading,
    String? query,
    List<ProductModel>? results,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      results: results ?? this.results,
    );
  }
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required CatalogRepository repository,
  })  : _repository = repository,
        super(const SearchState());

  final CatalogRepository _repository;

  Future<void> search(String query, {AppPreferences? preferences}) async {
    emit(state.copyWith(isLoading: true, query: query));
    final results = await _repository.searchProducts(query);
    if (preferences != null && query.trim().isNotEmpty) {
      await preferences.pushRecentSearch(query.trim());
    }
    emit(state.copyWith(isLoading: false, results: results));
  }

  void clear() => emit(const SearchState());
}
