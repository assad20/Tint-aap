import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/trends_cubit.dart';
import '../widgets/product_card.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  String activeFilter = 'الكل';

  final filters = const [
    'الكل',
    'الأكثر طلباً 📈',
    'جديد الترند ✨',
    'مكياج',
    'عطور',
    'عبايات',
    'إكسسوارات',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<TrendsCubit, TrendsState>(
          builder: (context, state) {
            final products = state.products.isNotEmpty
                ? state.products
                : FakeSeedData.topTrending;
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
                            Text(
                              'الترندات',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'اكتشفي المنتجات الرائجة الآن',
                              style: TextStyle(
                                color: TintColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TrendsHero(),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = filters[index];
                      final isActive = item == activeFilter;
                      return ChoiceChip(
                        selected: isActive,
                        onSelected: (_) => setState(() => activeFilter = item),
                        label: Text(
                          item,
                          style: TextStyle(
                            color: isActive ? Colors.white : TintColors.charcoal,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        selectedColor: TintColors.charcoal,
                        backgroundColor: Colors.white,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: filters.length,
                  ),
                ),
                const SizedBox(height: 12),
                _HorizontalFeature(
                  title: 'الأبرز الآن',
                  items: FakeSeedData.topTrending,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TintSurfaceCard(
                    child: Column(
                      children: [
                        const TintSectionHeader(
                          title: 'حديث الناس هذا الأسبوع',
                          subtitle: 'مشاهدات مرتفعة وتفاعل قوي',
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: FakeSeedData.mostViewed.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) => ProductCard(
                            product: FakeSeedData.mostViewed[index],
                            showViews: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TintSurfaceCard(
                    color: TintColors.charcoal,
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'تنسيق الترند ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'أناقة السهرات الشرقية',
                          style: TextStyle(
                            color: Color(0xFFE7D9CF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 160,
                          child: TintNetworkImage(
                            url:
                                'https://images.unsplash.com/photo-1550639525-c97d455acf70?w=800&q=80',
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ProductCard(
                                product: FakeSeedData.productsByCategory['abayas']![2],
                                dense: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductCard(
                                product: FakeSeedData.productsByCategory['accessories']![0],
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Column(
                    children: [
                      const TintSectionHeader(title: 'مختارات الترند'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: FakeSeedData.allProducts.take(8).length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 260,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: FakeSeedData.allProducts[index],
                          showViews: true,
                        ),
                      ),
                    ],
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

class _TrendsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url:
                  'https://images.unsplash.com/photo-1485230405346-71acb9518d9c?w=800&q=80',
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
                  'صيحات\nالموسم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'أكثر القطع لفتًا للأنظار، تسوقيها قبل النفاذ!',
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
                return SizedBox(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
