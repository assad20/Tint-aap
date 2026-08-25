import 'package:flutter/material.dart';

// يختار التنفيذ المناسب حسب المنصة:
// - الجوال (Android/iOS) → يستخدم Tabby SDK الحقيقي.
// - الويب (معاينة FlutLab) → بديل بسيط، لأن حزمة tabby_flutter_inapp_sdk
//   لا تدعم الويب فلا يتوفّر الـ Widget هناك.
import 'tabby_promo_snippet_web.dart'
    if (dart.library.io) 'tabby_promo_snippet_mobile.dart';

/// ‼️ **الاعتمادات تُمرَّر من الخادم لا تُقرأ من متغيّرات البناء.**
///
/// الخادم يُرسلها أصلاً مع وسائل الدفع (`PaymentMethodModel.publicKey` و
/// `merchantCode`)، والتطبيق يستعملها لإنشاء جلسة الدفع فعلاً — وكانت ودجة
/// العرض وحدها ما زالت تقرأ `--dart-define` القديمة.
///
/// وأثرُ ذلك أنّ متغيّرات البناء لو غابت (وهي غائبةٌ في Codemagic) **لا يُرسَم
/// شيء**: يختار العميل تابي فلا يرى كم سيدفع كلّ شهر — وهو سببُ اختياره تابي.
///
/// ‼️ **وتبديل مفتاحٍ من اللوحة لا يلزمه إصدارٌ جديد على المتجر.**
Widget buildTabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
  String? merchantCode,
  String? apiKey,
}) {
  return tabbyPromoSnippet(
    price: price,
    currencyCode: currencyCode,
    langCode: langCode,
    merchantCode: merchantCode,
    apiKey: apiKey,
  );
}
