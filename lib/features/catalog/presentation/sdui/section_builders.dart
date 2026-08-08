import 'package:flutter/material.dart';

import '../../../../core/models/cms_section_model.dart';
import '../../../../core/models/product_model.dart';
import 'section_registry.dart';
import 'sections/circle_categories_section.dart';
import 'sections/flash_sale_section.dart';
import 'sections/product_carousel_section.dart';
import 'sections/product_grid_section.dart';
import 'sections/rich_text_section.dart';
import 'sections/wide_banner_section.dart';

/// يحوّل عنصر منتجٍ كما يُرسله الوسيط داخل قسم CMS إلى `ProductModel`.
///
/// **الشكل مقيسٌ لا مفترَض** — استجابة حيّة لـ`product_carousel` بمصدر
/// `new_arrivals`:
/// `id · slug · categorySlug · brand · brandSlug · traits · title · images ·
///  titleEn · price · image · sku · quantity`
///
/// ‼️ **و`category` غائبٌ والموجود `categorySlug`.** بلا هذا التحويل يبقى حقل
/// القسم فارغاً في كلّ بطاقةٍ تأتي من اللوحة، بينما يمتلئ في البطاقات القادمة
/// من `/catalog/bootstrap` — فيختلف مظهر بطاقتين لنفس المنتج بحسب مصدرها.
///
/// ‼️ **و`oldPrice` يُرسَل حين يوجد فعلاً** — تحقّقٌ لاحق على قسم `flash_sale`
/// أعاد `"price":5.8,"oldPrice":7`. وغيابُه من عيّنة `new_arrivals` الأولى كان
/// لأنّ ذلك المنتج بلا سعرٍ سابق، لا لأنّ الحقل مفقود من العقد. ولا يُبنى على
/// عيّنةٍ واحدة حكمٌ على عقدٍ كامل.
ProductModel productFromCmsItem(Map<String, dynamic> item) {
  final json = Map<String, dynamic>.from(item);
  json['category'] ??= json['categorySlug'];
  return ProductModel.fromJson(json);
}

List<ProductModel> _products(CmsSectionModel section) =>
    section.items.map(productFromCmsItem).toList(growable: false);

/// عنوان القسم كما يظهر للعميل. `title` حقلٌ اختياريّ في المخطّط و`label` اسمٌ
/// إداريّ — والوقوع على `label` عند غياب `title` أفضل من رفٍّ بلا عنوان.
String _title(CmsSectionModel section) =>
    section.title ?? (section.label.isNotEmpty ? section.label : '');

/// السجلّ الافتراضيّ لهذه النسخة من التطبيق.
///
/// ‼️ **ما ليس هنا يسقط بصمت** — وهذا مقصود: الأنواع الثمانية عشرة في الخادم
/// تُرحَّل تباعاً (2.6 و2.9)، والنشر يبقى آمناً في كلّ مرحلةٍ منها.
/// يفتح وجهةً قادمة من اللوحة (`/category/<slug>` اليوم).
///
/// ‼️ يُمرَّر من الشاشة لا يُبنى هنا: التنقّل في هذا التطبيق تبديلُ تبويبٍ داخل
/// القشرة لا مسارُ `go_router`، وهو ما تعرفه الشاشة وحدها. ويُوسَّع في 3.2.
typedef SectionNavigate = void Function(BuildContext context, String href);

