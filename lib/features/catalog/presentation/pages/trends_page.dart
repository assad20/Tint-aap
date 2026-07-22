import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/trends_cubit.dart';
import '../widgets/product_card.dart';

// تبويب «الترندات»: يعرض المنتجات الرائجة الحقيقيّة من /catalog/trends.
class TrendsPage extends StatelessWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<TrendsCubit, TrendsState>(
          builder: (context, state) {
            if (state.isLoading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = state.products;
            return ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الترندات',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w900)),
                            Text('اكتشف المنتجات الرائجة الآن',
                                style: TextStyle(
                                    color: TintColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: _TrendsHero(),
                ),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 70, horizontal: 24),
                    child: Center(
                      child: Text(
                        'لا توجد منتجات رائجة حالياً',
                        style: TextStyle(
                            color: TintColors.textMuted,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                else ...[
                  _HorizontalFeature(
                    title: 'الأبرز الآن',
                    items: products.take(8).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TintSurfaceCard(
                      child: Column(
                        children: [
                          const TintSectionHeader(
                            title: 'الأكثر رواجاً هذا الأسبوع',
                            subtitle: 'مشاهدات مرتفعة وتفاعل قويّ',
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 260,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) => ProductCard(
                              product: products[index],
                              showViews: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrendsHero extends StatelessWidget {
  const _TrendsHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url:
                  'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(28),
              overlay: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xCC000000), Color(0x33000000)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 24,
            left: 24,
            top: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TintStatusPill(
                  label: 'Hot Right Now',
                  backgroundColor: TintColors.sand,
                  foregroundColor: Colors.white,
                ),
                SizedBox(height: 14),
                Text(
                  'الأكثر رواجاً\nالآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'أكثر المنتجات لفتاً للأنظار — تسوّقها قبل النفاذ!',
                  style: TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFeature extends StatelessWidget {
  const _HorizontalFeature({
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProductModel> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          TintSectionHeader(
            title: title,
            icon: const Icon(Icons.local_fire_department_rounded,
                color: Colors.red),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = items[index];
                return GestureDetector(
                  onTap: () => context.push('/product', extra: product),
                  child: SizedBox(
                  width: 240,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: TintNetworkImage(
                          url: product.image,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(24),
                          overlay: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.78),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'رائج جدًا 🔥',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        left: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.brand,
                              style: const TextStyle(
                                color: TintColors.sand,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${product.price.toStringAsFixed(0)} ﷼',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
