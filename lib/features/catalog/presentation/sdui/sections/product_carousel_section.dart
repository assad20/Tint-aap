import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/product_model.dart';
import '../../../../../core/widgets/tint_ui.dart';
import '../../widgets/product_card.dart';

/// رفٌّ أفقيّ — كان `_SectionCarousel` داخل `home_page.dart`.
///
/// ‼️ **نُقل حرفيّاً بلا تغييرٍ واحد في الشجرة**: نفس الحشوات (16,8,16,12) ونفس
/// الارتفاع 275 ونفس عرض البطاقة 160 ونفس الفاصل 12. ومعيار قبول 2.4 هو
/// «الشكل لا يتغيّر بصريّاً»، والطريقة الوحيدة لضمانه أن تُنقَل الودجة نفسها لا
/// أن تُعاد كتابتها.
class TintProductCarousel extends StatelessWidget {
  const TintProductCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    this.accent = TintColors.sand,
  });

  final String title;
  final String subtitle;
  final List<ProductModel> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TintSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: TextButton(
              onPressed: () {},
              child: Text(
                'عرض الكل',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 275,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 160,
                child: ProductCard(product: items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
