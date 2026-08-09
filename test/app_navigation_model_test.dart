import 'package:flutter_test/flutter_test.dart';
import 'package:tint_mobile/core/models/app_navigation_model.dart';

/// ‼️ منسوخٌ من استجابةٍ حيّة لـ`/cms/public/app-navigation`.
const _live = {
  'drawer': [
    {
      'id': 'budget',
      'label': 'بديلك الأرخص',
      'labelEn': 'Budget Picks',
      'highlight': false,
      'action': {'type': 'category', 'value': 'budget'},
      'children': <dynamic>[],
    },
    {
      'id': 'cosmetics',
      'label': 'مستحضرات التجميل والعناية الشخصية',
      'action': {'type': 'category', 'value': 'cosmetics-personal-care'},
      'children': [
        {
          'id': 'hair',
          'label': 'العناية بالشعر',
          'action': {'type': 'category', 'value': 'hair-care'},
          'children': <dynamic>[],
        },
      ],
    },
  ],
  'bottomTabs': [
    {'id': 'home', 'label': 'الرئيسية', 'icon': 'home', 'action': {'type': 'tab', 'value': 'home'}},
    {'id': 'cart', 'label': 'السلة', 'icon': 'cart', 'action': {'type': 'tab', 'value': 'cart'}},
  ],
};

void main() {
  group('AppNavigationModel — المهمّة 3.6', () {
    test('يقرأ الاستجابة الحيّة بمستوياتها', () {
      final nav = AppNavigationModel.fromJson(Map<String, dynamic>.from(_live));

      expect(nav.drawer.length, 2);
      expect(nav.bottomTabs.length, 2);
      expect(nav.drawer[0].actionType, 'category');
      expect(nav.drawer[0].actionValue, 'budget');
      expect(nav.drawer[1].children.single.label, 'العناية بالشعر');
      expect(nav.bottomTabs[0].icon, 'home');
    });

    test('عنصرٌ بلا عنوان يسقط وحده', () {
      final nav = AppNavigationModel.fromJson({
        'drawer': [
          {'id': 'a', 'label': 'صالح', 'action': {'type': 'category', 'value': 'x'}},
          {'id': 'b'},
          'ليس كائناً',
        ],
      });

      expect(nav.drawer.map((i) => i.id), ['a']);
    });

    test('‼️ العمق محدودٌ بثلاثة — كاشٌ أعمق لا يُجمّد الواجهة', () {
      Map<String, dynamic> nest(int depth) => {
            'id': 'n$depth',
            'label': 'مستوى $depth',
            'action': {'type': 'category', 'value': 'v'},
            'children': depth >= 6 ? <dynamic>[] : [nest(depth + 1)],
          };

      final nav = AppNavigationModel.fromJson({'drawer': [nest(1)]});

      var node = nav.drawer.single;
      var levels = 1;
      while (node.children.isNotEmpty) {
        node = node.children.single;
        levels++;
      }
      expect(levels, 3);
    });

    test('استجابةٌ فارغة أو تالفة ⇒ نموذجٌ فارغ لا استثناء', () {
      expect(AppNavigationModel.fromJson({}).isEmpty, isTrue);
      expect(AppNavigationModel.fromJson({'drawer': 'ليست قائمة'}).isEmpty, isTrue);
    });
  });
}
