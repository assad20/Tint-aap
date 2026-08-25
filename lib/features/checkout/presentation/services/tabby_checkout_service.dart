import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/models/cart_item_model.dart';

class TabbyCheckoutSession {
  const TabbyCheckoutSession({
    required this.sessionId,
    required this.paymentId,
    required this.checkoutUrl,
    this.paymentToken,
  });

  final String sessionId;
  final String paymentId;
  final String checkoutUrl;
  final String? paymentToken;
}

class TabbyCheckoutService {
  /// [merchantCodeOverride] و[publicKeyOverride] يأتيان من الخادم
  /// (`/catalog/payment-methods`)، ويسقطان على قيم البناء إن غابا.
  ///
  /// الأصل أنّهما من الخادم: مفتاحٌ مثبَّتٌ لحظة البناء يعني نسخةً جديدة على
  /// المتجر عند كلّ تبديل، وانتقالاً من الرمل إلى الإنتاج ببناءٍ ومراجعة —
  /// بينما الخادم يُبدّلهما من اللوحة فيسريان على كلّ الأجهزة فوراً.
  const TabbyCheckoutService(
    this._config, {
    String? merchantCodeOverride,
    String? publicKeyOverride,
  })  : _merchantCodeOverride = merchantCodeOverride,
        _publicKeyOverride = publicKeyOverride;

  final AppConfig _config;
  final String? _merchantCodeOverride;
  final String? _publicKeyOverride;

  /// المفتاح الذي هُيّئ به الـSDK في هذا التشغيل — `null` قبل أوّل تهيئة.
  static String? _configuredKey;

  /// تهيئة الـSDK مرّةً واحدة لكلّ تشغيل.
  ///
  /// ‼️ `TabbySDK().setup` يكتب في حقلٍ `late final`، فاستدعاؤه مرّتين يرمي
  /// `LateInitializationError: Field '_apiKey' has already been initialized`.
  /// كنتُ كتبتُ في التعليق السابق أنّ «الاستدعاء رخيصٌ ويقبل التكرار» — وهذا
  /// خطأ: أوّل محاولة دفعٍ كانت تسقط به.
  void _ensureSdkConfigured() => configureSdk(publicKey);

  /// تهيئة الـSDK — **مشتركةٌ بين الدفع والعرض**.
  ///
  /// ‼️ **ودجة العرض تحتاجها كما يحتاجها الدفع.** رُصد على المحاكي
  /// (2026-08-25) أنّ `TabbyProductPageSnippet` ترمي
  /// `LateInitializationError: Field '_widgetsHost' has not been initialized`
  /// حين تُرسَم قبل `setup` — وكان العطل مخفيّاً خلف حارسٍ يمنع رسمها أصلاً.
  /// وتهيئتان منفصلتان كانتا ستتصادمان في `late final` نفسه.
  static void configureSdk(String apiKey) {
    final key = apiKey.trim();
    if (key.isEmpty) throw Exception('مفتاح تابي غير مضبوط.');
    if (_configuredKey == key) return;

    if (_configuredKey != null) {
      // المفتاح تبدّل من اللوحة بعد أن هُيّئ الـSDK. لا سبيل إلى تبديله في
      // نفس التشغيل، والمضيّ بالقديم يُنشئ جلسةً تحت حسابٍ خاطئ — فيُقال
      // صراحةً بدل أن يفشل عند تابي برسالةٍ غامضة.
      throw Exception(
        'تغيّرت إعدادات تابي. أغلقي التطبيق وأعيدي فتحه ثمّ حاولي مجدّداً.',
      );
    }

    TabbySDK().setup(withApiKey: key);
    _configuredKey = key;
  }

  String get merchantCode =>
      (_merchantCodeOverride?.trim().isNotEmpty ?? false)
          ? _merchantCodeOverride!.trim()
          : _config.tabbyMerchantCode;

  String get publicKey => (_publicKeyOverride?.trim().isNotEmpty ?? false)
      ? _publicKeyOverride!.trim()
      : _config.tabbyPublicKey;

