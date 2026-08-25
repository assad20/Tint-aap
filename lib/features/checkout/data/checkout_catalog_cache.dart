import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/payment_method_model.dart';
import '../../../core/models/shipping_method_model.dart';

/// آخر وسائل دفعٍ وطرق توصيلٍ عرفها الخادم — محفوظةً على الجهاز.
///
/// ‼️ **لماذا تُحفظ أصلاً؟** لأنّ شاشة الدفع كانت تُصبح فارغةً عند أوّل تعثّر
/// شبكة، فيقرأ المشتري «لا توجد وسيلة دفع متاحة» ويظنّ المتجر معطّلاً — في آخر
/// خطوةٍ قبل أن يدفع. والمتاجر الكبرى تعرض ما تعرفه فوراً ثمّ تُحدّثه بصمت،
/// ولا تجعل العميل ينتظر الشبكة ليرى شكل الشاشة.
///
/// ‼️ **والخادم يبقى صاحب القرار.** ما هنا **عرضٌ مؤقّت** لا إذنٌ بالدفع:
/// الخادم يُعيد حساب الإجماليّ ويرفض وسيلةً لا يعرفها عند إنشاء الطلب. فأسوأ
/// ما قد يحدث أن يلمس المشتري وسيلةً عُطِّلت للتوّ فيُردّ — وهو أهون بكثيرٍ من
/// شاشةٍ تقول له إنّ المتجر لا يبيع.
///
/// ‼️ **وعمرٌ محدود (24 ساعة)**: نسخةٌ أقدم من ذلك تُهمَل ولا تُعرَض. تعطيلُ
/// وسيلةٍ من اللوحة يجب أن يسري، والاحتفاظ بها أسبوعاً يجعل التطبيق يعرض
/// أسعاراً ورسوماً لم تعد قائمة.
class CheckoutCatalogCache {
  static const _kPayments = 'checkout.payment_methods.v1';
  static const _kShipping = 'checkout.shipping_methods.v1';
  static const _kSavedAt = 'checkout.catalog.saved_at.v1';

  /// ‼️ يُرفع مع أيّ تغييرٍ في شكل ما يُحفظ. نسخةٌ قديمة تُقرأ بشكلٍ جديد
  /// تُنتج حقولاً فارغة — ورسوماً صفريّة تُعرَض ثمّ يرفضها الخادم.
  static const Duration maxAge = Duration(hours: 24);

  Future<void> save({
    List<PaymentMethodModel>? payments,
    List<ShippingMethodModel>? shipping,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (payments != null && payments.isNotEmpty) {
        await prefs.setString(
          _kPayments,
          jsonEncode([for (final m in payments) m.toJson()]),
        );
      }
      if (shipping != null && shipping.isNotEmpty) {
        await prefs.setString(
          _kShipping,
          jsonEncode([for (final m in shipping) m.toJson()]),
        );
      }
      await prefs.setInt(_kSavedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // ‼️ **الحفظ لا يُسقط الدفع أبداً**: هو تحسينُ عرضٍ لا شرطُ عمل.
    }
  }

  Future<CheckoutCatalogSnapshot?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAt = prefs.getInt(_kSavedAt);
      if (savedAt == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (age > maxAge.inMilliseconds) return null;

      List<T> decode<T>(String key, T Function(Map<String, dynamic>) from) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return const [];
        final list = jsonDecode(raw);
        if (list is! List) return const [];
        return [
          for (final item in list)
            if (item is Map) from(Map<String, dynamic>.from(item)),
        ];
      }

      final payments = decode(_kPayments, PaymentMethodModel.fromJson);
      final shipping = decode(_kShipping, ShippingMethodModel.fromJson);
      if (payments.isEmpty && shipping.isEmpty) return null;
      return CheckoutCatalogSnapshot(payments: payments, shipping: shipping);
    } catch (_) {
      return null;
    }
  }
}

class CheckoutCatalogSnapshot {
  const CheckoutCatalogSnapshot({required this.payments, required this.shipping});

  final List<PaymentMethodModel> payments;
  final List<ShippingMethodModel> shipping;
}
