import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/app_navigation_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/home_store_cubit.dart';

/// القائمة الجانبيّة — شجرة أقسامٍ بثلاثة مستويات من `app-navigation` (3.4).
///
/// ‼️ **تُغذّى من الخادم لا من كتالوج التطبيق**: الشجرة هناك مطبَّقٌ عليها
/// تخصيص المتجر وقواعده — فقسمٌ يُخفيه المالك من اللوحة يختفي هنا فوراً، وقسمٌ
/// فارغٌ بعد قواعده لا يُعرض. وشجرةٌ محلّيّة كانت ستُظهر ما يُخفيه الويب.
///
/// ‼️ **ولا تُلغي تبويب «الأقسام»** — تُضاف إليه. التبويب شاشةُ تصفّحٍ كاملة
/// بصورٍ وبحث، والقائمة قفزةٌ سريعة من أيّ شاشة. وإلغاء أحدهما يُفقد استعمالاً
/// قائماً.
class StoreDrawer extends StatelessWidget {
  const StoreDrawer({super.key, required this.onOpenCategory});

  /// يُمرَّر من القشرة: التنقّل هنا تبديلُ تبويبٍ لا مسار.
  final void Function(AppNavItem item) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<HomeStoreCubit>().state.appNavigation;
    final roots = nav?.drawer ?? const <AppNavItem>[];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: const [
                  TintBrandLogo(compact: true),
                  SizedBox(width: 10),
                  Text('كلّ الأقسام', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
            const Divider(height: 1, color: TintColors.line),
            Expanded(
              child: roots.isEmpty
                  // ‼️ رسالةٌ لا فراغ: القائمة تُفتَح قبل وصول التنقّل أحياناً،
                  //    وفراغٌ صامت يُقرأ «المتجر بلا أقسام».
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'تُحمَّل الأقسام…',
                          style: TextStyle(color: TintColors.textMuted, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: roots.length,
                      itemBuilder: (context, index) => _Node(
                        item: roots[index],
                        depth: 0,
                        onOpen: (item) {
                          Navigator.of(context).pop(); // تُغلق قبل التنقّل
                          onOpenCategory(item);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عقدةٌ واحدة — تتوسّع إن كان لها أبناء، وتفتح القسم إن لم يكن.
class _Node extends StatelessWidget {
  const _Node({required this.item, required this.depth, required this.onOpen});

  final AppNavItem item;
  final int depth;
  final void Function(AppNavItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.only(right: 20.0 + depth * 16, left: 12);

    if (item.children.isEmpty) {
      return ListTile(
        contentPadding: padding,
        dense: depth > 0,
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.w800 : FontWeight.w600,
            fontSize: depth == 0 ? 14 : 13,
            color: item.highlight ? TintColors.sand : null,
          ),
        ),
        onTap: () => onOpen(item),
      );
    }

    /**
     * ‼️ **الأب يُفتَح بالنقر على عنوانه أيضاً — لا بالسهم وحده.**
     *
     * «مستحضرات التجميل» قسمٌ حقيقيّ له منتجاته، لا مجرّد حاوية. وجعلُه سهماً
     * فقط يعني أنّ من يريد تصفّح القسم كلّه لا يجد له مدخلاً.
     */
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: padding,
        childrenPadding: EdgeInsets.zero,
        title: GestureDetector(
          onTap: () => onOpen(item),
          child: Text(
            item.label,
            style: TextStyle(
              fontWeight: depth == 0 ? FontWeight.w800 : FontWeight.w600,
              fontSize: depth == 0 ? 14 : 13,
              color: item.highlight ? TintColors.sand : null,
            ),
          ),
        ),
        children: item.children
            .map((child) => _Node(item: child, depth: depth + 1, onOpen: onOpen))
            .toList(growable: false),
      ),
    );
  }
}
