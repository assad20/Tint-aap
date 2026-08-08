import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_builders.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/circle_categories_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/flash_sale_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/rich_text_section.dart';

/// ‼️ عنصر `flash_sale` منسوخ من استجابة حيّة — **ولاحِظ `oldPrice`**: قياسٌ
/// أوّل على `new_arrivals` لم يُظهره فظُنّ مفقوداً من العقد، وهذا يُثبت خلافه.
const _liveFlashItem = {
  'id': 'TINT-PRD-MRNVJGYW-A38E63',
  'slug': 'TINT-PRD-MRNVJGYW-A38E63',
  'categorySlug': 'cosmetics-personal-care-skin-care-facial-skin-care-facial-cleanser',
  'brand': 'SMILE',
  'title': 'سمايل - تونر منظف للوجه بالبابايا 200 مل',
  'price': 5.8,
  'oldPrice': 7,
  'image': 'https://example.test/a.png',
  'sku': 'SC 011 B',
  'quantity': 12,
};

Future<Widget> buildOne(WidgetTester tester, Map<String, dynamic> sectionJson) async {
  final registry = buildDefaultSectionRegistry();
  final page = CmsPageModel.fromJson({'sections': [sectionJson]});
  late Widget built;
  await tester.pumpWidget(Builder(builder: (context) {
    built = registry.build(context, page.sections.single);
    return const SizedBox.shrink();
  }));
  return built;
}

void main() {
  group('htmlToPlainText — لا HTML ولا WebView', () {
    test('يفصل الفقرات بأسطر بدل لصقها', () {
      // الشكل مقيس: `<p>line <strong>one</strong></p><p>line two &amp; last</p>`
      final text = htmlToPlainText('<p>line <strong>one</strong></p><p>line two &amp; last</p>');
      expect(text, 'line one\nline two & last');
    });

    test('يحوّل <br> و<li> ويفكّ الكيانات', () {
      expect(htmlToPlainText('أ<br>ب'), 'أ\nب');
      expect(htmlToPlainText('<ul><li>واحد</li><li>اثنان</li></ul>'), '• واحد\n• اثنان');
      expect(htmlToPlainText('&lt;وسم&gt; &amp; &quot;نصّ&quot;'), '<وسم> & "نصّ"');
    });

    test('&amp; تُفكّ أخيراً فلا يعود الوسم للحياة', () {
      // لو فُكّت أوّلاً لصار `&amp;lt;` ⇒ `<` ⇒ وسمٌ يُنزَع، فيضيع النصّ.
      expect(htmlToPlainText('&amp;lt;script&amp;gt;'), '&lt;script&gt;');
    });

    test('فراغٌ يبقى فراغاً', () {
      expect(htmlToPlainText(''), '');
      expect(htmlToPlainText('   <p>  </p>  '), '');
    });
  });

  group('2.9 — البانيات', () {
    testWidgets('spacer: يقرأ height والافتراضيّ 24 كما في الويب', (tester) async {
      final sized = await buildOne(tester, {'id': 's', 'type': 'spacer', 'settings': {'height': 40}});
      expect((sized as SizedBox).height, 40);

      final fallback = await buildOne(tester, {'id': 's', 'type': 'spacer'});
      expect((fallback as SizedBox).height, 24);
    });

    testWidgets('rich_text: نصٌّ عاديّ بلا وسوم', (tester) async {
      final built = await buildOne(tester, {
        'id': 'r',
        'type': 'rich_text',
        'title': 'عن المتجر',
        'settings': {'html': '<p>سطر <strong>أوّل</strong></p>'},
      });

      expect(built, isA<TintRichTextSection>());
      final section = built as TintRichTextSection;
      expect(section.text, 'سطر أوّل');
      expect(section.text, isNot(contains('<')));
    });

    testWidgets('custom_html يمرّ بنفس الباني', (tester) async {
      final built = await buildOne(tester, {
        'id': 'h',
        'type': 'custom_html',
        'settings': {'html': '<p>نصّ</p>'},
      });
      expect(built, isA<TintRichTextSection>());
    });

    testWidgets('rich_text بلا نصٍّ ولا عنوان ⇒ لا بطاقة فارغة', (tester) async {
      final built = await buildOne(tester, {'id': 'r', 'type': 'rich_text', 'settings': {'html': ''}});
      expect(built, isA<SizedBox>());
    });

    testWidgets('circle_categories: يتبع أولويّة الويب في الاسم والصورة', (tester) async {
      final built = await buildOne(tester, {
        'id': 'c',
        'type': 'circle_categories',
        'settings': {'mobileColumns': 5, 'beigeBackground': true},
        'items': [
          {'id': 'a', 'name': 'مكياج', 'image': 'https://example.test/1.png', 'href': '/category/makeup'},
          {'id': 'b', 'customTitle': 'عنوانٌ مخصّص', 'customIcon': 'https://example.test/2.png'},
        ],
      });

      expect(built, isA<TintCircleCategories>());
      final circles = built as TintCircleCategories;
      expect(circles.columns, 5);
      expect(circles.beigeBackground, isTrue);
      expect(circles.items[0].name, 'مكياج');
      // الأولويّة: customTitle عند غياب name — وإلّا اختلف الويب عن التطبيق.
      expect(circles.items[1].name, 'عنوانٌ مخصّص');
      expect(circles.items[1].image, 'https://example.test/2.png');
    });

    testWidgets('circle_categories فارغ ⇒ لا شيء (تحكّم يدويّ 100%)', (tester) async {
      final built = await buildOne(tester, {'id': 'c', 'type': 'circle_categories', 'items': []});
      await tester.pumpWidget(MaterialApp(home: built));
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('flash_sale: يقرأ endsAt ومنتجاته', (tester) async {
      final built = await buildOne(tester, {
        'id': 'f',
        'type': 'flash_sale',
        'title': 'عروض اليوم',
        'settings': {'endsAt': '2099-12-31T20:00:00.000Z'},
        'items': [_liveFlashItem],
      });

      expect(built, isA<TintFlashSale>());
      final sale = built as TintFlashSale;
      expect(sale.title, 'عروض اليوم');
      expect(sale.endsAt, isNotNull);
      expect(sale.items.single.oldPrice, 7);
      expect(sale.items.single.discountPercent, greaterThan(0));
    });

    testWidgets('flash_sale بتاريخٍ تالف ⇒ رفٌّ بلا عدّاد لا رفٌّ ساقط', (tester) async {
      final built = await buildOne(tester, {
        'id': 'f',
        'type': 'flash_sale',
        'title': 'عروض',
        'settings': {'endsAt': 'ليس تاريخاً'},
        'items': [_liveFlashItem],
      });

      expect((built as TintFlashSale).endsAt, isNull);
      expect(built.items, hasLength(1));
    });
  });
}
