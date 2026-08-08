import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/cms_page_model.dart';
import 'package:tint_mobile/core/models/cms_section_model.dart';
import 'package:tint_mobile/features/catalog/presentation/sdui/section_registry.dart';

CmsSectionModel sec(String type, {String id = 's'}) =>
    CmsSectionModel(id: id, type: type);

void main() {
  group('SectionRegistry — معيار قبول 2.2', () {
    testWidgets('نوعٌ مجهول ⇒ SizedBox.shrink() ويُبلَّغ عنه', (tester) async {
      final skipped = <String>[];
      final registry = SectionRegistry(onSkipped: (type, _) => skipped.add(type));

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => registry.build(context, sec('type_from_the_future')),
        ),
      ));

      expect(skipped, ['type_from_the_future']);
      final box = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(box.width, 0);
      expect(box.height, 0);
    });

    testWidgets('نوعٌ مسجَّل ⇒ يُبنى ولا يُبلَّغ عنه', (tester) async {
      final skipped = <String>[];
      final registry = SectionRegistry(
        builders: {'rich_text': (_, s) => Text('بُني ${s.id}')},
        onSkipped: (type, _) => skipped.add(type),
      );

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => registry.build(context, sec('rich_text', id: 'x')),
        ),
      ));

      expect(find.text('بُني x'), findsOneWidget);
      expect(skipped, isEmpty);
    });

    testWidgets('بانٍ يرمي ⇒ يسقط وحده ولا يُسقط الشاشة', (tester) async {
      // ‼️ `settings` و`items` من نوع Mixed في الخادم: محرّرٌ واحد يستطيع أن
      //    يضع فيها أيّ شكل. وبلا هذا الحارس يتحوّل حقلٌ واحد إلى شاشةٍ حمراء.
      final errors = <Object?>[];
      final registry = SectionRegistry(
        builders: {
          'good': (_, __) => const Text('سليم'),
          'bad': (_, __) => throw StateError('حقلٌ غير متوقّع'),
        },
        onSkipped: (_, error) => errors.add(error),
      );

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Column(children: [
            registry.build(context, sec('bad', id: 'b')),
            registry.build(context, sec('good', id: 'g')),
          ]),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('سليم'), findsOneWidget);
      expect(errors.single, isStateError);
    });

    test('supports و knownTypes يعكسان ما سُجّل', () {
      final registry = SectionRegistry();
      expect(registry.supports('hero'), isFalse);

      registry.register('hero', (_, __) => const SizedBox.shrink());
      expect(registry.supports('hero'), isTrue);
      expect(registry.knownTypes, contains('hero'));
    });

    testWidgets('buildAll يحفظ ترتيب الأقسام ويُبقي الفارغة مكانها', (tester) async {
      final registry = SectionRegistry(builders: {
        'a': (_, __) => const Text('أ'),
        'c': (_, __) => const Text('ج'),
      });

      final page = CmsPageModel.fromJson({
        'sections': [
          {'id': '1', 'type': 'a', 'position': 0},
          {'id': '2', 'type': 'b', 'position': 1}, // غير مسجَّل
          {'id': '3', 'type': 'c', 'position': 2},
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Column(children: registry.buildAll(context, page)),
        ),
      ));

      expect(page.sections.length, 3);
      expect(find.text('أ'), findsOneWidget);
      expect(find.text('ج'), findsOneWidget);
    });
  });
}
