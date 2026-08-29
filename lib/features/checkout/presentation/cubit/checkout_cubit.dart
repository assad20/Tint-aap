import '../../../../core/models/apple_pay_config_model.dart';
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';

import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/payment_method_model.dart';
import '../../../../core/models/shipping_method_model.dart';
import '../../data/checkout_catalog_cache.dart';
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
    this.catalogOffline = false,
    this.shippingMethods = const [],
    this.applePay = ApplePayConfigModel.empty,
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

  /// **تعذّر الوصول إلى الخادم**، لا أنّ المتجر بلا وسائل.
  ///
  /// ‼️ **التمييز بين الحالتين هو أصل العطل.** كان `catch` يُفرّغ القائمة، فتقرأ
  /// الواجهة الفراغَ ادّعاءً تجاريّاً وتقول «لا توجد وسيلة دفع متاحة حالياً.
  /// يُرجى التواصل مع الدعم» — أي **يُتّهم المتجر بعطلٍ سببُه شبكة العميل**، في
  /// آخر خطوةٍ قبل الدفع. والفراغ الحقيقيّ (ردٌّ ناجح بقائمةٍ فارغة) حالةُ عملٍ
  /// واردة: أن يُعطّل المالك كلّ الوسائل من اللوحة.
  final bool catalogOffline;

  // طرق الشحن من الخادم — لا تُكتب في التطبيق. كانت مثبَّتةً بأسعارٍ تخالف
  // إعدادات المتجر، فيرفض الخادم كلّ طلبٍ اختير فيه الخيار الأرخص.
  final List<ShippingMethodModel> shippingMethods;

  /// إعداد شريحة آبل باي من الخادم — `available: false` يُخفي الزرّ.
  final ApplePayConfigModel applePay;

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
    bool? catalogOffline,
    List<ShippingMethodModel>? shippingMethods,
    ApplePayConfigModel? applePay,
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
      catalogOffline: catalogOffline ?? this.catalogOffline,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      applePay: applePay ?? this.applePay,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      errorMessage: errorMessage,
    );
  }
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required CheckoutRepository repository,
    TrackingService? tracking,
    CheckoutCatalogCache? cache,
  })  : _repository = repository,
        _tracking = tracking,
        _cache = cache ?? CheckoutCatalogCache(),
        super(const CheckoutState());

  final CheckoutRepository _repository;
  final CheckoutCatalogCache _cache;

  /// محاولةٌ مؤجَّلة بعد فشل الشبكة — تُلغى عند إغلاق الشاشة.
  Timer? _retryTimer;
  int _retryRound = 0;

  /// ‼️ **اختياريّة عمداً**: الدفع أهمّ من قياسه، ولا يفشل لأنّ القياس غائب.
  final TrackingService? _tracking;

  /// تُستدعى عند فتح الشاشة، وعند عودة التطبيق للمقدّمة، وبعد كلّ فشلٍ ذاتيّاً.
  ///
  /// ‼️ **لا زرّ «إعادة المحاولة» ولا رسالةَ لومٍ للعميل** (قرار المالك
  /// 2026-08-25: «لم أرَ وسائل دفع عليها زرّ إعادة المحاولة»). العميل لا يُصلح
  /// شبكتنا، والشاشة تتعافى وحدها على ثلاث طبقات:
  ///
  /// ① **ما نعرفه يُعرَض فوراً** من نسخة الجهاز قبل أن تردّ الشبكة.
  /// ② **محاولاتٌ صامتة متباعدة** بدل محاولةٍ واحدة تسقط عند أوّل تعثّر.
  /// ③ **ولا يُفرَّغ ما بين أيدينا عند الفشل** — الفراغ ادّعاءٌ لا نملكه.
  Future<void> loadPaymentMethods() async {
    _retryTimer?.cancel();
    _retryRound = 0;
    await _refreshCatalog(initial: true);
  }

  /// تُستدعى من الشاشة عند عودة التطبيق للمقدّمة.
  ///
  /// ‼️ **أكثر ما يحدث فعلاً**: ينتبه المشتري لانقطاع الشبكة، فيخرج إلى
  /// الإعدادات ويُصلحها ويعود — فلا يجوز أن يجد الشاشة كما تركها.
  void refreshIfStale() {
    if (state.isSubmitting) return;
    if (state.catalogOffline || state.methods.isEmpty) {
      unawaited(loadPaymentMethods());
    }
  }

  Future<void> _refreshCatalog({bool initial = false}) async {
    if (isClosed) return;
    if (initial && state.methods.isEmpty) {
      emit(state.copyWith(methodsLoading: true));
      // ① نسخة الجهاز أوّلاً: شاشةٌ مكتملة قبل أن تردّ الشبكة.
      final cached = await _cache.read();
      if (isClosed) return;
      if (cached != null && cached.payments.isNotEmpty) {
        emit(state.copyWith(
          methods: cached.payments,
          shippingMethods: cached.shipping.isNotEmpty
              ? cached.shipping
              : state.shippingMethods,
          methodsLoading: false,
          paymentMethod: _pickPayment(cached.payments),
          shippingMethod: _pickShipping(cached.shipping),
        ));
      }
    }

    // ② محاولاتٌ صامتة: تعثّرٌ لحظيّ لا يُسقط الشاشة.
    final payments = await _attempt(_repository.fetchPaymentMethods);
    final shipping = await _attempt(_repository.fetchShippingMethods);
    if (isClosed) return;

    if (payments == null) {
      // ③ **لا يُفرَّغ ما بين أيدينا**: يبقى المعروض، وتُرفع راية «تعذّر الوصول»
      //    ليعرف العرضُ أنّ الفراغ — إن وُجد — ليس قرار المتجر.
      emit(state.copyWith(methodsLoading: false, catalogOffline: true));
      _scheduleRetry();
    } else {
      emit(state.copyWith(
        methods: payments,
        methodsLoading: false,
        catalogOffline: false,
        paymentMethod: _pickPayment(payments),
        shippingMethods: shipping ?? state.shippingMethods,
        shippingMethod: _pickShipping(shipping ?? state.shippingMethods),
      ));
      _retryTimer?.cancel();
      _retryRound = 0;
      unawaited(_cache.save(payments: payments, shipping: shipping));
    }

    // ‼️ **بعدها لا معها**: آبل باي وسيلةٌ زائدة، وتأخيرُها لا يؤخّر الشاشة —
    //    ولا يجوز أن يُبطئ فشلُها ظهورَ بقيّة الوسائل.
    unawaited(_loadApplePay());
  }

  /// ثلاث محاولاتٍ متباعدة، ثمّ استسلامٌ **مؤقّت** لا نهائيّ.
  ///
  /// ‼️ التباعد مقصود: إعادةٌ فوريّة على شبكةٍ متعثّرة تفشل مثلها، وتستنزف
  /// البطّاريّة وتُغرق الخادم بطلباتٍ متزامنة من كلّ الأجهزة العالقة.
  Future<List<T>?> _attempt<T>(Future<List<T>> Function() fetch) async {
    const waits = [Duration.zero, Duration(milliseconds: 600), Duration(seconds: 2)];
    for (final wait in waits) {
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (isClosed) return null;
      try {
        return await fetch();
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// محاولةٌ كلّ ١٠ ثوانٍ حتّى ٦ مرّات (دقيقة) ما دامت الشاشة مفتوحة.
  ///
  /// ‼️ **بسقفٍ لا بلا نهاية**: العميل الذي بقي دقيقةً بلا شبكة لن تُنقذه
  /// المحاولة الحاديةَ عشرة، وعودتُه للمقدّمة تُعيد الدورة من أوّلها.
  void _scheduleRetry() {
    if (_retryRound >= 6) return;
    _retryRound++;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 10), () {
      if (isClosed) return;
      unawaited(_refreshCatalog());
    });
  }

  /// ‼️ **لا يُغيَّر اختيار العميل إن كان لا يزال متاحاً** — قائمةٌ تصل من
  /// الخادم بترتيبٍ مختلف كانت ستقفز باختياره إلى وسيلةٍ أخرى وهو ينظر.
  String _pickPayment(List<PaymentMethodModel> methods) {
    if (methods.any((m) => m.id == state.paymentMethod)) return state.paymentMethod;
    return methods.isNotEmpty ? methods.first.id : state.paymentMethod;
  }

  String _pickShipping(List<ShippingMethodModel> methods) {
    if (methods.any((m) => m.id == state.shippingMethod)) return state.shippingMethod;
    return methods.isNotEmpty ? methods.first.id : state.shippingMethod;
  }

  @override
  Future<void> close() {
    // ‼️ مؤقّتٌ حيٌّ بعد إغلاق الكيوبت يُنادي `emit` على مغلَقٍ فيرمي.
    _retryTimer?.cancel();
    return super.close();
  }

  Future<void> _loadApplePay() async {
    final config = await _repository.fetchApplePayConfig();
    if (isClosed) return;
    emit(state.copyWith(applePay: config));
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

  /// آبل باي: يُنفَّذ الدفع بتوكن الشريحة.
  ///
  /// ‼️ **الشحن من الخادم لا من الشريحة**: كلفة الشحن تُحسب هنا كما تُحسب لكلّ
  /// وسيلة، وأيّ رقمٍ يخالف ما رآه المشتري يرفضه الخادم بمقارنة `sheetTotal`.
  Future<Map<String, dynamic>> payWithApplePay({
    required List<CartItemModel> items,
    required AddressModel address,
    required String orderReference,
    required Map<String, dynamic> applePayToken,
    required String sheetTotal,
    String? buyerEmail,
  }) {
    return _repository.payWithApplePay(
      items: items,
      address: address,
      shippingMethod: state.shippingMethod,
      shippingCost: state.shippingCostFor(
          items.fold<double>(0, (sum, i) => sum + i.lineTotal)),
      orderReference: orderReference,
      applePayToken: applePayToken,
      sheetTotal: sheetTotal,
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

  /// ‼️ **الحدثان في الكيوبت لا في الشاشة.** الاختيار يقع من الشاشة ومن
  /// الاختيار التلقائيّ لأوّل وسيلةٍ ومن استرجاع طلبٍ سابق — ووصلُه بالشاشة
  /// وحدها يُسقط ثلثي الحالات.
  ///
  /// ‼️ **و`shipping_tier` اسمُ الطريقة لا معرّفها**: GA4 يُجمّع عليه، ومعرّفٌ
  /// مثل `std-2` يُنتج تقريراً لا يُقرأ.
  void setShippingMethod(String value) {
    emit(state.copyWith(shippingMethod: value));
    final method = state.shippingMethods.where((m) => m.id == value);
    if (method.isEmpty || _itemsForTracking.isEmpty) return;
    unawaited(_tracking?.logAddShippingInfo(
          tier: method.first.label,
          items: _itemsForTracking,
        ) ??
        Future<void>.value());
  }

  void setPaymentMethod(String value, {String? cardBrand}) {
    final wasSame =
        state.paymentMethod == value && state.cardBrand == (cardBrand ?? state.cardBrand);
    emit(state.copyWith(paymentMethod: value, cardBrand: cardBrand));
    if (_itemsForTracking.isEmpty) return;

    // نقرةٌ على وسيلةٍ مختارةٍ أصلاً لا تُغيّر شيئاً — فحدثُها ضجيجٌ يُضخّم العدّ.
    if (wasSame) return;

    unawaited(_tracking?.logAddPaymentInfo(
          paymentType: _paymentTypeFor(value),
          items: _itemsForTracking,
        ) ??
        Future<void>.value());
  }

  /// ‼️ **`payment_type` ما يراه المشتري لا ما يُرسَل للخادم.**
  ///
  /// «مدى» و«Visa / Mastercard» بطاقتان منفصلتان في الشاشة ويُرسلان المعرّف
  /// نفسه (`paytabs`) — فإرسال المعرّف يجعل التقرير يقول «paytabs» للاثنين،
  /// **فيضيع بالضبط التمييز الذي بُنيت الشاشة لأجله** ولا يُعرف أيّ شبكةٍ
  /// يختارها المشتري السعُدّ. (رُصد بالتشغيل 2026-08-13: نقرتان ⇒
  /// `payment_type=paytabs` مرّتين.)
  String _paymentTypeFor(String methodId) =>
      methodId == 'paytabs' ? state.cardBrand : methodId;

  /// عناصر السلّة كما يفهمها القياس.
  ///
  /// ‼️ **تُملأ من الشاشة لا يقرؤها الكيوبت بنفسه**: السلّة كيوبتٌ آخر، وربطُ
  /// الاثنين لأجل حدثٍ يُدخل اعتماديّةً لا يحتاجها الدفع.
  List<AnalyticsEventItem> _itemsForTracking = const [];
  set trackingItems(List<AnalyticsEventItem> value) => _itemsForTracking = value;
  List<AnalyticsEventItem> get trackingItems => _itemsForTracking;

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
