import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/widgets/tint_ui.dart';

/// شريطٌ عريض بصورةٍ ونصّ — كان `_WideBanner` داخل `home_page.dart`.
///
/// ‼️ منقولٌ حرفيّاً: نفس الارتفاع 145 ونفس نصف القطر 24 ونفس تدرّج السواد
/// (0.45 → 0.1) ونفس مواضع النصّ (18 من كلّ جهة).
class TintWideBanner extends StatelessWidget {
  const TintWideBanner({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.height = 145,
    this.onTap,
  });

  final String image;
  final String title;
  final String subtitle;
  final double height;

  /// ‼️ **وجهةٌ فارغة ⇒ لا زرّ** (المهمّة 0.1 والمبدأ الثاني). زرٌّ لا يؤدّي
  /// شيئاً أسوأ من غيابه: العميل يضغطه مرّتين ثمّ يظنّ التطبيق معطّلاً.
  /// و`null` هنا هو الحالة القائمة في الرئيسيّة المكتوبة بالشيفرة اليوم
  /// (`onPressed: () {}`), فالمظهر لا يتغيّر حتّى يُربَط من اللوحة.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url: image,
              fit: BoxFit.cover,
              // كبطاقة القسم: بلا مقاسٍ صريح تنكمش الصورة إلى نسبتها ويظهر
              // الرماديّ على جانبَي الشريط.
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(24),
              overlay: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            left: 18,
            bottom: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onTap ?? () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TintColors.sand,
                  ),
                  child: const Text('تصفح'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
