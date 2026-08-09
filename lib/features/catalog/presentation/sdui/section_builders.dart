import 'package:flutter/material.dart';

import '../../../../core/models/cms_section_model.dart';
import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/models/product_model.dart';
import '../widgets/banner_slider.dart';
import 'section_action.dart';
import 'section_registry.dart';
import 'sections/category_highlights_section.dart';
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
SectionRegistry buildDefaultSectionRegistry({
  SectionSkipReporter? onSkipped,
  SduiActionHandler? onAction,
}) {
  /// ‼️ **لا زرَّ بلا إجراءٍ يُنفَّذ فعلاً** (المهمّتان 0.1 و3.2).
  ///
  /// ثلاث حالاتٍ تُنتج `null` — وكلّها «لا زرّ»:
  ///  · لا `action` ولا رابط ⇒ لا وجهة أصلاً.
  ///  · `type: none` أو قيمةٌ فارغة ⇒ وجهةٌ مُعلَنة وفارغة.
  ///  · لا مُنفِّذ، أو مُنفِّذٌ لا يعرف النوع ⇒ **وجهةٌ لا أحد يفتحها**.
  ///
  /// والثالثة هي جوهر 3.2: نوعٌ اخترعته لوحةٌ أحدث من هذه النسخة يُتجاهَل
  /// **بصمت** — لا زرّ يُعرَض ثمّ يخيب، ولا استثناء.
  VoidCallback? tapFor(Map<String, dynamic> item) {
    final action = SduiAction.from(item);
    if (action == null || !action.isActionable || onAction == null) {
      return null;
    }
    // ‼️ يُسأل المُنفِّذ **قبل** عرض الزرّ لا عند النقر.
    if (!onAction(action, execute: false)) {
      return null;
    }
    return () => onAction(action, execute: true);
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
                  onTap: tapFor(banners[i]),
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

      /**
       * `hex_banner_grid` — بنراتٌ بمواضع (`center` · `left` · `right`).
       *
       * ‼️ **المركزيّ وحده — وهذا ما يفعله الويب على الجوّال حرفيّاً.**
       * تعليل مُصيّر الويب صريح: «يُخفى على الجوّال بقرارٍ تصميميّ لا لعجزٍ
       * تقنيّ: الشاشة الضيّقة تجعل البنرات الجانبيّة صفّاً إضافيّاً يُبعد
       * المنتجات عن أوّل مشهد، والبنر المركزيّ يحمل الرسالة كاملةً».
       *
       * فعرضُها في التطبيق كان سيُخالف قراراً مدروساً — لا يُنفّذه.
       *
       * ‼️ **ونسبة الصورة من الخادم** (1.5): قِيست على الإنتاج `2.359` و`1`
       * و`4` — أي أنّ نسبةً واحدة مفروضة كانت ستقصّ بنراتٍ صُمّمت بمقاساتٍ
       * مختلفة. فتُؤخَذ من أوّل شريحةٍ تعرف نسبتها.
       */
      'hex_banner_grid': (context, section) {
        final center = section.items
            .where((item) => (item['slot']?.toString() ?? '') == 'center')
            .where((item) => (item['image']?.toString().trim() ?? '').isNotEmpty)
            .toList(growable: false);
        if (center.isEmpty) return const SizedBox.shrink();

        final ratio = center
            .map((item) => _double(item['aspectRatio']))
            .firstWhere((value) => value != null && value > 0, orElse: () => null);

        final millis = _int(section.settings['autoplayMs']) ?? 4000;

        return TintBannerSlider(
          slides: center
              .map((item) => HeroSlideModel(
                    image: item['image'].toString(),
                    href: (item['href'] ?? '').toString(),
                  ))
              .toList(growable: false),
          aspectRatio: ratio ?? 2.5,
          showDots: center.length > 1,
          // ‼️ يُحَدّ كما في الويب (١٫٥–١٥ ثانية): قيمةٌ صغيرة تجعل البنر
          //    يومض بلا أن يُقرأ، وكبيرةٌ تجعله يبدو جامداً.
          interval: Duration(milliseconds: millis.clamp(1500, 15000)),
          onSlideTap: (href) {
            final action = SduiAction.legacyFromHref(href);
            if (action != null && onAction != null) {
              onAction(action, execute: true);
            }
          },
        );
      },

      // 2.6 — الأنماط الثلاثة كلّها: صورة · منتجات · بوّابة (صورةٌ ومنتجات).
      'category_highlights': (context, section) => TintCategoryHighlights(
            blocks: section.items.map((item) {
              final rawProducts = item['products'];
              return TintHighlightBlock(
                contentType: item['contentType']?.toString() ?? 'image',
                title: item['title']?.toString() ?? '',
                image: item['image']?.toString(),
                icon: item['icon']?.toString(),
                products: rawProducts is List
                    ? rawProducts
                        .whereType<Map>()
                        .map((p) => productFromCmsItem(Map<String, dynamic>.from(p)))
                        .toList(growable: false)
                    : const <ProductModel>[],
                onTap: tapFor(item),
              );
            }).toList(growable: false),
          ),

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
