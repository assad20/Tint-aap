import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/widgets/tint_ui.dart';

/// دائرة قسمٍ واحدة كما يُرسلها الوسيط.
///
/// **الشكل من نوعٍ مُعلَن في الخادم** (`HydratedCategoryItem` في
/// `hydrateCircularCategoriesSection`): `id · categoryId · name · nameEn · href ·
/// image · customIcon? · customTitle? · useCategoryImage · tint`.
///
/// ‼️ والويب يقرأ `name ?? customTitle ?? title` و`image ?? customIcon` — نتبع
/// نفس الأولويّة حرفيّاً، وإلّا ظهر عنوانٌ مخصّص في الويب واسمُ الفئة في التطبيق
/// من نفس الوثيقة.
class TintCircleItem {
  const TintCircleItem({
    required this.id,
    required this.name,
    required this.image,
    this.href = '',
    this.tint,
  });

  final String id;
  final String name;
  final String image;
  final String href;
  final Color? tint;

  factory TintCircleItem.fromJson(Map<String, dynamic> json, int index) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    return TintCircleItem(
      id: pick(['id', 'categoryId']).isNotEmpty ? pick(['id', 'categoryId']) : 'circle-$index',
      name: pick(['name', 'customTitle', 'title']),
      // ‼️ لا صورة نائبة عند الغياب — الويب علّلها: نائبةٌ تُحمَّل بنجاح تمنع
      //    التعافي إلى الحرف الأوّل، فتظهر دائرةٌ رماديّة بلا معنى.
      image: pick(['image', 'customIcon']),
      href: pick(['href']),
      tint: _parseColor(json['tint']),
    );
  }

  static Color? _parseColor(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (!value.startsWith('#')) return null;
    final hex = value.substring(1);
    final parsed = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}

/// شريط دوائر الأقسام — يقابل `CircularCategoryStrip` في الويب.
///
/// ‼️ **وفارغٌ يعني لا شيء**: الويب يُرجع `null` عند غياب اختيارٍ صريح
/// («تحكّم يدويّ 100%»)، فعرضُ إطارٍ فارغ هنا يخالفه.
class TintCircleCategories extends StatelessWidget {
  const TintCircleCategories({
    super.key,
    required this.items,
    this.columns = 4,
    this.beigeBackground = false,
    this.onTap,
  });

  final List<TintCircleItem> items;

  /// `mobileColumns` من اللوحة — الويب يحدّها بين ٢ و٦ بافتراضيّ ٤.
  final int columns;
  final bool beigeBackground;
  final void Function(TintCircleItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final safeColumns = columns.clamp(2, 6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: beigeBackground ? TintColors.sand.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: safeColumns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          // الدائرة + سطر الاسم تحتها.
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: onTap == null ? null : () => onTap!(item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipOval(
                      child: item.image.isNotEmpty
                          ? TintNetworkImage(
                              url: item.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : _InitialCircle(name: item.name, tint: item.tint),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// التعافي إلى الحرف الأوّل حين لا صورة — نفس سلوك الويب.
class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.name, this.tint});

  final String name;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tint ?? TintColors.sand.withOpacity(0.18),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '؟' : name.characters.first,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );
  }
}
