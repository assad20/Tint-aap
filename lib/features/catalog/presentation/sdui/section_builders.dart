import 'package:flutter/material.dart';

import '../../../../core/models/cms_section_model.dart';
import '../../../../core/models/product_model.dart';
import 'section_registry.dart';
import 'sections/product_carousel_section.dart';
import 'sections/product_grid_section.dart';
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
/// ‼️ **و`oldPrice` غير موجود في هذا الشكل إطلاقاً**، فلا شارة خصمٍ على بطاقةٍ
/// من اللوحة ولو كان للمنتج `comparePrice`. نقصٌ في الخادم لا في التطبيق،
/// ومُسجَّلٌ هنا حتّى لا يُشخَّص لاحقاً على أنّه عطلٌ في البطاقة.
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
SectionRegistry buildDefaultSectionRegistry({SectionSkipReporter? onSkipped}) {
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
                ),
              ],
            ],
          ),
        );
      },
    },
  );
}