SectionRegistry buildDefaultSectionRegistry({
  SectionSkipReporter? onSkipped,
  SectionNavigate? onNavigate,
}) {
  /// ‼️ **لا زرَّ بلا وجهةٍ عاملة** (المهمّة 0.1): وجهةٌ فارغة **أو** غياب
  /// مُنفِّذٍ للتنقّل ⇒ `null` ⇒ الشريط بلا زرّ. زرٌّ يُعرَض ثمّ لا يفعل شيئاً
  /// أسوأ من غيابه.
  VoidCallback? tapFor(BuildContext context, Map<String, dynamic> item) {
    final href = (item['href'] ?? item['ctaHref'])?.toString().trim() ?? '';
    if (href.isEmpty || onNavigate == null) return null;
    return () => onNavigate(context, href);
  }

  return SectionRegistry(
    onSkipped: onSkipped,
    builders: {
      // 2.4
      'product_carousel': (context, section) => TintProductCarousel(
            title: _title(section),
            subtitle: section.subtitle ?? '',
            items: _products(section),
          ),

      // 2.7
      'product_grid': (context, section) => TintProductGrid(
            title: _title(section),
            subtitle: section.subtitle ?? '',
            products: _products(section),
          ),

      // 2.5 — الشكل مقيس: كلّ عنصرٍ `title · subtitle · image`.
      //
      // ‼️ الشريط الواحد لا شبكة: `_WideBanner` القائمة شريطٌ عريض، وبناء شبكةٍ
      //    هنا يُغيّر شكل الرئيسيّة — ومعيار القبول «كما هو». وتعدّد العناصر
      //    يُعرَض عموداً بنفس الشريط، فلا عنصر يُخفى بصمت.
      'banner_grid': (context, section) {
        // ‼️ `trim` لا `isNotEmpty` وحدها: مسارٌ من مسافاتٍ بيضاء يمرّ الفحص
        //    ثمّ يفشل تحميله، فيظهر إطارٌ رماديّ بارتفاع ١٤٥ في وسط الرئيسيّة.
        //    كشفه اختبارٌ لا قراءةٌ للشيفرة.
        final banners = section.items
            .where((item) => (item['image']?.toString().trim() ?? '').isNotEmpty)
            .toList(growable: false);
        if (banners.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < banners.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                TintWideBanner(
                  image: banners[i]['image'].toString(),
                  title: banners[i]['title']?.toString() ?? '',
                  subtitle: banners[i]['subtitle']?.toString() ?? '',
                  // 2.13 — يعود من الخادم لصور المكتبة وحدها (1.5).
                  aspectRatio: _double(banners[i]['aspectRatio']),
                  onTap: tapFor(context, banners[i]),
                ),
              ],
            ],
          ),
        );
      },

      // ───────────────────────── 2.9 ─────────────────────────

      // ‼️ الافتراضيّ 24 كما في الويب حرفيّاً (`Number(settings.height ?? 24)`).
      //    ورقمٌ مختلف هنا يعني صفحةً تتنفّس في الويب وتختنق في التطبيق.
      'spacer': (context, section) =>
          SizedBox(height: _double(section.settings['height']) ?? 24),

      // `custom_html` يشترك مع `rich_text` في الويب — ونفس الاشتراك هنا.
      'rich_text': _richTextBuilder,
      'custom_html': _richTextBuilder,

      'circle_categories': (context, section) {
        final circles = <TintCircleItem>[];
        for (var i = 0; i < section.items.length; i++) {
          circles.add(TintCircleItem.fromJson(section.items[i], i));
        }
        return TintCircleCategories(
          items: circles,
          // الحدّ ٢..٦ في الويب — ويُطبَّق داخل الودجة أيضاً حمايةً من قيمةٍ قديمة.
          columns: _int(section.settings['mobileColumns']) ?? 4,
          beigeBackground: section.settings['beigeBackground'] == true,
        );
      },

      'flash_sale': (context, section) => TintFlashSale(
            title: _title(section),
            subtitle: section.subtitle,
            items: _products(section),
            // ‼️ `tryParse` لا `parse`: تاريخٌ تالف يُسقط الرفّ كلّه بينما
            //    منتجاته سليمة. بلا تاريخٍ يُعرَض الرفّ بلا عدّاد.
            endsAt: DateTime.tryParse(section.settings['endsAt']?.toString() ?? '')?.toLocal(),
          ),
    },
  );
}

Widget _richTextBuilder(BuildContext context, CmsSectionModel section) {
  final text = htmlToPlainText(section.settings['html']?.toString() ?? '');
  // ‼️ نصٌّ فارغ ⇒ لا بطاقة: إطارٌ أبيض بلا محتوى يبدو عطلاً لا تصميماً.
  if (text.isEmpty && (section.title ?? '').isEmpty) return const SizedBox.shrink();
  return TintRichTextSection(
    text: text,
    title: section.title,
    subtitle: section.subtitle,
  );
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
