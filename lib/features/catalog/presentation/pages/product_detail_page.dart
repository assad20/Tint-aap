import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../shell/presentation/cubit/shell_cubit.dart';

// صفحة تفاصيل المنتج (PDP): تُبنى من ProductModel المُمرَّر من البطاقة.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  void _addToCart() {
    final cart = context.read<CartCubit>();
    for (var i = 0; i < _qty; i++) {
      cart.addProduct(widget.product);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('أُضيف $_qty إلى السلة'),
          backgroundColor: TintColors.success,
          behavior: SnackBarBehavior.floating,
          // زرّ مباشر للسلة كي لا يتوه العميل عن مكان المنتج (نمط شي إن).
          action: SnackBarAction(
            label: 'عرض السلة',
            textColor: Colors.white,
            onPressed: _openCart,
          ),
        ),
      );
  }

  // يفتح تبويب السلة (٣) ويعود إليه من صفحة المنتج المدفوعة.
  void _openCart() {
    context.read<ShellCubit>().selectTab(3);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final discount = p.discountPercent?.round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: TintColors.charcoal,
        elevation: 0.5,
        title: Text(
          p.brand.isNotEmpty ? p.brand : 'تفاصيل المنتج',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          // أيقونة السلة بعدّاد حيّ — يرى العميل أين ذهب المنتج ويفتح السلة بنقرة.
          _CartAction(onOpen: _openCart),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: TintNetworkImage(url: p.image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.brand.isNotEmpty)
                  Text(
                    p.brand,
                    style: const TextStyle(
                      color: TintColors.sand,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  p.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.price.toStringAsFixed(0)} ﷼',
                      style: const TextStyle(
                        color: TintColors.sand,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (p.oldPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${p.oldPrice!.toStringAsFixed(0)} ﷼',
                          style: const TextStyle(
                            color: TintColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TintColors.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      p.isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.remove_circle_rounded,
                      color: p.isAvailable ? Colors.green : TintColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.isAvailable ? 'متوفّر' : 'غير متوفّر حالياً',
                      style: TextStyle(
                        color: p.isAvailable ? Colors.green : TintColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 34),
                const Text(
                  'نبذة عن المنتج',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  '${p.title} من ${p.brand.isNotEmpty ? p.brand : 'تِنت'}. '
                  'لمزيد من التفاصيل أو الاستفسار، تواصل مع مستشار تِنت.',
                  style: const TextStyle(
                    color: TintColors.textMuted,
                    height: 1.9,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: TintColors.line)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: TintColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '$_qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _qty++),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: TintColors.charcoal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: p.isAvailable ? _addToCart : null,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: const Text(
                      'أضف إلى السلة',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// أيقونة السلة في الرأس مع شارة عدد القطع (تتحدّث فور الإضافة) — نمط شي إن.
class _CartAction extends StatelessWidget {
  const _CartAction({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count =
            state.items.fold<int>(0, (sum, item) => sum + item.quantity);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: TintColors.danger,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
