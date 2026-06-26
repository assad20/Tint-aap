import 'package:flutter/material.dart';

// يختار التنفيذ المناسب حسب المنصة:
// - الجوال (Android/iOS) → يستخدم Tabby SDK الحقيقي.
// - الويب (معاينة FlutLab) → بديل بسيط، لأن حزمة tabby_flutter_inapp_sdk
//   لا تدعم الويب فلا يتوفّر الـ Widget هناك.
import 'tabby_promo_snippet_web.dart'
    if (dart.library.io) 'tabby_promo_snippet_mobile.dart';

Widget buildTabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
}) {
  return tabbyPromoSnippet(
    price: price,
    currencyCode: currencyCode,
    langCode: langCode,
  );
}
