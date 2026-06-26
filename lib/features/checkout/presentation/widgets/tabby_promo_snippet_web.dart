import 'package:flutter/material.dart';

// بديل الويب — حزمة Tabby تعمل على الجوال فقط، لذا نعرض بطاقة وصفية مكافئة
// أثناء المعاينة على الويب (FlutLab). الوظيفة الحقيقية تظهر على تطبيق الجوال.
Widget tabbyPromoSnippet({
  required String price,
  required String currencyCode,
  required String langCode,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FEFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFB8F7E4)),
    ),
    child: Text(
      'قسّمها على 4 دفعات بدون فوائد مع Tabby — $price $currencyCode\n'
      '(عرض Tabby التفاعلي يظهر على تطبيق الجوال)',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.5,
      ),
    ),
  );
}
