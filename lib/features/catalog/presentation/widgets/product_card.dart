import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';
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
                // «بقي N» — إلحاحٌ صادق من المخزون الحقيقيّ. السقف 5 كي لا تفقد
                // الشارة معناها على منتجٍ متوفّرٍ بكثرة. والصنف غير المتتبَّع
                // (كميّة `null`) لا شارة له ولا حجب.
                if (product.isLowStock)
                  // ‼️ **أسفل اليسار لا أعلاه.** كانت هنا `top: 8, left: 8`
                  //    وهو موضع زرّ المفضّلة نفسه (`top: 6, left: 6`) — فتغطّيه
                  //    الشارة تماماً، ويختفي القلب عن كلّ منتجٍ قارب النفاد.
                  //    وذلك أسوأ ما يقع بزرّ: لا يبدو معطّلاً بل غير موجود.
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _Badge(
                      label: 'بقي ${product.quantity}',
                      backgroundColor: const Color(0xFFFFF3E0),
                      foregroundColor: const Color(0xFFB45309),
                    ),
                  ),
                // نفدت الكمية — طبقةٌ فوق الصورة تُعرِّف الصنف من الشبكة نفسها،
                // فلا يُكتشف نفاده عند الدفع بعد إدخال العنوان.
                if (product.isSoldOut)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.62),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: _Badge(
                          label: 'نفدت الكمية',
                          backgroundColor: TintColors.charcoal.withOpacity(0.88),
                          foregroundColor: Colors.white,
                        ),
                      ),
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
                      color: TintColors.brand,
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

                  // ‼️ **سطر التقييم يظهر لمن قُيِّم وحده.** ومنتجٌ جديد لا
                  //    نجومَ له: خمسُ نجومٍ فارغة تحته تُقرأ «سيّئ» لا «لم
                  //    يُقيَّم بعد» — فتضرّه الشارة التي وُضعت لتنفعه.
                  if (product.hasRating) ...[
                    const SizedBox(height: 5),
                    _RatingRow(
                      rating: product.rating!,
                      count: product.ratingCount ?? 0,
                      dense: dense,
                    ),
                  ],

                  SizedBox(height: dense ? 8 : 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /**
                             * ‼️ **الفرق يُرى في سطرٍ واحد لا في سطرين.**
                             *
                             * كان القديم فوق والحاليّ تحته، فيقرأ العين رقمين
                             * متتاليين ولا تقارنهما. وجَعْلُهما متجاورين —
                             * القديم شاحباً مشطوباً والحاليّ أكبر بمرّتين —
                             * يجعل التوفير هو ما يُرى أوّلاً، وهو المقصود.
                             */
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${product.price.toStringAsFixed(0)} \u0631\u064a\u0627\u0644',
                                  style: TextStyle(
                                    color: TintColors.price,
                                    fontWeight: FontWeight.w900,
                                    fontSize: dense ? 16 : 17.5,
                                    height: 1.1,
                                  ),
                                ),
                                if (product.oldPrice != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    product.oldPrice!.toStringAsFixed(0),
                                    style: const TextStyle(
                                      color: TintColors.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: TintColors.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // زرّ إضافةٍ فوق صنفٍ نافد وعدٌ لا يُوفى — يُعطَّل ويُقال
                      // السبب عند اللمس بدل أن يُكتشف عند الدفع.
                      IconButton.filledTonal(
                        onPressed: product.isSoldOut
                            ? () => showTintToast(
                                  context,
                                  'نفدت كمية هذا المنتج حاليّاً',
                                  isError: true,
                                )
                            : () {
                                context.read<CartCubit>().addProduct(product);
                                // الإضافة السريعة تُسجَّل كما تُسجَّل من صفحة المنتج:
                                // إشارةٌ واحدة تُحتسب في مكانٍ دون آخر تُشوّه ترتيب
                                // الرواج لصالح المنتجات التي تُفتح صفحتها.
                                unawaited(context
                                    .read<CatalogRepository>()
                                    .recordSignal(
                                        product.id, ProductSignalType.cart));
                                // ‼️ حدث القمع يُطلَق **بجانب** إشارة الرواج لا
                                //    بدلاً منها: الأولى لـGA4 والثانية لترتيب
                                //    «الأكثر رواجاً» عندنا — غرضان مختلفان.
                                unawaited(context
                                    .read<TrackingService>()
                                    .logAddToCart(product));
                                showTintToast(
                                    context, 'تمت إضافة المنتج إلى السلة');
                              },
                        /**
                         * ‼️ **زرٌّ مملوءٌ لا باهت، وأكبر مساحةَ لمس.**
                         *
                         * كان رماديّاً فاتحاً على بطاقةٍ بيضاء، فلا يُقرأ زرّاً
                         * أصلاً — ومساحةُ لمسه أصغر من الأربعين نقطة التي
                         * توصي بها إرشادات اللمس، فيُخطئها الإبهام على شبكةٍ
                         * من عمودين.
                         *
                         * ‼️ **والنافد يبقى مرئيّاً معطّلاً لا مخفيّاً**: زرٌّ
                         * يختفي يُقرأ عطلاً، وزرٌّ يقول «نفدت» يُقرأ خبراً.
                         */
                        style: IconButton.styleFrom(
                          backgroundColor: product.isSoldOut
                              ? const Color(0xFFEDEFF2)
                              : TintColors.charcoal,
                          foregroundColor:
                              product.isSoldOut ? Colors.black38 : Colors.white,
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
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

/// سطر التقييم في البطاقة — **نجمةٌ واحدة ورقم، لا خمس نجوم**.
///
/// ‼️ خمسُ نجومٍ في بطاقةٍ عرضها نصف الشاشة تصير خمس نقاطٍ لا تُميَّز ممتلئةً
/// من فارغة، فتُشغل المساحة ولا تُفيد. والرقم يُقرأ من أوّل نظرة («4.6») وهو
/// ما يبحث عنه المشتري فعلاً.
///
/// ‼️ **والعدد بجانبه لا تحته**: «4.6» وحدها لا تقول إن كانت من مراجعةٍ واحدة
/// أو من مئة — والفرق بينهما هو كلّ الفرق في الثقة.
class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.rating,
    required this.count,
    required this.dense,
  });

  final double rating;
  final int count;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: dense ? 13 : 14, color: TintColors.tintYellow),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: TintColors.charcoal,
            fontSize: dense ? 11 : 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            color: TintColors.textMuted,
            fontSize: dense ? 10 : 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
