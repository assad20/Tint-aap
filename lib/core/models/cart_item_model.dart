import 'product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.variant,
  });

  final String cartId;
  final ProductModel product;
  final int quantity;
  final String variant;

  double get lineTotal => product.price * quantity;

  CartItemModel copyWith({
    String? cartId,
    ProductModel? product,
    int? quantity,
    String? variant,
  }) {
    return CartItemModel(
      cartId: cartId ?? this.cartId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }
}
