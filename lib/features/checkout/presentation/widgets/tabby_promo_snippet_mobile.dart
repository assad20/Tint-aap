import 'package:flutter/material.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';
import '../../../../app/config/app_config.dart';
import '../services/tabby_checkout_service.dart';

// تنفيذ الجوال — يعرض snippet الرسمي من Tabby (4 دفعات بدون فوائد).
// ‼️ SDK 1.11 غيّر الاسم إلى TabbyProductPageSnippet ويتطلّب price كـdouble
// + merchantCode + apiKey (يُقرآن من إعدادات البيئة). بلا إعداد Tabby نعرض نصّاً بسيطاً.
Widget tabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
  String? merchantCode,
  String? apiKey,
}) {
  final config = AppConfig.fromEnvironment();
  final amount = double.tryParse(price.replaceAll(',', '').trim()) ?? 0;
  final isEn = langCode.toLowerCase() == 'en';

  // ‼️ **الخادم أوّلاً ثمّ متغيّرات البناء** — الأخيرة ملاذُ توافقٍ مع نسخةٍ
  //    أقدم من الخادم لا تُرسل الاعتمادات، لا مصدراً أساسيّاً.
  final code = (merchantCode ?? '').trim().isNotEmpty
      ? merchantCode!.trim()
      : config.tabbyMerchantCode.trim();
  final key = (apiKey ?? '').trim().isNotEmpty
      ? apiKey!.trim()
      : config.tabbyPublicKey.trim();

  /// ‼️ **تُهيَّأ قبل الرسم بنفس حارس الدفع** — انظر `configureSdk`.
  ///
  /// وأيّ إخفاقٍ هنا يسقط إلى السطر النصّيّ ولا يُسقط الشاشة: عرضٌ ترويجيّ لا
  /// يجوز أن يمنع الشراء.
  var ready = code.isNotEmpty && key.isNotEmpty && amount > 0;
  if (ready) {
    try {
      TabbyCheckoutService.configureSdk(key);
    } catch (_) {
      ready = false;
    }
  }

  if (!ready) {
    return Text(
      isEn
          ? 'Split in 4 interest-free payments with Tabby — $price $currencyCode'
          : 'قسّمها على 4 دفعات بدون فوائد مع Tabby — $price $currencyCode',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  return TabbyProductPageSnippet(
    price: amount,
    currency: _currencyFrom(currencyCode),
    lang: isEn ? Lang.en : Lang.ar,
    merchantCode: code,
    apiKey: key,
  );
}

Currency _currencyFrom(String code) {
  switch (code.toUpperCase()) {
    case 'AED':
      return Currency.aed;
    case 'BHD':
      return Currency.bhd;
    case 'KWD':
      return Currency.kwd;
    case 'QAR':
      return Currency.qar;
    default:
      return Currency.sar;
  }
}
