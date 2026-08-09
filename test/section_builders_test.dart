import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_builders.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_registry.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/product_carousel_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/product_grid_section.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/wide_banner_section.dart';
import 'package:tint_mobile/features/catalog/presentation/widgets/banner_slider.dart';

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

    testWidgets('banner_grid: وجهةٌ فارغة ⇒ لا زرّ (المهمّة 0.1)', (tester) async {
      // ‼️ زرٌّ يُعرَض ثمّ لا يفعل شيئاً أسوأ من غيابه: يظنّ العميل التطبيق
      //    معطّلاً، ولا سجلّ يُفسّر ذلك.
      final navigated = <String>[];
      final registry = buildDefaultSectionRegistry(
        onAction: (action, {required execute}) {
          if (action.type != 'category') return false;
          if (execute) navigated.add('${action.type}:${action.value}');
          return true;
        },
      );
      final page = CmsPageModel.fromJson({
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {'image': 'https://example.test/1.jpg', 'title': 'بوجهة', 'href': '/category/makeup'},
              {'image': 'https://example.test/2.jpg', 'title': 'بلا وجهة'},
              {'image': 'https://example.test/3.jpg', 'title': 'وجهةٌ فراغات', 'href': '   '},
            ],
          },
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(children: registry.buildAll(context, page)),
            ),
          ),
        ),
      ));

      // ثلاثة شرائط، وزرٌّ واحد فقط — للذي يملك وجهة.
      expect(find.byType(TintWideBanner), findsNWidgets(3));
      expect(find.text('تصفح'), findsOneWidget);

      await tester.tap(find.text('تصفح'));
      expect(navigated, ['category:makeup']);
    });

    testWidgets('نوعُ إجراءٍ لا يعرفه المُنفِّذ ⇒ لا زرّ (المهمّة 3.2)', (tester) async {
      // ‼️ جوهر 3.2: نوعٌ اخترعته لوحةٌ أحدث من هذه النسخة يُتجاهَل **بصمت** —
      //    لا زرٌّ يُعرَض ثمّ يخيب، ولا استثناء.
      final executed = <String>[];
      final registry = buildDefaultSectionRegistry(
        onAction: (action, {required execute}) {
          if (action.type != 'category') return false;
          if (execute) executed.add(action.value);
          return true;
        },
      );
      final page = CmsPageModel.fromJson({
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {'image': 'https://example.test/1.jpg', 'action': {'type': 'story', 'value': 'x'}},
              {'image': 'https://example.test/2.jpg', 'action': {'type': 'none', 'value': ''}},
              {'image': 'https://example.test/3.jpg', 'action': {'type': 'category', 'value': 'makeup'}},
            ],
          },
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(children: registry.buildAll(context, page)),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byType(TintWideBanner), findsNWidgets(3));
      // زرٌّ واحد فقط — للنوع الذي يعرفه المُنفِّذ.
      expect(find.text('تصفح'), findsOneWidget);
    });

    testWidgets('`action` من الخادم يسبق الرابط القديم', (tester) async {
      // كاشٌ قديم بلا `action` يجب أن يبقى عاملاً (توافقٌ خلفيّ)، وحين يوجد
      // كلاهما فالخادم هو المرجع.
      final seen = <String>[];
      final registry = buildDefaultSectionRegistry(
        onAction: (action, {required execute}) {
          if (execute) seen.add('${action.type}:${action.value}');
          return true;
        },
      );
      final page = CmsPageModel.fromJson({
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {
                'image': 'https://example.test/1.jpg',
                'href': '/category/old',
                'action': {'type': 'category', 'value': 'new'},
              },
            ],
          },
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(children: registry.buildAll(context, page)),
          ),
        ),
      ));

      await tester.tap(find.text('تصفح'));
      expect(seen, ['category:new']);
    });

    testWidgets('banner_grid: بلا مُنفِّذ تنقّل ⇒ لا زرّ ولو وُجدت وجهة', (tester) async {
      // وجهةٌ لا أحد يستطيع فتحها = وجهةٌ فارغة عمليّاً.
      final built = await buildOne(tester, {
        'id': 'b',
        'type': 'banner_grid',
        'position': 0,
        'items': [
          {'image': 'https://example.test/1.jpg', 'href': '/category/makeup'},
        ],
      });

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: built)));
      expect(find.text('تصفح'), findsNothing);
    });

    testWidgets('banner_grid: aspectRatio من الخادم يحجز المساحة (2.13)', (tester) async {
      // ‼️ الحجز قبل وصول الصورة هو ما يمنع القفز. وبلا نسبةٍ يبقى الارتفاع
      //    الثابت — ولا تُخمَّن نسبة.
      await pumpPage(tester, {
        'sections': [
          {
            'id': 'b',
            'type': 'banner_grid',
            'position': 0,
            'items': [
              {'image': 'https://example.test/1.jpg', 'aspectRatio': 1.333},
              {'image': 'https://example.test/2.jpg'},
            ],
          },
        ],
      });

      final banners = tester.widgetList<TintWideBanner>(find.byType(TintWideBanner)).toList();
      expect(banners[0].aspectRatio, 1.333);
      expect(banners[1].aspectRatio, isNull);
      expect(find.byType(AspectRatio), findsOneWidget);
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

    testWidgets('نوعٌ لا يعرفه السجلّ يسقط بصمت — ويُبلَّغ عنه', (tester) async {
      // بقيت أنواعٌ لم تُرحَّل بعد، وسقوطها الصامت هو ما يجعل النشر آمناً في
      // كلّ مرحلة.
      final skipped = <String>[];
      final built = await buildOne(
        tester,
        {'id': 'x', 'type': 'video_reels', 'position': 0},
        onSkipped: (type, _) => skipped.add(type),
      );

      expect(skipped, ['video_reels']);
      expect(built, isA<SizedBox>());
    });

    testWidgets('hex_banner_grid: المركزيّ وحده — كالويب على الجوّال', (tester) async {
      // ‼️ عناصر منسوخة من **إنتاج تِنت**: المواضع والنسب حقيقيّة.
      final built = await buildOne(tester, {
        'id': 'hex',
        'type': 'hex_banner_grid',
        'position': 0,
        'settings': {'autoplayMs': 4000},
        'items': [
          {'slot': 'center', 'image': 'https://example.test/c1.webp', 'aspectRatio': 2.359},
          {'slot': 'right', 'image': 'https://example.test/r1.png', 'aspectRatio': 1},
          {'slot': 'center', 'image': 'https://example.test/c2.webp'},
          {'slot': 'left', 'image': 'https://example.test/l1.webp', 'aspectRatio': 4},
        ],
      });

      expect(built, isA<TintBannerSlider>());
      final slider = built as TintBannerSlider;
      // شريحتان مركزيّتان فقط — والجانبيّتان لا تُعرضان (قرار الويب نفسه).
      expect(slider.slides.length, 2);
      // ‼️ النسبة من الخادم لا مفروضة: بنراتٌ صُمّمت 2.359 لا تُقصّ إلى 2.5.
      expect(slider.aspectRatio, 2.359);
      expect(slider.interval, const Duration(milliseconds: 4000));
      expect(slider.showDots, isTrue);
    });

    testWidgets('hex_banner_grid: بلا شريحةٍ مركزيّة ⇒ لا شيء', (tester) async {
      final built = await buildOne(tester, {
        'id': 'hex',
        'type': 'hex_banner_grid',
        'position': 0,
        'items': [
          {'slot': 'right', 'image': 'https://example.test/r.png'},
        ],
      });

      expect(built, isA<SizedBox>());
    });

    testWidgets('hex_banner_grid: مدّة التبديل تُحَدّ كالويب', (tester) async {
      final fast = await buildOne(tester, {
        'id': 'hex',
        'type': 'hex_banner_grid',
        'position': 0,
        'settings': {'autoplayMs': 200},
        'items': [
          {'slot': 'center', 'image': 'https://example.test/c.webp'},
        ],
      });

      // ٢٠٠ms تجعل البنر يومض بلا أن يُقرأ — يُرفَع إلى الحدّ الأدنى.
      expect((fast as TintBannerSlider).interval, const Duration(milliseconds: 1500));
    });
  });
}
