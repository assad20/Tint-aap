import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../cubit/favorites_cubit.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String activeFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'قائمة أمنياتي',
      child: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final items = _filter(state.items);
          if (state.items.isEmpty) {
            return TintEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'لم تقومي بحفظ أي منتج بعد',
              subtitle:
                  'تصفحي تشكيلاتنا الأنيقة واحفظي القطع التي تعجبك هنا للعودة إليها بسهولة.',
              action: TintPrimaryButton(
                label: 'تصفح المنتجات الآن',
                onPressed: () => Navigator.of(context).pop(),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              TintSurfaceCard(
                color: const Color(0xFFFFF7F5),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تألقي باختياراتك ✨',
                            style: TextStyle(
                              color: TintColors.charcoal,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لديك منتجات تنتظر إضافتها للسلة.',
                            style: TextStyle(
                              color: TintColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        for (final item in state.items.take(2)) {
                          context.read<CartCubit>().addProduct(item);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نقل المنتجات إلى السلة')),
                        );
                      },
                      child: const Text('نقل للسلة'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['الكل', 'متوفر', 'عروض حصرية', 'عاد للتوفر']
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            selected: label == activeFilter,
                            onSelected: (_) => setState(() => activeFilter = label),
                            label: Text(label),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: TintEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد منتجات تطابق هذا الفلتر',
                    subtitle: 'جرّبي فلترًا آخر أو عودي لاحقًا.',
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 300,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ProductCard(
                            product: product,
                            showViews: true,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: IconButton(
                              onPressed: () =>
                                  context.read<FavoritesCubit>().remove(product.id),
                              icon: const Icon(Icons.favorite, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<ProductModel> _filter(List<ProductModel> items) {
    switch (activeFilter) {
      case 'متوفر':
        return items.where((item) => item.isAvailable).toList();
      case 'عروض حصرية':
        return items.where((item) => item.oldPrice != null).toList();
      case 'عاد للتوفر':
        return items.where((item) => item.tag == 'حصري' || item.tag == 'جديد').toList();
      default:
        return items;
    }
  }
}
