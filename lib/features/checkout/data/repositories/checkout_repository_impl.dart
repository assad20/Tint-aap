import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../domain/models/tabby_payment_result.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_data_source.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl({
    required CheckoutRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CheckoutRemoteDataSource _remoteDataSource;

  @override
  Future<List<PaymentMethodModel>> fetchPaymentMethods() async {
    final raw = await _remoteDataSource.fetchPaymentMethods();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PaymentMethodModel.fromJson)
        .toList();
  }

  @override
  Future<String> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
    required String shippingMethod,
    required String paymentMethod,
    double codFee = 0,
  }) async {
    final response = await _remoteDataSource.submitOrder(
      items: items,
      address: address,
      shippingMethod: shippingMethod,
      paymentMethod: paymentMethod,
      codFee: codFee,
    );

    return response['orderId']?.toString() ??
        response['externalOrderId']?.toString() ??
        'TN-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
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
  }) async {
    await _remoteDataSource.registerPendingTabbyOrder(
      paymentId: paymentId,
      paymentToken: paymentToken,
      sessionId: sessionId,
      orderReference: orderReference,
      items: items,
      address: address,
      shippingMethod: shippingMethod,
      buyerEmail: buyerEmail,
      buyerDob: buyerDob,
    );
  }

  @override
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
  }) async {
    final response = await _remoteDataSource.confirmTabbyPayment(
      paymentId: paymentId,
      paymentToken: paymentToken,
      sessionId: sessionId,
      orderReference: orderReference,
      items: items,
      address: address,
      shippingMethod: shippingMethod,
      buyerEmail: buyerEmail,
      buyerDob: buyerDob,
    );

    return TabbyConfirmationResult.fromJson(response);
  }
}
