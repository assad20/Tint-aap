import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/discover_model.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../account/presentation/cubit/favorites_cubit.dart';
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
        onTap: () => context.push('/product', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // contain لا cover: صور المنتجات لقطات كتالوج بخلفيّة بيضاء
                  // وهوامش، فكان القصّ يُزيح المنتج عن مركز البطاقة ويقتطع
                  // أطرافه. الآن تظهر الصورة كاملةً متوسّطة البطاقة.
                  TintNetworkImage(
                    url: product.image,
                    fit: BoxFit.contain,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: _FavoriteButton(product: product),
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
                // «بقي N» — إلحاحٌ صادق من المخزون الحقيقيّ. كميّة 0 تعني «لم
                // يُزامَن المخزون» لا «نفد»، فلا تُعرض. والسقف 5 كي لا تفقد
                // الشارة معناها على منتجٍ متوفّرٍ بكثرة.
                if (product.quantity > 0 && product.quantity <= 5)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      label: 'بقي ${product.quantity}',
                      backgroundColor: const Color(0xFFFFF3E0),
                      foregroundColor: const Color(0xFFB45309),
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
              padding: dense
                  ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
                  : const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                    style: TextStyle(
                      color: TintColors.charcoal,
                      fontSize: dense ? 11.5 : 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: dense ? 8 : 10),
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
                          // الإضافة السريعة تُسجَّل كما تُسجَّل من صفحة المنتج:
                          // إشارةٌ واحدة تُحتسب في مكانٍ دون آخر تُشوّه ترتيب
                          // الرواج لصالح المنتجات التي تُفتح صفحتها.
                          unawaited(context
                              .read<CatalogRepository>()
                              .recordSignal(product.id, ProductSignalType.cart));
                          showTintToast(context, 'تمت إضافة المنتج إلى السلة');
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

/// قلب المفضّلة. يقرأ حالته من `FavoritesCubit` وحده — فمهما تكرّرت بطاقة
/// المنتج في أرففٍ عدّة تتبدّل قلوبها كلّها معاً بلا مزامنةٍ يدويّة.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      buildWhen: (a, b) =>
          a.contains(product.id) != b.contains(product.id) ||
          a.pending.contains(product.id) != b.pending.contains(product.id),
      builder: (context, state) {
        final on = state.contains(product.id);
        return GestureDetector(
          onTap: () async {
            final added = await context.read<FavoritesCubit>().toggle(product);
            if (!context.mounted) return;
            if (added) {
              unawaited(context
                  .read<CatalogRepository>()
                  .recordSignal(product.id, ProductSignalType.wishlist));
            }
            showTintToast(
              context,
              added ? 'أُضيف إلى المفضّلة' : 'أُزيل من المفضّلة',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(
              on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: on ? TintColors.danger : TintColors.charcoal,
            ),
          ),
        );
      },
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
