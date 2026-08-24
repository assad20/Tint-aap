import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/cms_page_model.dart';
import '../../../../core/network/api_client.dart';
import 'cms_page_view.dart';

/// يفتح **صفحة CMS منشورة** برابطٍ عميق — `tint://page/<slug>` (المهمّة 3.3).
///
/// ‼️ **الفجوة التي سدّها**: `action.type == 'page'` كان يعود `false` من كلّ
/// مُنفِّذ، فبنرٌ تربطه بصفحة حملةٍ من لوحتك **لا يُركَّب له `onTap` أصلاً** —
/// يُرسَم ويُقرأ ويُضغَط ولا يحدث شيء. والقسم والمنتج يعملان منذ زمن.
///
/// ‼️ **ويُصيَّر بـ`CmsPageView` نفسها** التي تخدم المعاينة — بسجلّ المكوّنات
/// نفسه. وشاشتان تُصيّران التخطيط بطريقتين تنحرفان مع أوّل نوعٍ يُضاف.
class CmsPageRoute extends StatefulWidget {
  const CmsPageRoute({super.key, required this.slug});

  final String slug;

  @override
  State<CmsPageRoute> createState() => _CmsPageRouteState();
}

class _CmsPageRouteState extends State<CmsPageRoute> {
  CmsPageModel? _page;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      /// ‼️ **القناة تُمرَّر صراحةً** — وبدونها يسقط الطلب على `web`.
      ///
      /// الخادم يقبل `channel` منذ البداية، والكنترولر لم يكن يمرّرها فكان
      /// تخطيط `app` لا يصل التطبيق أبداً. أُصلح هناك، ويُرسَل هنا لئلّا
      /// يُعتمد على افتراضٍ في الطرف الآخر.
      final data = await context.read<ApiClient>().getMap(
            '${ApiRoutes.cmsPage}/${Uri.encodeComponent(widget.slug)}',
            queryParameters: const {'channel': 'app', 'locale': 'ar'},
          );

      // النقطة تُعيد الصفحة مسطّحةً — و`page` احتياطٌ لخادمٍ أقدم يُغلّفها.
      final raw = data['page'] is Map ? data['page'] as Map : data;
      final page = CmsPageModel.fromJson(Map<String, dynamic>.from(raw));
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        /// ‼️ **يُفرَّق بين «غير موجودة» و«تعذّر الاتّصال»؟ لا — عمداً.**
        ///
        /// الخادم يردّ 404 للمسودّة وللمحذوفة معاً، وتمييزُهما للعميل يكشف
        /// وجود صفحةٍ غير منشورة. والرسالة الواحدة تكفيه: لا شيء هنا الآن.
        _error = 'هذه الصفحة غير متاحة حاليّاً.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page != null) {
      return CmsPageView(page: page);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('صفحة')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'تعذّر فتح الصفحة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: TintColors.textMuted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('حاول ثانيةً')),
                  ],
                ),
              ),
      ),
    );
  }
}
