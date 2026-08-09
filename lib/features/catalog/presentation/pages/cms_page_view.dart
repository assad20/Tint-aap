import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/cms_page_model.dart';
import '../../../../app/theme/app_theme.dart';
import '../cubit/home_store_cubit.dart';
import '../sdui/section_action.dart';
import '../sdui/section_builders.dart';

/// يُصيّر **أيّ صفحة CMS** بسجلّ المكوّنات نفسه.
///
/// ‼️ **شاشةٌ واحدة تخدم غرضين**: معاينة المسودّة على الجهاز (4.3) وفتح صفحةٍ
/// منشورة برابطٍ عميق (`tint://page/<slug>`). وشاشتان كانتا ستُصيّران نفس
/// التخطيط بطريقتين تنحرفان.
///
/// ‼️ **ولا قياس هنا** (`tracker` غائب): المعاينة ليست زيارة عميل، وقياسُها
/// يُضخّم ظهور المكوّنات بمراجعات المالك فيُتّخذ قرارٌ على رقمٍ صنعه بنفسه.
class CmsPageView extends StatelessWidget {
  const CmsPageView({
    super.key,
    required this.page,
    this.isPreview = false,
  });

  final CmsPageModel page;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final registry = buildDefaultSectionRegistry(
      onSkipped: (type, error) => debugPrint(
        '[sdui] لم يُعرَض "$type"${error == null ? '' : ': $error'}',
      ),
      onAction: (action, {required execute}) =>
          _handleAction(context, action, execute: execute),
    );

    return Scaffold(
      appBar: AppBar(title: Text(page.title.isEmpty ? 'صفحة' : page.title)),
      body: Column(
        children: [
          /**
           * ‼️ **شريطٌ يقول «معاينة» صراحةً.**
           *
           * مسودّةٌ تبدو كصفحةٍ منشورة تُوقع في خطأين: يظنّ المالك أنّه نشر وهو
           * لم ينشر، أو يرسل الرابط لغيره فيظنّه المتجرَ الحقيقيّ. والرابط
           * ينتهي بعد ساعتين فتصير الشاشة خطأً بلا تفسير.
           */
          if (isPreview)
            Container(
              width: double.infinity,
              color: TintColors.sand,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Text(
                'معاينة — هذه النسخة غير منشورة، والرابط ينتهي بعد ساعتين',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: page.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'لا أقسام تعرضها هذه النسخة من التطبيق',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TintColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: registry.buildAll(context, page),
                  ),
          ),
        ],
      ),
    );
  }

  /// ‼️ **يُفتَح القسم بالمسار لا بتبديل تبويب**: هذه شاشةٌ فوق القشرة، وتبديلُ
  /// تبويبٍ تحتها يُغيّر ما لا يراه المستخدم ويتركه حيث هو.
  bool _handleAction(BuildContext context, SduiAction action, {required bool execute}) {
    switch (action.type) {
      case 'product':
        if (execute) context.push('/product/${Uri.encodeComponent(action.value)}');
        return true;
      case 'category':
        if (execute) {
          context.read<HomeStoreCubit>();
          context.push('/category/${Uri.encodeComponent(action.value)}');
        }
        return true;
      default:
        return false;
    }
  }
}
