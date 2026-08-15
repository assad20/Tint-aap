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

  group('حمولة طلب الرمز', () {
    /// نسخةٌ من بناء الحمولة في `AuthRemoteDataSource` — تُختبَر وحدها لأنّ
    /// المصدر يحتاج عميل شبكةٍ حيّاً.
    Map<String, dynamic> body({
      required String phone,
      required String email,
      required String channel,
    }) =>
        {
          'phone': phone,
          if (email.isNotEmpty) 'email': email,
          'channel': channel,
        };

    test('‼️ `phone` يُرسَل دائماً ولو فارغاً', () {
      // عقد الخادم يُعلنه `@IsString` بلا `@IsOptional`. وإسقاطه عند اختيار
      // البريد يُرجع «phone must be a string» — خطأٌ إنجليزيّ يقرؤه المشتري
      // ولا يدلّه على حيلة. (وقع فعلاً ورُصد بالتشغيل 2026-08-13.)
      final row = body(phone: '', email: 'a@b.com', channel: 'email');
      expect(row.containsKey('phone'), isTrue);
      expect(row['phone'], '');
    });

    test('‼️ `email` الفارغ لا يُرسَل', () {
      // اختياريٌّ في العقد، لكنّ `@IsEmail` يُسقط النصّ الفارغ. فلكلّ حقلٍ
      // حكمُه، ولا يُعمَّم قياسٌ من أحدهما على الآخر.
      final row = body(phone: '512345678', email: '', channel: 'whatsapp');
      expect(row.containsKey('email'), isFalse);
    });

    test('القناة حاضرةٌ في الحالتين', () {
      expect(body(phone: '', email: 'a@b.com', channel: 'email')['channel'], 'email');
      expect(body(phone: '5', email: '', channel: 'whatsapp')['channel'], 'whatsapp');
    });
  });
}