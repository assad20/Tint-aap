import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../domain/repositories/account_repository.dart';

class FavoritesState {
  const FavoritesState({
    this.isLoading = true,
    this.items = const [],
  });

  final bool isLoading;
  final List<ProductModel> items;

  FavoritesState copyWith({
    bool? isLoading,
    List<ProductModel>? items,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({required AccountRepository repository})
      : _repository = repository,
        super(const FavoritesState());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final items = await _repository.fetchFavorites();
    emit(state.copyWith(isLoading: false, items: items));
  }

  void remove(String productId) {
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != productId).toList(),
      ),
    );
  }
}