  bool get isConfigured => publicKey.isNotEmpty && merchantCode.isNotEmpty;

  Currency get _currency => Currency.sar;

  Lang get _lang =>
      _config.tabbyLanguage.toLowerCase() == 'en' ? Lang.en : Lang.ar;

  Future<TabbyCheckoutSession> createSession({
    required List<CartItemModel> items,
    required AddressModel address,
    required double totalAmount,
    required String buyerName,
    required String buyerEmail,
    required String buyerDob,
    required String orderReference,
  }) async {
    final payment = Payment(
      amount: totalAmount.toStringAsFixed(2),
      currency: _currency,
      buyer: Buyer(
        email: buyerEmail,
        phone: _normalizePhone(address.mobile),
        name: buyerName,
        dob: buyerDob,
      ),
      buyerHistory: BuyerHistory(
        loyaltyLevel: 0,
        registeredSince: DateTime.now().toUtc().toIso8601String(),
        wishlistCount: 0,
      ),
      shippingAddress: ShippingAddress(
        city: address.city,
        address: '${address.neighborhood} - ${address.details}',
        zip: '00000',
      ),
      order: Order(
        referenceId: orderReference,
        items: items
            .map(
              (item) => OrderItem(
                title: item.product.title,
                description: item.variant,
                quantity: item.quantity,
                unitPrice: item.product.price.toStringAsFixed(2),
                referenceId: item.product.id,
                productUrl: 'https://tint.app/products/${item.product.id}',
                category: item.product.category,
              ),
            )
            .toList(),
      ),
      orderHistory: const [],
    );

    // التهيئة بمفتاح الخادم — مرّةً واحدة لكلّ تشغيل (انظر `_ensureSdkConfigured`).
    _ensureSdkConfigured();

    final session = await TabbySDK().createSession(
      TabbyCheckoutPayload(
        merchantCode: merchantCode,
        lang: _lang,
        payment: payment,
      ),
    );

    /**
     * ‼️ تُقرأ الحقول من النوع مباشرةً لا عبر `dynamic`.
     *
     * كانت الاستجابة تُقرأ كـ`dynamic` بأسماء حقولٍ من نسخةٍ أقدم (`id`,
     * `payment.id`, `token`) لا وجود لها في 1.11 — فيمرّ التحويل البرمجيّ
     * صامتاً ويسقط على الجهاز بـ`NoSuchMethodError`. أسماء 1.11 هي:
     * `sessionId` و`paymentId` و`availableProducts.installments?.webUrl`،
     * ولا يوجد `token` أصلاً.
     */
    if (session.status == SessionStatus.rejected) {
      throw Exception(
        _lang == Lang.ar ? TabbySDK.rejectionTextAr : TabbySDK.rejectionTextEn,
      );
    }

    final installments = session.availableProducts.installments;
    if (installments == null || installments.webUrl.trim().isEmpty) {
      // الجلسة قُبلت بلا منتج تقسيطٍ متاح — لا رابط يُفتَح. يُقال صراحةً بدل
      // فتح شاشةٍ فارغة.
      throw Exception(
        'تابي لا يتيح التقسيط لهذا الطلب حاليّاً. جرّبي وسيلة دفعٍ أخرى.',
      );
    }

    return TabbyCheckoutSession(
      sessionId: session.sessionId,
      paymentId: session.paymentId,
      checkoutUrl: installments.webUrl,
    );
  }

  Future<WebViewResult> openCheckout({
    required BuildContext context,
    required String checkoutUrl,
  }) {
    final completer = Completer<WebViewResult>();

    TabbyWebView.showWebView(
      context: context,
      webUrl: checkoutUrl,
      onResult: (result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      },
    );

    return completer.future.timeout(
      const Duration(minutes: 25),
      onTimeout: () => WebViewResult.expired,
    );
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('966')) return '+$digits';
    if (digits.startsWith('05')) return '+966${digits.substring(1)}';
    return digits;
  }
}
