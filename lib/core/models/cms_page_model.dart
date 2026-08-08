import 'package:flutter/foundation.dart';

import 'cms_section_model.dart';

/// تخطيطُ صفحةٍ كما يُصدره الوسيط من `/cms/public/pages/:slug` و`/cms/public/home`.
///
/// شكل الاستجابة الحقيقيّ (مقيسٌ على الإنتاج): `id · title · slug · description ·
/// seoTitle · seoDescription · seoImage · pageCss · pageJs · publishedAt · sections[]`.
///
/// ‼️ **`pageCss` و`pageJs` لا يُقرآن هنا** — المبدأ الخامس: لا HTML ولا WebView
/// بديلاً عن مكوّن. وقراءتُهما تعني بابَ تنفيذٍ من اللوحة داخل التطبيق.
@immutable
class CmsPageModel {
  const CmsPageModel({
    required this.id,
    required this.slug,
    this.title = '',
    this.description,
    this.publishedAt,
    this.sections = const <CmsSectionModel>[],
    this.droppedSections = 0,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final DateTime? publishedAt;

  /// الأقسام الصالحة **التي تفهمها هذه النسخة**، مرتّبةً بـ`position`.
  final List<CmsSectionModel> sections;

  /// كم قسماً أُسقط (تالفٌ أو أحدث من هذه النسخة). للتشخيص والقياس (5.1) —
  /// **لا يُعرض للعميل**: رسالة «أُسقط قسمان» تُقلقه ولا يملك لها حلّاً.
  final int droppedSections;

  bool get isEmpty => sections.isEmpty;

  /// ‼️ **لا يرمي أبداً.** أسوأ حالةٍ صفحةٌ بلا أقسام، لا شاشة خطأ.
  factory CmsPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    final parsed = <CmsSectionModel>[];
    var dropped = 0;

    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final section = CmsSectionModel.tryParse(raw[i], fallbackPosition: i);
        if (section == null) {
          dropped++;
          continue;
        }
        // ‼️ حارس الإصدار هنا لا في التصيير: قسمٌ لا تفهمه هذه النسخة يجب ألّا
        //    يدخل القائمة أصلاً، وإلّا حُسب في «عدد الأقسام» وفي مؤشّرات
        //    السلايدر وترك فجوةً بلا محتوى.
        if (!section.isSupportedByThisApp) {
          dropped++;
          debugPrint(
            '[sdui] قسم "${section.type}" يحتاج ${section.minAppVersion} ⇒ تُجوهل بصمت',
          );
          continue;
        }
        parsed.add(section);
      }
    }

    parsed.sort((a, b) => a.position.compareTo(b.position));

    return CmsPageModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      sections: parsed,
      droppedSections: dropped,
    );
  }
}
