import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/product_model.dart';
import '../../../../../core/widgets/tint_ui.dart';
import '../../widgets/product_card.dart';

/// كتلةٌ واحدة داخل `category_highlights`.
///
/// **الشكل مقيسٌ على النقطة الحيّة** — ثلاثة أنماطٍ مختلفة الحقول:
///  · `image`   : `title · image · href · action`
///  · `products`: `title · icon · products[]`
///  · `gateway` : `title · image · products[]`  ← صورةٌ **ومنتجات** معاً
///
/// ‼️ **ولهذا أُجّلت 2.6 أوّلاً**: البطاقة القديمة (`TintCategoryWorldCard`)
/// تعرض صورةً وعنواناً فقط، فتسجيلُها لهذا النوع كان يُخفي كتل «المنتجات»
/// بصمت — يراها المسوّق في الويب ولا يجدها في التطبيق.
@immutable
class TintHighlightBlock {
  const TintHighlightBlock({
    required this.contentType,
    required this.title,
    this.image,
    this.icon,
    this.products = const <ProductModel>[],
    this.onTap,
  });

  final String contentType;
  final String title;
  final String? image;
  final String? icon;
  final List<ProductModel> products;
  final VoidCallback? onTap;

  bool get hasImage => (image ?? '').isNotEmpty;
  bool get hasProducts => products.isNotEmpty;
}

/// أيقونات ترويسة الكتلة — نفس مجموعة الويب بالأسماء ذاتها.
///
/// ‼️ اسمٌ مجهول ⇒ **لا أيقونة** لا أيقونةٌ بديلة: رمزٌ خاطئ بجانب عنوانٍ صحيح
/// يُربك أكثر من غيابه.
const Map<String, IconData> _highlightIcons = {
  'flame': Icons.local_fire_department_rounded,
  'sparkles': Icons.auto_awesome_rounded,
  'star': Icons.star_rounded,
  'zap': Icons.bolt_rounded,
  'trending': Icons.trending_up_rounded,
  'tag': Icons.sell_rounded,
  'crown': Icons.workspace_premium_rounded,
  'gift': Icons.card_giftcard_rounded,
  'heart': Icons.favorite_rounded,
  'bag': Icons.shopping_bag_rounded,
};

/// كتل «ترندات وتصنيفات» (المهمّة 2.6).
class TintCategoryHighlights extends StatelessWidget {
  const TintCategoryHighlights({super.key, required this.blocks});

  final List<TintHighlightBlock> blocks;

  @override
  Widget build(BuildContext context) {
    // ‼️ كتلةٌ بلا صورةٍ ولا منتجات ليست كتلة — والويب يُخفيها كذلك.
    final visible = blocks
        .where((block) => block.hasImage || block.hasProducts)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _Block(block: visible[i]),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});

  final TintHighlightBlock block;

  @override
  Widget build(BuildContext context) {
    final icon = _highlightIcons[block.icon ?? ''];

    return TintSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (block.title.isNotEmpty)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: TintColors.sand),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ],
            ),

          if (block.hasImage) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: block.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  // ‼️ نسبةٌ ثابتة هنا: صور الكتل تأتي من روابط قد لا تكون في
                  //    المكتبة، فلا `aspectRatio` من الخادم لها (1.5).
                  aspectRatio: 16 / 9,
                  child: TintNetworkImage(
                    url: block.image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ],

          if (block.hasProducts) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 262,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: block.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => SizedBox(
                  width: 150,
                  child: ProductCard(product: block.products[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
