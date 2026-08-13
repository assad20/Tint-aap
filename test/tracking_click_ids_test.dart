import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:tint_mobile/app/router/app_router.dart';

/// حارس الروابط العميقة ومعرّفات النقرة.
///
/// ‼️ **لماذا حارسٌ آليّ؟** لأنّ الرابط العميق **مدخلٌ من العالم**: أيّ أحدٍ
/// يستطيع نشر `tint://...?anything=...` ونقره. وما يُلتقَط منه يُرسَل إلى
/// الخادم ويُبنى عليه الإسناد — فقبولُ ما لم يُتّفق عليه مسار حقنٍ مفتوح، ولا
/// يظهر خطأً بل بياناتٍ ملوّثة تبدو سليمة.
void main() {
  group('تطبيع الرابط العميق', () {
    test('‼️ المضيف جزءٌ من المسار في مخطّط tint', () {
      // نظام أندرويد يضع «category» في `host` لا في `path` — وتمريره كما هو
      // يجعل الموجّه يبحث عن «/makeup» فيفتح شاشةً بيضاء.
      expect(
        AppRouter.normalizeDeepLink(Uri.parse('tint://category/makeup')),
        '/category/makeup',
      );
    });

    test('معاملات الاستعلام لا تُغيّر الوجهة', () {
      expect(
        AppRouter.normalizeDeepLink(
          Uri.parse('tint://category/makeup?gclid=ABC123'),
        ),
        '/category/makeup',
      );
    });

    test('رابطٌ فارغ يفتح الرئيسيّة لا شاشةَ خطأ', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('tint://')), '/');
    });

    test('الروابط الداخليّة تمرّ بمسارها', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('/cart')), '/cart');
    });
  });

  group('ترشيح معرّفات النقرة', () {
    /// نسخةٌ من منطق الترشيح في `TrackingService.captureClickIds` — تُختبَر
    /// وحدها لأنّ الخدمة تحتاج Firebase لا يعمل في اختبارٍ صرف.
    ///
    /// ‼️ والقائمة **مطابقةٌ لما يقبله الخادم** (`CLICK_KEYS`): مفتاحٌ يُضاف
    /// في أحد الطرفين بلا الآخر يسقط بصمت.
    const allowed = <String>[
      'gclid',
      'gbraid',
      'wbraid',
      'fbclid',
      'ttclid',
      'sc_click_id',
      'msclkid',
    ];

    Map<String, dynamic> filter(Uri uri) {
      final out = <String, dynamic>{};
      for (final key in allowed) {
        final value = uri.queryParameters[key]?.trim() ?? '';
        if (value.isNotEmpty && value.length <= 256) out[key] = value;
      }
      return out;
    }

    test('يلتقط المعتمَد وحده', () {
      final row = filter(Uri.parse(
        'tint://category/x?gclid=G1&fbclid=F1&utm_source=news&evil=DROP',
      ));
      expect(row, {'gclid': 'G1', 'fbclid': 'F1'});
    });

    test('‼️ معاملٌ غير معتمَد لا يصل الخادم', () {
      // مسار حقنٍ مفتوح للعالم لو مُرِّر ما في الرابط كما هو.
      final row = filter(Uri.parse('tint://x?attacker=1&__proto__=2'));
      expect(row, isEmpty);
    });

    test('‼️ قيمةٌ تتجاوز ٢٥٦ حرفاً تُسقَط لا تُقصّ', () {
      // الخادم يرفض ما زاد برمز ٤٠٠ فيسقط النداء كلّه؛ والقصّ يُنتج معرّفاً
      // باطلاً يبدو صالحاً ويُفسد الإسناد بصمت.
      final long = 'A' * 257;
      expect(filter(Uri.parse('tint://x?gclid=$long')), isEmpty);
      expect(filter(Uri.parse('tint://x?gclid=${'A' * 256}')).length, 1);
    });

    test('الفراغ لا يُكتَب — لئلّا يمحو نقرةً سابقة صالحة', () {
      expect(filter(Uri.parse('tint://x?gclid=&fbclid=%20')), isEmpty);
    });
  });

  group('سياق التتبّع', () {
    test('‼️ لا حرفَ `\$` مهروبٌ في قيمةٍ تُرسَل للخادم', () {
      // كُتب مرّةً `'app-\\$orderReference'` فخرج النصّ حرفيّاً في **كلّ**
      // طلب. والحقل مفتاحُ إزالة تكرار: قيمةٌ واحدة تجعل المنصّات تُسقط كلّ
      // شراءٍ بعد الأوّل بصمت. ولا فحصٌ ولا تحليلٌ يرى هذا — النصّ سليمٌ لغةً.
      // ‼️ **فحصٌ نصّيّ لا تعبيرٌ نمطيّ.** كُتبت أوّل نسخةٍ من هذا الحارس
      //    بتعبيرٍ نمطيّ نُسي فيه هروب `$`، فصار مِرساةَ نهايةٍ ولم يُطابق
      //    شيئاً: **حارسٌ يمرّ دائماً وهو أخطر من لا حارس**، لأنّه يشتري
      //    طمأنينةً كاذبة. (رُصد بإعادة العطل عمداً — وهو ما يجب أن يُفعَل
      //    بكلّ حارسٍ قبل الوثوق به.)
      final source =
          File('lib/core/tracking/tracking_service.dart').readAsStringSync();
      final offenders = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .where((line) => line.contains(r'\$'))
          .map((line) => line.trim())
          .toList();
      expect(
        offenders,
        isEmpty,
        reason: 'قيمةٌ فيها \$ مهروب — أهو مقصود؟ $offenders',
      );
    });
  });
}