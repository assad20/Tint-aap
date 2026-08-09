import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_builders.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/sections/category_highlights_section.dart';

/// ‼️ الأنماط الثلاثة **منسوخة من استجابةٍ حيّة** — ولاحِظ اختلاف حقولها:
/// `image` بلا منتجات، و`products` بلا صورة، و`gateway` بكليهما.
const _liveSection = {
  'id': 'h1',
  'type': 'category_highlights',
  'position': 0,
  'settings': {'desktopColumns': 3, 'mobileColumns': 1},
  'items': [
    {
      'contentType': 'image',
      'title': 'كتلة صورة',
      'image': 'https://example.test/i.jpg',
      'href': '/category/makeup',
      'action': {'type': 'category', 'value': 'makeup'},
    },
    {
      'contentType': 'products',
      'title': 'كتلة منتجات',
      'icon': 'flame',
      'productLimit': 3,
      'products': [
        {'id': 'P1', 'title': 'منتج أوّل', 'brand': 'SMILE', 'price': 5.8, 'image': 'https://x/1.png'},
        {'id': 'P2', 'title': 'منتج ثانٍ', 'brand': 'SMILE', 'price': 7.0, 'image': 'https://x/2.png'},
      ],
    },
    {
      'contentType': 'gateway',
      'title': 'كتلة بوّابة',
      'image': 'https://example.test/g.jpg',
      'products': [
        {'id': 'P3', 'title': 'منتج ثالث', 'brand': 'SMILE', 'price': 9.0, 'image': 'https://x/3.png'},
      ],
    },
  ],
};

Future<Widget> buildSection(WidgetTester tester, Map<String, dynamic> json) async {
  final registry = buildDefaultSectionRegistry(
    onAction: (action, {required execute}) => action.type == 'category',
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
  group('category_highlights — المهمّة 2.6', () {
    testWidgets('يقرأ الأنماط الثلاثة بحقولها المختلفة', (tester) async {
      final built = await buildSection(tester, Map<String, dynamic>.from(_liveSection));

      expect(built, isA<TintCategoryHighlights>());
      final blocks = (built as TintCategoryHighlights).blocks;
      expect(blocks.length, 3);

      expect(blocks[0].contentType, 'image');
      expect(blocks[0].hasImage, isTrue);
      expect(blocks[0].hasProducts, isFalse);
      expect(blocks[0].onTap, isNotNull); // له وجهةٌ يعرفها المُنفِّذ

      expect(blocks[1].contentType, 'products');
      expect(blocks[1].hasImage, isFalse);
      expect(blocks[1].products.length, 2);
      expect(blocks[1].icon, 'flame');
      expect(blocks[1].onTap, isNull); // لا وجهة ⇒ لا نقر

      // ‼️ البوّابة صورةٌ **ومنتجات** معاً — وهي الحالة التي كانت ستضيع لو
      //    سُجّلت البطاقة القديمة لهذا النوع.
      expect(blocks[2].contentType, 'gateway');
      expect(blocks[2].hasImage, isTrue);
      expect(blocks[2].hasProducts, isTrue);
    });

    testWidgets('كتلةٌ بلا صورةٍ ولا منتجات لا تُعرَض', (tester) async {
      final built = await buildSection(tester, {
        'id': 'h',
        'type': 'category_highlights',
        'position': 0,
        'items': [
          {'contentType': 'products', 'title': 'فارغة', 'products': <dynamic>[]},
        ],
      });

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: built)));
      expect(find.text('فارغة'), findsNothing);
    });

    testWidgets('قسمٌ بلا كتلٍ ⇒ لا شيء', (tester) async {
      final built = await buildSection(tester, {
        'id': 'h',
        'type': 'category_highlights',
        'position': 0,
        'items': <dynamic>[],
      });

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: built)));
      expect(find.byType(Card), findsNothing);
    });
  });
}
