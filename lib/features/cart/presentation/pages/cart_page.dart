import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/cart_cubit.dart';
import '../../../catalog/presentation/widgets/product_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return TintEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'سلتك فارغة حاليًا',
                subtitle:
                    'أضيفي لمساتك الساحرة للإطلالة القادمة واكتشفي أحدث التشكيلات.',
                action: TintPrimaryButton(
                  label: 'اكتشفي التشكيلة',
                  onPressed: () {},
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'سلة التسوق',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<CartCubit>().clear(),
                      child: const Text('إفراغ السلة'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'منتجاتك الأنيقة بانتظارك، أكملي طلبك الآن!',
                      style: TextStyle(
                        color: Color(0xFFBE185D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...state.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TintSurfaceCard(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: TintNetworkImage(
                              url: item.product.image,
                              fit: BoxFit.cover,
                              width: 96,
                              height: 128,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.variant,
                                    style: const TextStyle(
                                      color: TintColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product.price.toStringAsFixed(0)} ﷼',
                                        style: const TextStyle(
                                          color: TintColors.sand,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6F8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => context
                                                .read<CartCubit>()
                                                .decrement(item.cartId),
                                            icon: const Icon(Icons.remove, size: 18),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => context
                                                .read<CartCubit>()
                                                .increment(item.cartId),
                                            icon: const Icon(Icons.add, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.read<CartCubit>().remove(item.cartId),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  label: const Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TintSurfaceCard(
                  child: Column(
                    children: [
                      const TintSectionHeader(title: 'كود الخصم'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'أدخلي كود الخصم هنا...',
                              ),
                              onChanged: context.read<CartCubit>().applyPromoCode,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('تطبيق'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TintSurfaceCard(
                  child: Column(
                    children: [
                      const TintSectionHeader(title: 'ملخص الطلب'),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'إجمالي المنتجات (${state.items.length})',
                        value: '${state.subtotal.toStringAsFixed(2)} ﷼',
                      ),
                      const SizedBox(height: 8),
                      const _SummaryRow(
                        label: 'الخصم',
                        value: '0.00 ﷼',
                        valueColor: TintColors.danger,
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'الشحن',
                        value: state.shippingCost == 0
                            ? 'مجاني'
                            : '${state.shippingCost.toStringAsFixed(2)} ﷼',
                        valueColor: state.shippingCost == 0
                            ? TintColors.success
                            : TintColors.charcoal,
                      ),
                      const Divider(height: 28),
                      _SummaryRow(
                        label: 'الإجمالي النهائي',
                        value: '${state.total.toStringAsFixed(2)} ﷼',
                        valueStyle: const TextStyle(
                          color: TintColors.sand,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TintPrimaryButton(
                        label: 'إتمام الطلب الآن',
                        expanded: true,
                        onPressed: () => context.push('/checkout'),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: _TrustTile(icon: Icons.local_shipping_outlined, title: 'شحن سريع')),
                    SizedBox(width: 10),
                    Expanded(child: _TrustTile(icon: Icons.verified_user_outlined, title: 'دفع آمن')),
                    SizedBox(width: 10),
                    Expanded(child: _TrustTile(icon: Icons.restart_alt_rounded, title: 'استرجاع سهل')),
                  ],
                ),
                const SizedBox(height: 16),
                const TintSectionHeader(title: 'أضيفي لمستك الأخيرة'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 258,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 150,
                      child: ProductCard(
                        product: FakeSeedData.productsByCategory['accessories']![index],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = TintColors.charcoal,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final style = valueStyle ??
        TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TintColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return TintSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: TintColors.sand),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
