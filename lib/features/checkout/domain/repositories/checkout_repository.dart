import '../../../../core/models/apple_pay_config_model.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../../../core/models/shipping_method_model.dart';
import '../models/tabby_payment_result.dart';

abstract class CheckoutRepository {
  /// وسائل الدفع المفعّلة (+ رسومها) من الخادم.
  Future<List<PaymentMethodModel>> fetchPaymentMethods();

  Future<List<ShippingMethodModel>> fetchShippingMethods();

  /// تابي: إنشاء الجلسة **من الخادم** → {paymentId, sessionId, webUrl, returnUrls}.
  Future<Map<String, dynamic>> createTabbySession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    String? buyerEmail,
    String? buyerDob,
  });

  /// تمارا: إنشاء الجلسة من الخادم → {orderId, checkoutUrl, returnUrls}.
  Future<Map<String, dynamic>> createTamaraSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    String? buyerEmail,
  });

  /// تمارا: التأكيد — يُنادى عند العودة وعند الإغلاق اليدويّ معاً.
  Future<Map<String, dynamic>> confirmTamaraPayment(String orderId);

  /// آبل باي: إعداد الشريحة من الخادم — و`available` وحده يقرّر ظهور الزرّ.
  Future<ApplePayConfigModel> fetchApplePayConfig();

  /// آبل باي: تنفيذ الدفع بتوكن الشريحة → ردّ الخادم كما هو (`orderId` دليلُه).
  Future<Map<String, dynamic>> payWithApplePay({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    required Map<String, dynamic> applePayToken,
    required String sheetTotal,
    String? buyerEmail,
  });

  /// PayTabs: إنشاء صفحة الدفع → {cartId, tranRef, redirectUrl}.
  Future<Map<String, dynamic>> createPayTabsSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String orderReference,
    String? buyerEmail,
  });

  /// PayTabs: التأكيد — يُنادى عند العودة وعند الإغلاق اليدويّ معاً.
  Future<Map<String, dynamic>> confirmPayTabsPayment(String cartId, {String? tranRef});

  /// نون: إنشاء الطلب → {checkoutUrl, noonOrderId}.
  Future<Map<String, dynamic>> initiateNoon({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    String? buyerEmail,
  });

  /// نون: تحقّق من الحالة بعد webview → {ok, status, orderId?}.
  Future<Map<String, dynamic>> verifyNoon(String noonOrderId);

  Future<String> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required double shippingCost,
    required String paymentMethod,
    double codFee,
  });

  Future<void> registerPendingTabbyOrder({
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
  });

  Future<TabbyConfirmationResult> confirmTabbyPayment({
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
  });
}
