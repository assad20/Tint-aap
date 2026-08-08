import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/utils/app_version.dart';

void main() {
  group('kAppVersion', () {
    // ‼️ هذا الاختبار هو ثمن عدم استعمال `package_info_plus`: بدونه يبقى الثابت
    //    على `1.0.0` بعد رفع إصدار التطبيق، فيُخفي الحارسُ مكوّناتٍ صار الجهاز
    //    يفهمها — عطلٌ صامت لا يظهر إلّا كشاشةٍ ناقصة عند العميل.
    test('يطابق version في pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(r'^version:\s*([0-9.]+)', multiLine: true)
          .firstMatch(pubspec);

      expect(match, isNotNull, reason: 'لا يوجد سطر version في pubspec.yaml');
      expect(
        kAppVersion,
        match!.group(1),
        reason: 'حدّث kAppVersion في lib/core/utils/app_version.dart ليطابق pubspec',
      );
    });
  });

  group('compareVersions', () {
    test('يقارن بالمقاطع رقميّاً لا نصّيّاً', () {
      expect(compareVersions('1.10.0', '1.9.0'), 1); // نصّيّاً "1.10" < "1.9"
      expect(compareVersions('2.0.0', '10.0.0'), -1);
      expect(compareVersions('1.4.0', '1.4.0'), 0);
    });

    test('المقاطع الناقصة أصفار', () {
      expect(compareVersions('1.4', '1.4.0'), 0);
      expect(compareVersions('1', '1.0.0'), 0);
      expect(compareVersions('1.4.1', '1.4'), 1);
    });

    test('يرمي على ما لا يُقرأ بدل أن يُساوي بصمت', () {
      expect(() => compareVersions('v1.4', '1.4.0'), throwsFormatException);
      expect(() => compareVersions('1.4-beta', '1.4.0'), throwsFormatException);
      expect(() => compareVersions('', '1.0.0'), throwsFormatException);
    });
  });

  group('supportsMinVersion', () {
    test('الغياب يعني كلّ الإصدارات — لا العكس', () {
      // ‼️ لو انعكست هذه الحالة لأصبحت الرئيسيّة فارغةً على كلّ جهاز:
      //    الأقسام المنشورة اليوم كلّها بلا هذا الحقل.
      expect(supportsMinVersion(null, current: '1.0.0'), isTrue);
      expect(supportsMinVersion('', current: '1.0.0'), isTrue);
      expect(supportsMinVersion('   ', current: '1.0.0'), isTrue);
    });

    test('نسخةٌ أقدم ⇒ لا تُعرض (معيار قبول 2.3)', () {
      expect(supportsMinVersion('1.4.0', current: '1.0.0'), isFalse);
      expect(supportsMinVersion('1.0.1', current: '1.0.0'), isFalse);
    });

    test('النسخة المساوية أو الأحدث ⇒ تُعرض', () {
      expect(supportsMinVersion('1.4.0', current: '1.4.0'), isTrue);
      expect(supportsMinVersion('1.4.0', current: '2.0.0'), isTrue);
      expect(supportsMinVersion('1.4', current: '1.4.0'), isTrue);
    });

    test('قيمةٌ تالفة ⇒ تُخفي المكوّن ولا ترمي', () {
      expect(supportsMinVersion('v1.4-beta', current: '9.9.9'), isFalse);
      expect(supportsMinVersion('latest', current: '9.9.9'), isFalse);
    });
  });
}
