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
    // كلفة الشحن كما يحسبها الخادم لهذه الطريقة ولهذا المجموع.
    required double shippingCost,
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
    // ‼️ لا تُخمَّن هنا: الخادم يحسب الشحن من إعداداته ويرفض الطلب إن كان
    // حسابه أعلى. المبلغ يأتي من الطريقة التي جلبها التطبيق من الخادم نفسه.
    final shippingAmount = shippingCost;
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

  Future<List<dynamic>> fetchShippingMethods() async {
    final res = await _apiClient.getMap(ApiRoutes.catalogShippingMethods);
    return (res['methods'] as List<dynamic>?) ?? const [];
  }

  Future<Map<String, dynamic>> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
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
        shippingCost: shippingCost,
        paymentMethod: paymentMethod,
        orderReference: orderReference,
        codFee: codFee,
      ),
    );
  }

  /// تابي: إنشاء الجلسة **من الخادم** والحصول على رابط الدفع.
  ///
  /// ‼️ لا من الجهاز عبر حزمة تابي: حمولة الحزمة لا تحمل `merchant_urls`
  /// إطلاقاً، فتقف شاشتها عند «سنعيدك الآن» بلا عنوانٍ تعود إليه بينما المال
  /// مُصرَّحٌ به. وخادمنا يرسلها كما يفعل في الموقع، ويُطبّق التسعير الموثوق
  /// وفحص المخزون قبل أن يرى المشتري تابي.
  Future<Map<String, dynamic>> createTabbySession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    String? buyerEmail,
    String? buyerDob,
  }) {
    return _apiClient.postMap(
      ApiRoutes.tabbySession,
      data: {
        'lang': 'ar',
        'order': _buildOrderPayload(
          items: items,
          address: address,
          shippingMethod: shippingMethod,
          shippingCost: shippingCost,
          paymentMethod: 'Tabby',
          orderReference: orderReference,
          buyerEmail: buyerEmail,
          buyerDob: buyerDob,
        ),
      },
    );
  }

  /// تمارا: إنشاء الجلسة من الخادم → {orderId, checkoutUrl, returnUrls}.
  Future<Map<String, dynamic>> createTamaraSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    String? buyerEmail,
  }) {
    return _apiClient.postMap(
      ApiRoutes.tamaraSession,
      data: {
        'lang': 'ar',
        'order': _buildOrderPayload(
          items: items,
          address: address,
          shippingMethod: shippingMethod,
          shippingCost: shippingCost,
          paymentMethod: 'Tamara',
          orderReference: orderReference,
          buyerEmail: buyerEmail,
        ),
      },
    );
  }

  /// تمارا: التأكيد — الخادم يسأل تمارا ثمّ يُصرّح ويقبض ويُنشئ الطلب.
  Future<Map<String, dynamic>> confirmTamaraPayment(String orderId) {
    return _apiClient.postMap(ApiRoutes.tamaraConfirm, data: {'orderId': orderId});
  }

  // نون: إنشاء الطلب والحصول على رابط الدفع المستضاف (يُفتح في webview).
  Future<Map<String, dynamic>> initiateNoon({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    String? buyerEmail,
  }) {
    final orderReference = 'NOON-${DateTime.now().millisecondsSinceEpoch}';
    return _apiClient.postMap(
      ApiRoutes.noonInitiate,
      data: _buildOrderPayload(
        items: items,
        address: address,
        shippingMethod: shippingMethod,
        shippingCost: shippingCost,
        paymentMethod: 'noon',
        orderReference: orderReference,
        buyerEmail: buyerEmail,
      ),
    );
  }

  // نون: تحقّق/تسوية بعد إغلاق webview (الخادم يسأل نون مباشرةً).
  Future<Map<String, dynamic>> verifyNoon(String noonOrderId) {
    return _apiClient.getMap('${ApiRoutes.noonVerify}/$noonOrderId');
  }

  Future<Map<String, dynamic>> registerPendingTabbyOrder({
    required String paymentId,
    String? paymentToken,
    String? sessionId,
    required String orderReference,
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
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
          shippingCost: shippingCost,
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
    required double shippingCost,
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
          shippingCost: shippingCost,
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
