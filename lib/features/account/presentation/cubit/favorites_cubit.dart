import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../domain/repositories/account_repository.dart';

class FavoritesState {
  const FavoritesState({
    this.isLoading = true,
    this.items = const [],
    this.pending = const {},
  });

  final bool isLoading;
  final List<ProductModel> items;

  /// مُعرّفاتٌ قيد الحفظ — يتجاهل التبديلُ ضغطةً ثانية عليها ريثما يردّ
  /// الخادم، فلا يتسابق نداءان متعارضان على المنتج نفسه.
  final Set<String> pending;

  bool contains(String productId) => items.any((p) => p.id == productId);

  FavoritesState copyWith({
    bool? isLoading,
    List<ProductModel>? items,
    Set<String>? pending,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      pending: pending ?? this.pending,
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

  /// يُبدّل حالة المنتج ويُعيد `true` إن صار مُفضَّلاً — فتقرّر الواجهة رسالتها.
  ///
  /// تفاؤليّ: القلب يمتلئ فوراً ثمّ يُصحَّح من ردّ الخادم. انتظار الشبكة قبل
  /// تلوينه يجعل الضغطة تبدو ضائعةً على اتّصالٍ بطيء.
  Future<bool> toggle(ProductModel product) async {
    final id = product.id;
    if (id.isEmpty || state.pending.contains(id)) return state.contains(id);

    final wasFavorite = state.contains(id);
    final previous = state.items;
    final optimistic = wasFavorite
        ? previous.where((p) => p.id != id).toList()
        : <ProductModel>[product, ...previous];
    emit(state.copyWith(items: optimistic, pending: {...state.pending, id}));

    final saved = wasFavorite
        ? await _repository.removeFavorite(id)
        : await _repository.addFavorite(id);
    if (isClosed) return !wasFavorite;

    emit(state.copyWith(
      // فشل الحفظ يُرجع القائمة كما كانت: قلبٌ ممتلئ بلا حفظٍ كذبٌ على المستخدم.
      items: saved ?? previous,
      pending: {...state.pending}..remove(id),
    ));
    return state.contains(id);
  }
}
