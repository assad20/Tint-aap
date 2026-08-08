import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_builders.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_registry.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/product_carousel_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/product_grid_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/wide_banner_section.dart';

/// ‼️ **عنصر منتجٍ حقيقيّ** — منسوخ من استجابة حيّة لـ`/cms/public/pages/:slug`
/// بقسم `product_carousel` ومصدر `new_arrivals`. وليس شكلاً مُتخيَّلاً: لاحِظ
/// `categorySlug` بلا `category`، وغياب `oldPrice` تماماً.
const _liveProductItem = {
  'id': 'TINT-PRD-MRNVKOH8-4650AA',
  'slug': 'TINT-PRD-MRNVKOH8-4650AA',
  'categorySlug': 'cosmetics-personal-care-perfume-deodorant-deodorant-and-roll-on',
  'brand': 'SMILE',
  'brandSlug': 'smile',
  'traits': ['skin:dry'],
  'title': 'سمايل مزيل عرق 50 مل - دايموند',
  'images': ['https://example.test/a.png'],
  'titleEn': 'Smile Deodorant - Diamond',
  'price': 5.8,
  'image': 'https://example.test/a.png',
  'sku': 'SC021-H',
  'quantity': 6,
};

/// يُشغّل البانيَ الحقيقيّ ويُعيد الودجة **بلا تصيير شجرتها**.
///
/// ‼️ مقصود: `ProductCard` يقرأ `FavoritesCubit` و`CartCubit` من الشجرة،
/// وتصييرُها هنا يعني حقن مستودع حسابٍ كامل في اختبار وحدة — فنختبر ما تخصّه
/// هذه المهمّة (أنّ النوع الصحيح يُبنى بالبيانات الصحيحة) لا ما تخصّ البطاقة.
Future<Widget> buildOne(WidgetTester tester, Map<String, dynamic> sectionJson,
    {SectionSkipReporter? onSkipped}) async {
  final registry = buildDefaultSectionRegistry(onSkipped: onSkipped);
  final page = CmsPageModel.fromJson({'sections': [sectionJson]});
  late Widget built;
  await tester.pumpWidget(Builder(builder: (context) {
    built = page.sections.isEmpty
        ? const SizedBox.shrink()
        : registry.build(context, page.sections.single);
    return const SizedBox.shrink();
  }));
  return built;
}

/// يُصيّر الصفحة كاملةً — لِما لا يحتاج مزوّدات (البنرات).
Future<void> pumpPage(WidgetTester tester, Map<String, dynamic> json) async {
  final registry = buildDefaultSectionRegistry();
  final page = CmsPageModel.fromJson(json);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) =>
            SingleChildScrollView(child: Column(children: registry.buildAll(context, page))),
      ),
    ),
  ));
}

void main() {
  group('productFromCmsItem — الشكل مقيسٌ لا مفترَض', () {
    test('يقرأ الحقول التي يُرسلها الخادم فعلاً', () {
      final product = productFromCmsItem(Map<String, dynamic>.from(_liveProductItem));

      expect(product.id, 'TINT-PRD-MRNVKOH8-4650AA');
      expect(product.title, 'سمايل مزيل عرق 50 مل - دايموند');
      expect(product.brand, 'SMILE');
      expect(product.price, 5.8);
      expect(product.sku, 'SC021-H');
      expect(product.quantity, 6);
    });

    test('categorySlug يملأ category — وإلّا بقي فارغاً في كلّ بطاقةٍ من اللوحة', () {
      final product = productFromCmsItem(Map<String, dynamic>.from(_liveProductItem));
      expect(product.category, isNotEmpty);
      expect(product.category, _liveProductItem['categorySlug']);
    });

    test('غياب quantity يبقى null — لا صفراً يُقرأ نفاداً', () {
      final json = Map<String, dynamic>.from(_liveProductItem)..remove('quantity');
      expect(productFromCmsItem(json).quantity, isNull);
      expect(productFromCmsItem(json).isSoldOut, isFalse);
    });
  });

  group('السجلّ الافتراضيّ — المهامّ 2.4 و2.5 و2.7', () {
    testWidgets('product_carousel يُبنى برفٍّ أفقيّ بمنتجاته', (tester) async {
      final built = await buildOne(tester, {
        'id': 'c',
        'type': 'product_carousel',
        'title': 'وصل حديثاً',
        'position': 0,
        'items': [_liveProductItem],
      });

      expect(built, isA<TintProductCarousel>());
      final carousel = built as TintProductCarousel;
      expect(carousel.title, 'وصل حديثاً');
      expect(carousel.items.single.sku, 'SC021-H');
    });

    testWidgets('product_grid يُبنى بشبكة بمنتجاته', (tester) async {
      final built = await buildOne(tester, {
        'id': 'g',
        'type': 'product_grid',
        'title': 'تشكيلة القسم',
        'position': 0,
        'items': [_liveProductItem],
      });

      expect(built, isA<TintProductGrid>());
      expect((built as TintProductGrid).products.single.brand, 'SMILE');
    });

    testWidgets('banner_grid: كلّ عنصرٍ شريطٌ عريض — ولا عنصر يُخفى', (tester) async {
      await pumpPage(tester, {
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {'image': 'https://example.test/1.jpg', 'title': 'أوّل', 'subtitle': 'وصف'},
              {'image': 'https://example.test/2.jpg', 'title': 'ثانٍ', 'subtitle': 'وصف'},
            ],
          },
        ],
      });

      expect(find.byType(TintWideBanner), findsNWidgets(2));
      expect(find.text('أوّل'), findsOneWidget);
      expect(find.text('ثانٍ'), findsOneWidget);
    });

    testWidgets('banner_grid بلا صورةٍ صالحة ⇒ لا شيء (لا إطارٌ فارغ)', (tester) async {
      await pumpPage(tester, {
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {'title': 'بلا صورة'},
              {'image': '  '},
            ],
          },
        ],
      });

      expect(find.byType(TintWideBanner), findsNothing);
      expect(find.text('بلا صورة'), findsNothing);
    });

    testWidgets('عنوان القسم يقع على label عند غياب title', (tester) async {
      final built = await buildOne(tester, {
        'id': 'c',
        'type': 'product_carousel',
        'label': 'رفٌّ بلا عنوانٍ معروض',
        'position': 0,
        'items': [_liveProductItem],
      });

      expect((built as TintProductCarousel).title, 'رفٌّ بلا عنوانٍ معروض');
    });

    testWidgets('category_highlights غير مسجَّل بعد ⇒ يسقط بصمت (2.6 معلّقة)', (tester) async {
      // ‼️ توثيقٌ لسلوكٍ مقصود لا اختبارُ ميزة: نوع الخادم أغنى من البطاقة
      //    القائمة (أربعة أنماط محتوى)، وتسجيلُها اليوم يُخفي كتل «منتجات» بصمت.
      final skipped = <String>[];
      final built = await buildOne(
        tester,
        {'id': 'h', 'type': 'category_highlights', 'position': 0},
        onSkipped: (type, _) => skipped.add(type),
      );

      expect(skipped, ['category_highlights']);
      expect(built, isA<SizedBox>());
    });
  });
}
