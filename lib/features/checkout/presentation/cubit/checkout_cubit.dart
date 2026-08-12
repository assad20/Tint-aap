import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../../../core/models/shipping_method_model.dart';
import '../../domain/models/tabby_payment_result.dart';
import '../../domain/repositories/checkout_repository.dart';

class CheckoutState {
  const CheckoutState({
    this.isSubmitting = false,
    this.shippingMethod = 'aramex',
    this.paymentMethod = 'cod',
    this.cardBrand = 'mada',
    this.methods = const [],
    this.methodsLoading = true,
    this.shippingMethods = const [],
    this.lastOrderId,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String shippingMethod;
  final String paymentMethod;

  /// أيّ بطاقةٍ اختار المستخدم داخل PayTabs: `mada` أو `visa`.
  ///
  /// ‼️ **للعرض وحده — والخادم يستقبل `paytabs` في الحالتين.** البطاقتان
  /// تُرسلان المعرّف نفسه، فجعلُ «مُحدَّدة» تعتمد على المعرّف وحده كان يُضيء
  /// الاثنتين معاً (بلاغ المالك 2026-08-12). والتمييز هنا لا في العقد: المزوّد
  /// واحد، والفصل بصريٌّ لأنّ المشتري يبحث عن شعار «مدى» بعينه.
  final String cardBrand;
  // وسائل الدفع المفعّلة من الخادم (المصدر الوحيد للرسوم).
  final List<PaymentMethodModel> methods;
  final bool methodsLoading;

  // طرق الشحن من الخادم — لا تُكتب في التطبيق. كانت مثبَّتةً بأسعارٍ تخالف
  // إعدادات المتجر، فيرفض الخادم كلّ طلبٍ اختير فيه الخيار الأرخص.
  final List<ShippingMethodModel> shippingMethods;

  ShippingMethodModel? get selectedShipping {
    for (final m in shippingMethods) {
      if (m.id == shippingMethod) return m;
    }
    return shippingMethods.isNotEmpty ? shippingMethods.first : null;
  }

  /// كلفة الشحن لهذه السلّة — بنفس قاعدة الخادم (عتبة الشحن المجّانيّ).
  double shippingCostFor(double subtotal) =>
      selectedShipping?.costFor(subtotal) ?? 0;
  final String? lastOrderId;
  final String? errorMessage;

  // رسوم الوسيلة المختارة (0 إن لم تُوجَد) — تُرسَل للخادم ليتطابق الإجماليّ.
  double get selectedFee => methods
      .where((m) => m.id == paymentMethod)
      .fold<double>(0, (_, m) => m.fee);

  /// وسيلة تابي كما أرسلها الخادم — منها مفتاحها ورمز متجرها.
  PaymentMethodModel? get tabbyMethod {
    for (final m in methods) {
      if (m.id == 'tabby') return m;
    }
    return null;
  }

  CheckoutState copyWith({
    bool? isSubmitting,
    String? shippingMethod,
    String? paymentMethod,
    String? cardBrand,
    List<PaymentMethodModel>? methods,
    bool? methodsLoading,
    List<ShippingMethodModel>? shippingMethods,
    String? lastOrderId,
    String? errorMessage,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardBrand: cardBrand ?? this.cardBrand,
      methods: methods ?? this.methods,
      methodsLoading: methodsLoading ?? this.methodsLoading,
      shippingMethods: shippingMethods ?? this.shippingMethods,
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

  // تُستدعى عند فتح السلّة: تجلب الوسائل المفعّلة وتختار أوّلها.
  Future<void> loadPaymentMethods() async {
    emit(state.copyWith(methodsLoading: true));
    try {
      final methods = await _repository.fetchPaymentMethods();
      final selected = methods.any((m) => m.id == state.paymentMethod)
          ? state.paymentMethod
          : (methods.isNotEmpty ? methods.first.id : state.paymentMethod);
      emit(state.copyWith(
        methods: methods,
        methodsLoading: false,
        paymentMethod: selected,
      ));
    } catch (_) {
      emit(state.copyWith(methods: const [], methodsLoading: false));
    }
    await loadShippingMethods();
  }

  // تُستدعى مع وسائل الدفع: الطريقة المختارة تُصحَّح إلى أوّل طريقةٍ يعرفها
  // الخادم إن كانت المحفوظة مجهولةً عنده — وإلّا حسب شحناً غير الذي عرضناه.
  Future<void> loadShippingMethods() async {
    try {
      final methods = await _repository.fetchShippingMethods();
      if (methods.isEmpty) return;
      final selected = methods.any((m) => m.id == state.shippingMethod)
          ? state.shippingMethod
          : methods.first.id;
      emit(state.copyWith(shippingMethods: methods, shippingMethod: selected));
    } catch (_) {
      // تُترك القائمة فارغة؛ الواجهة تعرض حالتها الخاصّة بدل أسعارٍ مخترعة.
    }
  }

  // تابي: إنشاء الجلسة من الخادم (يعيد {paymentId, sessionId, webUrl, returnUrls}).
  Future<Map<String, dynamic>> createTabbySession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String orderReference,
    String? buyerEmail,
    String? buyerDob,
  }) {
    return _repository.createTabbySession(
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
      orderReference: orderReference,
      buyerEmail: buyerEmail,
      buyerDob: buyerDob,
    );
  }

  // تمارا: إنشاء الجلسة من الخادم.
  Future<Map<String, dynamic>> createTamaraSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String orderReference,
    String? buyerEmail,
  }) {
    return _repository.createTamaraSession(
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
      orderReference: orderReference,
      buyerEmail: buyerEmail,
    );
  }

  Future<Map<String, dynamic>> confirmTamaraPayment(String orderId) {
    return _repository.confirmTamaraPayment(orderId);
  }

  // PayTabs: إنشاء صفحة الدفع.
  Future<Map<String, dynamic>> createPayTabsSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required String orderReference,
    String? buyerEmail,
  }) {
    return _repository.createPayTabsSession(
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
      orderReference: orderReference,
      buyerEmail: buyerEmail,
    );
  }

  Future<Map<String, dynamic>> confirmPayTabsPayment(String cartId, {String? tranRef}) {
    return _repository.confirmPayTabsPayment(cartId, tranRef: tranRef);
  }

  // نون: إنشاء الطلب (يعيد {checkoutUrl, noonOrderId}).
  Future<Map<String, dynamic>> initiateNoon({
    required List<CartItemModel> items,
    required AddressModel address,
    String? buyerEmail,
  }) {
    return _repository.initiateNoon(
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
      buyerEmail: buyerEmail,
    );
  }

  // نون: تحقّق من الحالة بعد إغلاق webview.
  Future<Map<String, dynamic>> verifyNoon(String noonOrderId) {
    return _repository.verifyNoon(noonOrderId);
  }

  void setShippingMethod(String value) {
    emit(state.copyWith(shippingMethod: value));
  }

  void setPaymentMethod(String value, {String? cardBrand}) {
    emit(state.copyWith(paymentMethod: value, cardBrand: cardBrand));
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
        shippingCost: state.shippingCostFor(
            items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
        paymentMethod: state.paymentMethod,
        codFee: state.selectedFee,
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
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
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
        shippingCost: state.shippingCostFor(
            items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
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
