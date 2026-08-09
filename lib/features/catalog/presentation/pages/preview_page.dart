import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/api_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/cms_page_model.dart';
import '../../../../core/network/api_client.dart';
import 'cms_page_view.dart';

/// معاينة مسودّةٍ على الجهاز برابطٍ موقَّع — `tint://preview/<token>` (4.3).
///
/// ‼️ **التوكن يحمل نطاقه داخل توقيعه** (الصفحة والمتجر والقناة واللغة)، فلا
/// يُمرَّر شيءٌ من التطبيق ولا يستطيع أحدٌ توسيع ما يراه بتعديل الرابط.
///
/// ‼️ **وينتهي بعد ساعتين** — وهذا سبب أهمّ رسالةٍ هنا: انتهاؤه يجب أن يُقرأ
/// «انتهت صلاحيّة الرابط» لا «التطبيق معطّل».
class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key, required this.token});

  final String token;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
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
      final data = await context
          .read<ApiClient>()
          .getMap('${ApiRoutes.cmsPreview}/${Uri.encodeComponent(widget.token)}');
      final raw = data['page'];
      if (raw is! Map) {
        throw StateError('لا صفحة في حمولة المعاينة');
      }
      if (!mounted) return;
      setState(() {
        _page = CmsPageModel.fromJson(Map<String, dynamic>.from(raw));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'انتهت صلاحيّة رابط المعاينة أو تعذّر فتحه.\nأنشئ رابطاً جديداً من اللوحة.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page != null) {
      return CmsPageView(page: page, isPreview: true);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('معاينة')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'تعذّر فتح المعاينة',
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
