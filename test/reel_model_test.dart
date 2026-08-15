import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/features/reels/domain/reel_model.dart';

/// حارس شريط الفيديو.
///
/// ‼️ العطل الوحيد الذي لا يُكتشَف بالنظر هنا هو **مقطعٌ بلا رابط**: المشغّل
/// يُفتح على لا شيء فيعرض مستطيلاً أسود بلا خطأ ولا رسالة — يقرؤه المشاهد
/// «تعلّق التطبيق» فيخرج. والترشيح في الخادم لا يكفي: بياناتٌ قديمة، أو حقلٌ
/// حُذف من اللوحة، يصلان بسلسلةٍ فارغة تمرّ من كلّ شرط.
void main() {
  group('مقطع المنتج', () {
    Map<String, dynamic> row({String? video}) => {
          'id': 'PRD-1',
          'title': 'كريم الأفوكادو',
          'brand': 'LOVEME BEAUTY',
          'price': 7,
          'image': 'https://x/y.jpg',
          if (video != null) 'videoUrl': video,
        };

    test('المقطع الكامل يُقرأ', () {
      final reel = ReelModel.fromJson(row(video: 'https://x/v.mp4'));
      expect(reel, isNotNull);
      expect(reel!.videoUrl, 'https://x/v.mp4');
      expect(reel.product.title, 'كريم الأفوكادو');
      expect(reel.id, 'PRD-1');
    });

    test('‼️ بلا رابطٍ يُسقَط ولا يُبنى بمقطعٍ فارغ', () {
      expect(ReelModel.fromJson(row()), isNull);
      expect(ReelModel.fromJson(row(video: '')), isNull);
      expect(ReelModel.fromJson(row(video: '   ')), isNull);
    });

    test('‼️ منتجٌ بلا معرّف يُسقَط', () {
      // المعرّف مفتاح الصفحة ومفتاح المفضّلة والسلّة. وفارغُه يجعل الإعجاب
      // يُصيب منتجاً آخر أو لا شيء — بلا خطأ يُنبّه.
      final broken = row(video: 'https://x/v.mp4')..['id'] = '';
      expect(ReelModel.fromJson(broken), isNull);
    });

    test('حمولةٌ ليست خريطة لا تُسقط الشريط', () {
      expect(ReelModel.fromJson(null), isNull);
      expect(ReelModel.fromJson('نصّ'), isNull);
      expect(ReelModel.fromJson(<String>[]), isNull);
    });

    test('الرابط يُشذَّب من المسافات', () {
      final reel = ReelModel.fromJson(row(video: '  https://x/v.mp4 '));
      expect(reel!.videoUrl, 'https://x/v.mp4');
    });
  });
}
