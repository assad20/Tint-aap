import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// شعارات وسائل الدفع.
///
/// ‼️ **نفس ملفّات الموقع** (`tint-next14/public/payment/`) لا نسخةٌ ثانية:
/// نسختان تتباعدان، والعميل يرى علامتين مختلفتين للمزوّد الواحد بين المتجر
/// والتطبيق. وشروط أصحاب العلامات (حدٌّ أدنى للحجم · مساحةٌ حولها · ألوانٌ لا
/// تُعدَّل) تسري على الاثنين، ونسخةٌ محرَّرة تخالفها.
///
/// ‼️ **ومحزَّمةٌ في التطبيق لا مجلوبةٌ من الشبكة**: شعارٌ يُجلب عند الدفع
/// يتأخّر أو يُحجَب، فيظهر فراغٌ مكانه **في أكثر موضعٍ تُهمّ فيه الثقة**.
///
/// ‼️ **وملفّاتٌ مسطّحة لا مدمجة.** ملفّ `visa.svg` في الموقع يحوي شعارَي فيزا
/// وماستركارد في `<svg>` **متداخلين** — و`flutter_svg` لا يدعم التداخل، فرسم
/// **فراغاً** بلا خطأ ولا تحذير. (رُصد على المحاكي 2026-08-12: «مدى» ظهرت
/// و«فيزا» لم تظهر.) فأُخذ الملفّان المنفصلان من `public/payment/brands/`.
/// **والمتصفّح يتسامح مع ما لا يتسامح معه العارض الأصليّ.**
const Map<String, String> kPaymentMarks = {
  'tabby': 'assets/payment/tabby.svg',
  'tamara': 'assets/payment/tamara.svg',
  'mada': 'assets/payment/mada.svg',
  'visa': 'assets/payment/visa.svg',
  'mastercard': 'assets/payment/mastercard.svg',
  'cod': 'assets/payment/cod.svg',
  'bank': 'assets/payment/bank.svg',
};

/// شعارٌ بارتفاعٍ ثابت وعرضٍ حرّ.
///
/// ‼️ **الارتفاع يُثبَّت والعرض يُترك** — نِسَب الشعارات مختلفة جدّاً: «تابي»
/// مستطيلٌ عريض، و«فيزا» كلمةٌ ممتدّة، و«مدى» شبه مربّع. وتثبيت العرض يمطّ
/// بعضها ويسحق بعضها فتبدو القائمة غير متّسقة.
///
/// ‼️ **وشعارٌ مفقود لا يكسر الشاشة**: يسقط إلى نصٍّ صغير بدل مربّعٍ أحمر —
/// وسيلةُ دفعٍ جديدة قد تصل من الخادم قبل أن يُضاف شعارها إلى نسخة الجهاز.
class PaymentMark extends StatelessWidget {
  const PaymentMark({super.key, required this.markKey, this.fallbackLabel});

  final String markKey;
  final String? fallbackLabel;

  static const double _height = 22;

  @override
  Widget build(BuildContext context) {
    final path = kPaymentMarks[markKey];
    if (path == null) {
      /// ‼️ **أيقونةٌ عامّة لا تكرارُ العنوان.** كان يُطبَع `fallbackLabel` وهو
      /// عنوان البطاقة نفسه، فيظهر النصّ مرّتين في السطر الواحد (رُصد مع «نون»).
      /// ووسيلةُ دفعٍ بلا شعارٍ في هذه النسخة تُرسَم بطاقةً محايدة.
      return const Icon(Icons.credit_card_rounded, size: _height, color: Color(0xFF8A8F98));
    }

    return SizedBox(
      height: _height,
      child: SvgPicture.asset(
        path,
        height: _height,
        fit: BoxFit.contain,
        // ‼️ لا `colorFilter`: ألوان العلامات جزءٌ من شروط استعمالها.
        placeholderBuilder: (_) => const SizedBox(height: _height, width: 40),
      ),
    );
  }
}
