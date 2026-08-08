import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/widgets/tint_ui.dart';

/// يحوّل HTML اللوحة إلى نصٍّ عاديّ.
///
/// ‼️ **ولا مُصيّر HTML ولا WebView** — المبدأ الخامس في الخطّة. وهو ليس تفضيلاً
/// شكليّاً: `settings.html` نصٌّ يكتبه المحرّر، وتنفيذُه داخل التطبيق يفتح باباً
/// من اللوحة إلى جهاز العميل. الويب يُعقّمه (`sanitizeCmsHtml`) لأنّه متصفّح
/// أصلاً؛ والتطبيق لا يحتاج أن يصير متصفّحاً.
///
/// ‼️ **والثمن مُعلَن**: التنسيق يضيع — العريض والروابط والقوائم تظهر نصّاً
/// عاديّاً. فالمكوّن **ليس** مطابقاً للويب بصريّاً، بخلاف بقيّة أنواع 2.9.
/// وعرضُ النصّ أصدق من إخفاء فقرةٍ كتبها المالك.
String htmlToPlainText(String html) {
  if (html.trim().isEmpty) return '';

  var text = html;

  // نهايات الفقرات والأسطر تصير أسطراً حقيقيّة قبل نزع الوسوم — وإلّا التصق
  // آخر كلمةٍ في الفقرة بأوّل كلمةٍ في التالية.
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');

  // نزع كلّ وسمٍ متبقٍّ.
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');

  // الكيانات الشائعة. و`&amp;` **آخراً** وإلّا صار `&amp;lt;` وسماً من جديد.
  const entities = {
    '&nbsp;': ' ',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&mdash;': '—',
    '&ndash;': '–',
  };
  entities.forEach((entity, value) => text = text.replaceAll(entity, value));
  text = text.replaceAll('&amp;', '&');

  // ثلاثة أسطر فارغة أو أكثر تصير سطرين، وتُقصّ الأطراف.
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

/// نصٌّ تحريريّ من اللوحة (`rich_text` و`custom_html`).
class TintRichTextSection extends StatelessWidget {
  const TintRichTextSection({
    super.key,
    required this.text,
    this.title,
    this.subtitle,
  });

  final String text;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TintSurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((title ?? '').isNotEmpty) ...[
              TintSectionHeader(title: title!, subtitle: subtitle ?? ''),
              const SizedBox(height: 10),
            ],
            Text(
              text,
              style: const TextStyle(
                height: 1.7,
                fontSize: 14,
                color: TintColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
