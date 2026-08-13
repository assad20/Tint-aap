import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/features/auth/domain/entities/verification_channel.dart';

/// حارس تكافؤ التطبيق مع الموقع في تسجيل الدخول.
///
/// ‼️ **القاعدة منسوخةٌ من `looksLikeSaudiMobile` في الموقع**، وأيّ انحرافٍ
/// هنا يعني رقماً يقبله أحدهما ويرفضه الآخر: عميلٌ اشترى أمس من الموقع يقرأ
/// اليوم في التطبيق «رقم غير صحيح» لرقمه نفسه. ولا يظهر ذلك خطأً في أيّ سجلّ.
void main() {
  group('رقم الجوّال السعوديّ', () {
    test('الصيغ المقبولة كلّها', () {
      for (final value in [
        '512345678',
        '0512345678',
        '966512345678',
        '+966512345678',
        '00966512345678',
        '+966 51 234 5678',
        '05 1234 5678',
      ]) {
        expect(looksLikeSaudiMobile(value), isTrue, reason: 'رُفض: $value');
      }
    });

    test('‼️ الأرقام العربيّة والفارسيّة تُقبَل', () {
      // لوحة المفاتيح العربيّة تكتب «٠٥…»، ورفضُها يمنع فئةً كاملة من
      // المستخدمين بلا سببٍ ظاهر لهم.
      expect(looksLikeSaudiMobile('٠٥١٢٣٤٥٦٧٨'), isTrue);
      expect(looksLikeSaudiMobile('۰۵۱۲۳۴۵۶۷۸'), isTrue);
    });

    test('ما ليس جوّالاً سعوديّاً يُرفَض', () {
      for (final value in [
        '',
        '12345678',       // لا يبدأ بـ5
        '51234567',       // ناقص خانة
        '5123456789',     // زائد خانة
        '0412345678',     // ثابت لا جوّال
        'abcdefghi',
      ]) {
        expect(looksLikeSaudiMobile(value), isFalse, reason: 'قُبل: $value');
      }
    });
  });

  group('قناة التحقّق', () {
    test('الاسم المُرسَل للخادم مطابقٌ للعقد', () {
      expect(VerificationChannel.whatsapp.wire, 'whatsapp');
      expect(VerificationChannel.email.wire, 'email');
    });

    test('‼️ قناةٌ مجهولة تُهمَل ولا تُسقط الدخول', () {
      // الخادم قد يُضيف قناةً (رسالة نصّيّة) قبل أن يعرفها هذا الإصدار،
      // وتطبيقٌ يرمي عند أوّل اسمٍ لا يعرفه يمنع الدخول كلّه لأجل خيارٍ إضافيّ.
      expect(VerificationChannel.tryParse('sms'), isNull);
      expect(VerificationChannel.tryParse(null), isNull);
      expect(VerificationChannel.tryParse('WhatsApp'), VerificationChannel.whatsapp);
    });
  });
}
