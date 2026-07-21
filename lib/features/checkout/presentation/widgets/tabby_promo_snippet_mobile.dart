import 'package:flutter/material.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';
import '../../../../app/config/app_config.dart';

// تنفيذ الجوال — يعرض snippet الرسمي من Tabby (4 دفعات بدون فوائد).
// ‼️ SDK 1.11 غيّر الاسم إلى TabbyProductPageSnippet ويتطلّب price كـdouble
// + merchantCode + apiKey (يُقرآن من إعدادات البيئة). بلا إعداد Tabby نعرض نصّاً بسيطاً.
Widget tabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
}) {
  final config = AppConfig.fromEnvironment();
  final amount = double.tryParse(price.replaceAll(',', '').trim()) ?? 0;
  final isEn = langCode.toLowerCase() == 'en';

  if (!config.hasTabbyConfig || amount <= 0) {
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
    merchantCode: config.tabbyMerchantCode,
    apiKey: config.tabbyPublicKey,
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
