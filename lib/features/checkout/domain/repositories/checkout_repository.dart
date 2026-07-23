import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/payment_method_model.dart';
import '../models/tabby_payment_result.dart';

abstract class CheckoutRepository {
  /// وسائل الدفع المفعّلة (+ رسومها) من الخادم.
  Future<List<PaymentMethodModel>> fetchPaymentMethods();

  Future<String> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
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
    required String buyerEmail,
    required String buyerDob,
  });
}
