import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../domain/models/tabby_payment_result.dart';
import '../../domain/repositories/checkout_repository.dart';

class CheckoutState {
  const CheckoutState({
    this.isSubmitting = false,
    this.shippingMethod = 'aramex',
    this.paymentMethod = 'card',
    this.lastOrderId,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String shippingMethod;
  final String paymentMethod;
  final String? lastOrderId;
  final String? errorMessage;

  CheckoutState copyWith({
    bool? isSubmitting,
    String? shippingMethod,
    String? paymentMethod,
    String? lastOrderId,
    String? errorMessage,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      errorMessage: errorMessage,
    );
  }
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({required CheckoutRepository repository})
      : _repository = repository,
        super(const CheckoutState());

  final CheckoutRepository _repository;

  void setShippingMethod(String value) {
    emit(state.copyWith(shippingMethod: value));
  }

  void setPaymentMethod(String value) {
    emit(state.copyWith(paymentMethod: value));
  }

  Future<String> submitOrder({
    required List<CartItemModel> items,
    required AddressModel address,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, lastOrderId: null));
    try {
      final orderId = await _repository.submitOrder(
        items: items,
        address: address,
        shippingMethod: state.shippingMethod,
        paymentMethod: state.paymentMethod,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          lastOrderId: orderId,
        ),
      );
      return orderId;
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> registerPendingTabbyOrder({
    required String paymentId,
    String? paymentToken,
    String? sessionId,
    required String orderReference,
    required List<CartItemModel> items,
    required AddressModel address,
    required String buyerEmail,
    required String buyerDob,
  }) async {
    await _repository.registerPendingTabbyOrder(
      paymentId: paymentId,
      paymentToken: paymentToken,
      sessionId: sessionId,
      orderReference: orderReference,
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      buyerEmail: buyerEmail,
      buyerDob: buyerDob,
    );
  }

  Future<TabbyConfirmationResult> confirmTabbyPayment({
    required String paymentId,
    String? paymentToken,
    String? sessionId,
    required String orderReference,
    required List<CartItemModel> items,
    required AddressModel address,
    required String buyerEmail,
    required String buyerDob,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, lastOrderId: null));
    try {
      final result = await _repository.confirmTabbyPayment(
        paymentId: paymentId,
        paymentToken: paymentToken,
        sessionId: sessionId,
        orderReference: orderReference,
        items: items,
        address: address,
        shippingMethod: state.shippingMethod,
        buyerEmail: buyerEmail,
        buyerDob: buyerDob,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          lastOrderId: result.orderId,
        ),
      );
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }
}
