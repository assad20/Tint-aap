import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.promoCode = '',
  });

  final List<CartItemModel> items;
  final String promoCode;

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  double get shippingCost => subtotal > 300 ? 0 : 25;

  double get total => subtotal + shippingCost;

  CartState copyWith({
    List<CartItemModel>? items,
    String? promoCode,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: promoCode ?? this.promoCode,
    );
  }
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: FakeSeedData.cartItems));

  void increment(String cartId) {
    emit(
      state.copyWith(
        items: state.items
            .map((item) => item.cartId == cartId
                ? item.copyWith(quantity: item.quantity + 1)
                : item)
            .toList(),
      ),
    );
  }

  void decrement(String cartId) {
    emit(
      state.copyWith(
        items: state.items
            .map((item) => item.cartId == cartId
                ? item.copyWith(
                    quantity: item.quantity > 1 ? item.quantity - 1 : 1,
                  )
                : item)
            .toList(),
      ),
    );
  }

  void remove(String cartId) {
    emit(
      state.copyWith(
        items: state.items.where((item) => item.cartId != cartId).toList(),
      ),
    );
  }

  void clear() => emit(const CartState(items: []));

  void applyPromoCode(String value) {
    emit(state.copyWith(promoCode: value));
  }

  void addProduct(ProductModel product, {String variant = 'افتراضي'}) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      final updated = [...state.items];
      final item = updated[existingIndex];
      updated[existingIndex] = item.copyWith(quantity: item.quantity + 1);
      emit(state.copyWith(items: updated));
      return;
    }

    emit(
      state.copyWith(
        items: [
          ...state.items,
          CartItemModel(
            cartId: 'cart_${product.id}_${state.items.length + 1}',
            product: product,
            quantity: 1,
            variant: variant,
          ),
        ],
      ),
    );
  }
}
