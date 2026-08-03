import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/network/api_client.dart';

/// توفّر بندٍ في السلّة كما يراه الخادم لحظةَ المراجعة.
class CartStockState {
  const CartStockState({required this.sellable, this.available});

  final bool sellable;

  /// `null` = صنف غير متتبَّع ⇒ بلا سقفٍ وبلا حجب.
  final int? available;
}

class CartState {
  const CartState({
    this.items = const [],
    this.promoCode = '',
    this.stock = const {},
    this.checkingStock = false,
  });

  final List<CartItemModel> items;
  final String promoCode;

  /// حالة التوفّر بمفتاح `cartId` — فارغة قبل أوّل مراجعة.
  final Map<String, CartStockState> stock;
  final bool checkingStock;

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  double get shippingCost => subtotal > 300 ? 0 : 25;

  double get total => subtotal + shippingCost;

  /// البنود التي رفضها الخادم (نفدت أو حُجبت أو اختفت).
  List<CartItemModel> get unavailable =>
      items.where((item) => stock[item.cartId]?.sellable == false).toList();

  bool get hasUnavailable => unavailable.isNotEmpty;

  /// الكمّيّة المتاحة لبندٍ بعينه — `null` = بلا سقف.
  int? availableFor(String cartId) => stock[cartId]?.available;

  CartState copyWith({
    List<CartItemModel>? items,
    String? promoCode,
    Map<String, CartStockState>? stock,
    bool? checkingStock,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: promoCode ?? this.promoCode,
      stock: stock ?? this.stock,
      checkingStock: checkingStock ?? this.checkingStock,
    );
  }
}

class CartCubit extends Cubit<CartState> {
  CartCubit({ApiClient? apiClient})
      : _apiClient = apiClient,
        super(const CartState());

  /// اختياريّ كي تبقى السلّة قابلةً للاستعمال في الاختبارات بلا شبكة.
  final ApiClient? _apiClient;

  void increment(String cartId) {
    final cap = state.availableFor(cartId);
    emit(
      state.copyWith(
        items: state.items
            .map((item) => item.cartId == cartId
                // السقف من الخادم لا من رغبة العميل: زيادةٌ فوق المتاح تُرفض
                // عند الدفع، فمنعُها هنا أصدق من السماح بها ثمّ الاعتذار.
                ? (cap != null && item.quantity >= cap
                    ? item
                    : item.copyWith(quantity: item.quantity + 1))
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

  /// يزيل كلّ ما رفضه الخادم دفعةً واحدة — بضغطةٍ لا بحذفٍ صنفاً صنفاً.
  void removeUnavailable() {
    final drop = state.unavailable.map((item) => item.cartId).toSet();
    if (drop.isEmpty) return;
    emit(
      state.copyWith(
        items: state.items.where((item) => !drop.contains(item.cartId)).toList(),
      ),
    );
  }

  void clear() => emit(const CartState(items: []));

  void applyPromoCode(String value) {
    emit(state.copyWith(promoCode: value));
  }

  /// يُعيد `false` إن رُفضت الإضافة لنفاد الكمية — فتقول الواجهة السبب.
  bool addProduct(ProductModel product, {String variant = 'افتراضي'}) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == product.id);

    // الصنف غير المتتبَّع (كميّة `null`) لا يُحجب — نفس قاعدة حارس المخزون.
    final cap = product.quantity;
    final current = existingIndex == -1 ? 0 : state.items[existingIndex].quantity;
    if (cap != null && current + 1 > cap) return false;

    if (existingIndex != -1) {
      final updated = [...state.items];
      final item = updated[existingIndex];
      updated[existingIndex] = item.copyWith(quantity: item.quantity + 1);
      emit(state.copyWith(items: updated));
      return true;
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
    return true;
  }

  /// ─── مراجعة التوفّر ───
  ///
  /// تُنادى عند فتح السلّة وقبل الدفع. الكمّيّة التي وصلت مع بطاقة المنتج قد
  /// تكون قديمة، والصنف قد ينفد بعد إضافته — والخادم يرفض الطلب حينها. هذه
  /// المراجعة تكشفه في السلّة بدل شاشة الدفع.
  ///
  /// ‼️ عند فشل النداء لا يُحجب شيء: عطلٌ عندنا يجب ألّا يمنع بيعاً، وحارس
  /// المخزون في الخادم يبقى الفاصل الأخير.
  Future<void> revalidateStock() async {
    final client = _apiClient;
    final items = state.items;
    if (client == null || items.isEmpty) {
      if (state.stock.isNotEmpty) emit(state.copyWith(stock: const {}));
      return;
    }

    emit(state.copyWith(checkingStock: true));
    try {
      final response = await client.postMap(
        ApiRoutes.catalogAvailability,
        data: {
          'items': items
              .map((item) => {
                    'id': item.product.id,
                    'sku': item.product.sku,
                    'quantity': item.quantity,
                  })
              .toList(),
        },
      );

      final rows = (response['items'] as List?) ?? const [];
      // الخادم يردّ بمعرّف المنتج، والسلّة تُفهرَس بـcartId — فقد يحمل بندان
      // مختلفان نفس المعرّف (متغيّرات) ويأخذان نفس الحالة.
      final byProduct = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          byProduct[row['id']?.toString() ?? ''] = row;
        }
      }

      final next = <String, CartStockState>{};
      for (final item in state.items) {
        final row = byProduct[item.product.id] ?? byProduct[item.product.sku ?? ''];
        if (row == null) continue;
        next[item.cartId] = CartStockState(
          sellable: row['sellable'] == true,
          available: row['available'] == null
              ? null
              : int.tryParse(row['available'].toString()),
        );
      }
      emit(state.copyWith(stock: next, checkingStock: false));
    } catch (_) {
      // صامت عمداً — انظر التعليق أعلاه: لا حجب عند العطل.
      emit(state.copyWith(checkingStock: false));
    }
  }
}
