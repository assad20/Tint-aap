import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_builders.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/wide_banner_section.dart';
import 'package:tint_mobile/features/catalog/presentation/widgets/banner_slider.dart';

Future<Widget> buildOne(WidgetTester tester, Map<String, dynamic> json,
    {bool withHandler = true}) async {
  final registry = buildDefaultSectionRegistry(
    onAction: withHandler ? (action, {required execute}) => action.type == 'category' : null,
  );
  final page = CmsPageModel.fromJson({'sections': [json]});
  late Widget built;
  await tester.pumpWidget(Builder(builder: (context) {
    built = registry.build(context, page.sections.single);
    return const SizedBox.shrink();
  }));
  return built;
}

void main() {
  group('أنواعٌ إضافيّة — أشكالها مقيسة من النقطة الحيّة', () {
    testWidgets('hero: صورةٌ وعنوانٌ وزرّ عبر الشريط العريض', (tester) async {
      // الشكل المقيس: settings{image,title,subtitle,ctaLabel,ctaHref,action}
      final built = await buildOne(tester, {
        'id': 'h',
        'type': 'hero',
        'position': 0,
        'settings': {
          'image': 'https://example.test/hero.jpg',
          'title': 'عنوان الهيرو',
          'subtitle': 'سطرٌ فرعيّ',
          'ctaLabel': 'تسوّق',
          'ctaHref': '/category/makeup',
          'action': {'type': 'category', 'value': 'makeup'},
          'aspectRatio': 2.4,
        },
      });

      // ‼️ يُفحَص الكائن لا الشجرة: `TintWideBanner` تُصيّر صورةً من الشبكة،
      //    وتصييرُها هنا يختبر الصورة لا الباني.
      expect(built, isA<Padding>());
      final banner = (built as Padding).child;
      expect(banner, isA<TintWideBanner>());
      expect((banner as TintWideBanner).title, 'عنوان الهيرو');
      expect(banner.subtitle, 'سطرٌ فرعيّ');
      expect(banner.aspectRatio, 2.4);
      expect(banner.onTap, isNotNull);
    });

    testWidgets('hero بلا صورة ⇒ لا شيء', (tester) async {
      final built = await buildOne(tester, {
        'id': 'h',
        'type': 'hero',
        'position': 0,
        'settings': {'title': 'بلا صورة'},
      });
      expect(built, isA<SizedBox>());
    });

    testWidgets('media: صورةٌ بنسبتها', (tester) async {
      final built = await buildOne(tester, {
        'id': 'm',
        'type': 'media',
        'position': 0,
        'settings': {'image': 'https://example.test/m.jpg', 'aspectRatio': 3},
      });

      // ‼️ داخل مُمرِّر كما يُستعمل فعلاً: شاشة الاختبار قصيرة، وقسمٌ بصورةٍ
      //    ونصٍّ وزرّ يتجاوزها — والرئيسيّة نفسها مُمرَّرة.
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: built))),
      );
      final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
      expect(ratio.aspectRatio, 3);
    });

    testWidgets('media بلا صورة ⇒ لا شيء', (tester) async {
      final built = await buildOne(tester, {
        'id': 'm',
        'type': 'media',
        'position': 0,
        'settings': <String, dynamic>{},
      });
      expect(built, isA<SizedBox>());
    });

    testWidgets('split_feature: نصٌّ عاديّ وزرٌّ بوجهةٍ تُفتَح', (tester) async {
      final built = await buildOne(tester, {
        'id': 's',
        'type': 'split_feature',
        'position': 0,
        'title': 'قسمٌ مقسوم',
        'settings': {
          'image': 'https://example.test/s.jpg',
          'html': '<p>نصّ <b>عريض</b></p>',
          'ctaLabel': 'اذهب',
          'action': {'type': 'category', 'value': 'care'},
        },
      });

      // ‼️ داخل مُمرِّر كما يُستعمل فعلاً: شاشة الاختبار قصيرة، وقسمٌ بصورةٍ
      //    ونصٍّ وزرّ يتجاوزها — والرئيسيّة نفسها مُمرَّرة.
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: built))),
      );
      expect(find.text('قسمٌ مقسوم'), findsOneWidget);
      // ‼️ النصّ عاديّ لا HTML — الوسوم منزوعة.
      expect(find.text('نصّ عريض'), findsOneWidget);
      expect(find.text('اذهب'), findsOneWidget);
    });

    testWidgets('split_feature: بلا مُنفِّذ ⇒ لا زرّ ولو كُتب له عنوان', (tester) async {
      final built = await buildOne(
        tester,
        {
          'id': 's',
          'type': 'split_feature',
          'position': 0,
          'settings': {
            'html': '<p>نصّ</p>',
            'ctaLabel': 'اذهب',
            'action': {'type': 'category', 'value': 'care'},
          },
        },
        withHandler: false,
      );

      // ‼️ داخل مُمرِّر كما يُستعمل فعلاً: شاشة الاختبار قصيرة، وقسمٌ بصورةٍ
      //    ونصٍّ وزرّ يتجاوزها — والرئيسيّة نفسها مُمرَّرة.
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: built))),
      );
      expect(find.text('اذهب'), findsNothing);
    });

    testWidgets('banner_placement: يُصيَّر من resolvedBanners لا من items', (tester) async {
      // ‼️ الشكل المقيس: الخادم يحلّ بنرات الاستوديو في `settings.resolvedBanners`.
      final built = await buildOne(tester, {
        'id': 'p',
        'type': 'banner_placement',
        'position': 0,
        'settings': {
          'placement': 'hero',
          'resolvedBanners': [
            {'image': 'https://example.test/b1.webp', 'name': 'أوّل'},
            {'image': 'https://example.test/b2.webp', 'name': 'ثانٍ'},
            {'name': 'بلا صورة'},
          ],
        },
      });

      expect(built, isA<TintBannerSlider>());
      final slider = built as TintBannerSlider;
      expect(slider.slides.length, 2); // الثالث بلا صورة يسقط
      expect(slider.showDots, isTrue);
    });

    testWidgets('banner_placement بلا بنرات ⇒ لا شيء', (tester) async {
      final built = await buildOne(tester, {
        'id': 'p',
        'type': 'banner_placement',
        'position': 0,
        'settings': {'placement': 'hero', 'resolvedBanners': <dynamic>[]},
      });
      expect(built, isA<SizedBox>());
    });
  });
}
