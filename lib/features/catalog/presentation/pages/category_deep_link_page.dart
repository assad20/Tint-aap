import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shell/presentation/pages/main_shell_page.dart';
import '../cubit/home_store_cubit.dart';

/// يفتح القشرة على قسمٍ بعينه — وجهة `tint://category/<slug>` (المهمّة 3.3).
///
/// ‼️ **لا شاشة جديدة**: الأقسام تُعرَض بتبديل تبويبٍ داخل القشرة لا بمسار
/// مستقلّ. فهذه الصفحة تُصيّر القشرة نفسها ثمّ تُبدّل تبويبها — وشاشةٌ ثانية
/// للقسم كانت ستُنتج تجربتين مختلفتين لنفس المحتوى.
///
/// ‼️ **والتبديل ينتظر وصول التنقّل.** الرابط قد يفتح التطبيق **من البارد**،
/// فتكون `topNav` فارغةً لحظتها وتصل بعد رحلة الإقلاع. ومحاولةٌ واحدة عند
/// الإنشاء كانت ستفشل صامتةً وتترك المستخدم على الرئيسيّة — وهو أسوأ ما في
/// الروابط العميقة: تفتح التطبيق ولا تصل الوجهة.
class CategoryDeepLinkPage extends StatefulWidget {
  const CategoryDeepLinkPage({super.key, required this.slug});

  final String slug;

  @override
  State<CategoryDeepLinkPage> createState() => _CategoryDeepLinkPageState();
}

class _CategoryDeepLinkPageState extends State<CategoryDeepLinkPage> {
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    // محاولةٌ فوريّة: التطبيق قد يكون يعمل والتنقّل محمّلاً سلفاً.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(context.read<HomeStoreCubit>().state));
  }

  void _apply(HomeStoreState state) {
    if (_applied || widget.slug.isEmpty) return;
    for (final category in state.topNav) {
      if (category.id == widget.slug) {
        _applied = true;
        context.read<HomeStoreCubit>().setActiveTopNav(category.name);
        return;
      }
    }
    // ‼️ لا نُعلّم `_applied` هنا: التنقّل قد لم يصل بعد، والمحاولة تتكرّر مع
    //    كلّ تحديثٍ للحالة. وقسمٌ لا وجود له يبقى على الرئيسيّة بهدوء.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeStoreCubit, HomeStoreState>(
      listenWhen: (previous, current) => previous.topNav != current.topNav,
      listener: (context, state) => _apply(state),
      child: const MainShellPage(),
    );
  }
}
