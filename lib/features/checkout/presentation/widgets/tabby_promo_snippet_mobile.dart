import 'package:flutter/material.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

// تنفيذ الجوال — يعرض snippet الرسمي من Tabby (4 دفعات بدون فوائد).
Widget tabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
}) {
  return TabbyPresentationSnippet(
    price: price,
    currency: Currency.sar,
    lang: langCode.toLowerCase() == 'en' ? Lang.en : Lang.ar,
  );
}
