import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/core/models/cms_section_model.dart';
import 'package:tint_mobile/core/utils/app_version.dart';

/// قسمٌ صحيح — يُبنى منه ما تحتاجه كلّ حالة بتعديل حقلٍ واحد.
Map<String, dynamic> section(String id, {Object? type = 'rich_text', Map<String, dynamic>? extra}) => {
      'id': id,
      'type': type,
      'label': id,
      'position': 0,
      'settings': <String, dynamic>{},
      'items': <dynamic>[],
      ...?extra,
    };

void main() {
  group('CmsSectionModel.tryParse — معيار قبول 2.1', () {
    test('حقلٌ تالف ⇒ يسقط القسم وحده', () {
      final page = CmsPageModel.fromJson({
        'id': 'p1',
        'slug': 'home',
        'sections': [
          section('a'),
          section('b', type: null), // بلا نوع
          section('c'),
          'ليس كائناً', // نصّ مكان القسم
          section('d', type: 42), // نوعٌ ليس نصّاً مفيداً
        ],
      });

      expect(page.sections.map((s) => s.id), ['a', 'c']);
      expect(page.droppedSections, 3);
    });

    test('عنصرٌ تالف داخل القسم يسقط وحده ولا يُسقط القسم', () {
      final parsed = CmsSectionModel.tryParse(
        section('shelf', extra: {
          'items': [
            {'sku': 'A'},
            'عنصرٌ فاسد',
            {'sku': 'B'},
          ],
        }),
      );

      expect(parsed, isNotNull);
      expect(parsed!.items.length, 2);
    });

    test('حقولٌ غائبة لا تُسقط القسم — القيم الافتراضيّة تكفي', () {
      final parsed = CmsSectionModel.tryParse({'type': 'hero'});

      expect(parsed, isNotNull);
      expect(parsed!.type, 'hero');
      expect(parsed.id, isNotEmpty); // مُعرّفٌ اشتقاقيّ
      expect(parsed.settings, isEmpty);
      expect(parsed.items, isEmpty);
    });

    test('الأقسام تُرتَّب بـposition لا بترتيب وصولها', () {
      final page = CmsPageModel.fromJson({
        'sections': [
          section('third', extra: {'position': 2}),
          section('first', extra: {'position': 0}),
          section('second', extra: {'position': 1}),
        ],
      });

      expect(page.sections.map((s) => s.id), ['first', 'second', 'third']);
    });

    test('استجابةٌ بلا أقسام أو بشكلٍ خاطئ ⇒ صفحةٌ فارغة لا استثناء', () {
      expect(CmsPageModel.fromJson({}).isEmpty, isTrue);
      expect(CmsPageModel.fromJson({'sections': 'ليست قائمة'}).isEmpty, isTrue);
    });
  });

  group('حارس minAppVersion — معيار قبول 2.3', () {
    test('قسمٌ أحدث من التطبيق يُتجاهل بصمت ولا يدخل القائمة', () {
      // ‼️ الاستبعاد قبل الإدراج لا عند التصيير: لو دخل القائمة لحُسب في عدد
      //    الأقسام وفي مؤشّرات السلايدر وترك فجوةً بلا محتوى.
      final page = CmsPageModel.fromJson({
        'sections': [
          section('now'),
          section('future', extra: {'minAppVersion': '99.0.0'}),
        ],
      });

      expect(page.sections.map((s) => s.id), ['now']);
      expect(page.droppedSections, 1);
    });

    test('قسمٌ بحدٍّ يساوي إصدار التطبيق يُعرض', () {
      final page = CmsPageModel.fromJson({
        'sections': [
          section('exact', extra: {'minAppVersion': kAppVersion}),
        ],
      });

      expect(page.sections.single.id, 'exact');
    });

    test('الأقسام القائمة (بلا الحقل) تبقى ظاهرة', () {
      final page = CmsPageModel.fromJson({
        'sections': [section('legacy')],
      });

      expect(page.sections.single.id, 'legacy');
      expect(page.droppedSections, 0);
    });
  });
}
