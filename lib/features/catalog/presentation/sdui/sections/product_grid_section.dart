import 'package:flutter/material.dart';

import '../../../../../core/models/product_model.dart';
import '../../../../../core/widgets/tint_ui.dart';
import '../../widgets/product_card.dart';

/// شبكة منتجات — كانت `_SimpleGridStorefront` داخل `home_page.dart`.
///
/// ‼️ منقولةٌ حرفيّاً: نفس `mainAxisExtent: 258` ونفس الحشوات، و`padding: zero`
/// على الشبكة (بدونه يُضيف Flutter حشوة `MediaQuery` تلقائيّاً فتظهر فراغات
/// فوق كلّ شبكة — والرئيسيّة بلا `SafeArea`).
class TintProductGrid extends StatelessWidget {
  const TintProductGrid({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final List<ProductModel> products;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: TintSurfaceCard(
        color: highlighted ? const Color(0xFFFFF4F1) : Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            TintSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 258,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => ProductCard(product: products[index]),
            ),
          ],
        ),
      ),
    );
  }
}
