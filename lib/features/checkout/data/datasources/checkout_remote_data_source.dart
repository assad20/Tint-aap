import '../../../../app/config/api_routes.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/network/api_client.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _buildOrderPayload({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required String paymentMethod,
    required String orderReference,
    String? paymentId,
    String? paymentToken,
    String? sessionId,
    String? buyerEmail,
    String? buyerDob,
    double codFee = 0,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final shippingAmount = shippingMethod == 'smsa' ? 0.0 : 25.0;
    // ‼️ رسوم الدفع عند الاستلام تُضاف للإجماليّ المُرسَل. الخادم يعيد الحساب
    // ويرفض الطلب إن كان حسابه أعلى من حساب العميل — فإغفالها يعني رفض كلّ طلب COD.
    final total = subtotal + shippingAmount + codFee;

    return {
      'externalOrderId': orderReference,
      'salesChannel': 'mobile',
      'currency': 'SAR',
      'paymentMethod': paymentMethod,
      'paymentReference': paymentId,
      'paymentToken': paymentToken,
      'tabbySessionId': sessionId,
      'customer': {
        'name': address.recipient,
        'email': buyerEmail,
        'phone': address.mobile,
        'dob': buyerDob,
      },
      // نُرسل الحقول المسموح بها في CheckoutAddressDto فقط — الخادم صارم
      // (forbidNonWhitelisted) ويرفض isDefault/country التي يضمّها toJson().
      'address': {
        'id': address.id,
        'title': address.title,
        'recipient': address.recipient,
        'mobile': address.mobile,
        'city': address.city,
        'neighborhood': address.neighborhood,
        'details': address.details,
        if (address.lat != null) 'lat': address.lat,
        if (address.lng != null) 'lng': address.lng,
      },
      'shippingMethod': shippingMethod,
      'totals': {
        'subtotal': subtotal,
        'shipping': shippingAmount,
        'discount': 0,
        if (codFee > 0) 'codFee': codFee,
        'total': total,
      },
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'sku': item.product.id,
              'title': item.product.title,
              'brand': item.product.brand,
              'category': item.product.category,
              'image': item.product.image,
              'quantity': item.quantity,
              'unitPrice': item.product.price,
              'variant': item.variant,
            },
          )
          .toList(),
    };
  }

  // وسائل الدفع المفعّلة من الخادم (المصدر الوحيد الموثوق للرسوم).
  Future<List<dynamic>> fetchPaymentMethods() async {
    final res = await _apiClient.getMap(ApiRoutes.catalogPaymentMethods);
    return (res['methods'] as List<dynamic>?) ?? const [];
  }

  Future<Map<String, dynamic>> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required String paymentMethod,
    double codFee = 0,
  }) {
    final orderReference = 'TN-${DateTime.now().millisecondsSinceEpoch}';

    return _apiClient.postMap(
      ApiRoutes.checkout,
      data: _buildOrderPayload(
        items: items,
        address: address,
        shippingMethod: shippingMethod,
        paymentMethod: paymentMethod,
        orderReference: orderReference,
        codFee: codFee,
      ),
    );
  }

  Future<Map<String, dynamic>> registerPendingTabbyOrder({
    required String paymentId,
    String? paymentToken,
    String? sessionId,
    required String orderReference,
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required String buyerEmail,
    required String buyerDob,
  }) {
    return _apiClient.postMap(
      ApiRoutes.tabbyRegisterPending,
      data: {
        'paymentId': paymentId,
        'paymentToken': paymentToken,
        'sessionId': sessionId,
        'order': _buildOrderPayload(
          items: items,
          address: address,
          shippingMethod: shippingMethod,
          paymentMethod: 'Tabby',
          orderReference: orderReference,
          paymentId: paymentId,
          paymentToken: paymentToken,
          sessionId: sessionId,
          buyerEmail: buyerEmail,
          buyerDob: buyerDob,
        ),
      },
    );
  }

  Future<Map<String, dynamic>> confirmTabbyPayment({
    required String paymentId,
    String? paymentToken,
    String? sessionId,
    required String orderReference,
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required String buyerEmail,
    required String buyerDob,
  }) {
    return _apiClient.postMap(
      ApiRoutes.tabbyConfirm,
      data: {
        'paymentId': paymentId,
        'paymentToken': paymentToken,
        'sessionId': sessionId,
        'order': _buildOrderPayload(
          items: items,
          address: address,
          shippingMethod: shippingMethod,
          paymentMethod: 'Tabby',
          orderReference: orderReference,
          paymentId: paymentId,
          paymentToken: paymentToken,
          sessionId: sessionId,
          buyerEmail: buyerEmail,
          buyerDob: buyerDob,
        ),
      },
    );
  }
}
