import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.dense = false,
    this.showViews = false,
  });

  final ProductModel product;
  final bool dense;
  final bool showViews;

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent?.round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TintColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TintNetworkImage(
                    url: product.image,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                if (product.tag != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      label: product.tag!,
                      backgroundColor: Colors.white.withOpacity(0.94),
                      foregroundColor: TintColors.charcoal,
                    ),
                  ),
                if (discount != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _Badge(
                      label: '-$discount%',
                      backgroundColor: TintColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (showViews && product.views != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _Badge(
                      label: '👁 ${product.views}',
                      backgroundColor: Colors.black.withOpacity(0.58),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: const TextStyle(
                      color: TintColors.sand,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TintColors.charcoal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.oldPrice != null)
                              Text(
                                '${product.oldPrice!.toStringAsFixed(0)} ﷼',
                                style: const TextStyle(
                                  color: TintColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10,
                                ),
                              ),
                            Text(
                              '${product.price.toStringAsFixed(0)} ﷼',
                              style: const TextStyle(
                                color: TintColors.sand,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          context.read<CartCubit>().addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت إضافة المنتج إلى السلة'),
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF7F8FA),
                          foregroundColor: TintColors.charcoal,
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
