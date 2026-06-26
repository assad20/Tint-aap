import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/product_card.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final config = _CategoryUiConfig.forName(state.selectedCategory);
        final picks = switch (state.selectedCategory) {
          'المكياج' => state.catalog['makeup'] ?? FakeSeedData.productsByCategory['makeup']!,
          'العطور' => state.catalog['perfumes'] ?? FakeSeedData.productsByCategory['perfumes']!,
          'العبايات' => state.catalog['abayas'] ?? FakeSeedData.productsByCategory['abayas']!,
          'الفساتين' => state.catalog['dresses'] ?? FakeSeedData.productsByCategory['dresses']!,
          'الإكسسوارات' => state.catalog['accessories'] ?? FakeSeedData.productsByCategory['accessories']!,
          'الهدايا' => state.catalog['gifts'] ?? FakeSeedData.productsByCategory['gifts']!,
          _ => FakeSeedData.allProducts.take(6).toList(),
        };

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: TintColors.textMuted),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ابحثي عن قسم أو منتج...',
                                  style: TextStyle(
                                    color: TintColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border_rounded),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.shopping_cart_outlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 92,
                        color: const Color(0xFFF8F9FA),
                        child: ListView.builder(
                          itemCount: state.sidebar.length,
                          itemBuilder: (context, index) {
                            final item = state.sidebar[index];
                            final isActive = item == state.selectedCategory;
                            return InkWell(
                              onTap: () => context.read<CategoriesCubit>().select(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white : Colors.transparent,
                                  border: Border(
                                    right: BorderSide(
                                      color: isActive
                                          ? TintColors.sand
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  item,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isActive
                                        ? TintColors.sand
                                        : TintColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          children: [
                            _CategoriesHero(config: config),
                            const SizedBox(height: 18),
                            const TintSectionHeader(title: 'تسوقي حسب الفئة'),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: config.subCategories.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisExtent: 112,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 18,
                              ),
                              itemBuilder: (context, index) {
                                final item = config.subCategories[index];
                                return Column(
                                  children: [
                                    ClipOval(
                                      child: TintNetworkImage(
                                        url: item.image,
                                        fit: BoxFit.cover,
                                        width: 68,
                                        height: 68,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            TintSectionHeader(
                              title: 'مختارات من أجلك',
                              trailing: TextButton(
                                onPressed: () {},
                                child: const Text('مشاهدة الكل'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: picks.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 260,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (context, index) {
                                return ProductCard(product: picks[index]);
                              },
                            ),
                          ],
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
    );
  }
}

class _CategoriesHero extends StatelessWidget {
  const _CategoriesHero({required this.config});

  final _CategoryUiConfig config;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url: config.heroImage,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(24),
              overlay: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.black.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            left: 18,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.worldTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.worldSubtitle,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const TintStatusPill(
                  label: 'اكتشفي القسم',
                  backgroundColor: Color(0x33FFFFFF),
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryUiConfig {
  const _CategoryUiConfig({
    required this.worldTitle,
    required this.worldSubtitle,
    required this.heroImage,
    required this.subCategories,
  });

  final String worldTitle;
  final String worldSubtitle;
  final String heroImage;
  final List<CategoryModel> subCategories;

  static _CategoryUiConfig forName(String name) {
    final map = <String, _CategoryUiConfig>{
      'الفساتين': _CategoryUiConfig(
        worldTitle: 'عالم الفساتين',
        worldSubtitle: 'تألقي في كل مناسبة',
        heroImage:
            'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80',
        subCategories: const [
          CategoryModel(id: '1', name: 'فساتين يومية', image: 'https://images.unsplash.com/photo-1572804013309-82a89b47afc2?w=200&q=80'),
          CategoryModel(id: '2', name: 'مناسبات وسهرة', image: 'https://images.unsplash.com/photo-1566160983946-77872089b0d3?w=200&q=80'),
          CategoryModel(id: '3', name: 'فساتين ناعمة', image: 'https://images.unsplash.com/photo-1515347619252-5d8122d4f2bc?w=200&q=80'),
          CategoryModel(id: '4', name: 'فساتين طويلة', image: 'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=200&q=80'),
          CategoryModel(id: '5', name: 'فساتين قصيرة', image: 'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=200&q=80'),
          CategoryModel(id: '6', name: 'جديد الفساتين', image: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=200&q=80'),
        ],
      ),
      'الهدايا': _CategoryUiConfig(
        worldTitle: 'عالم الهدايا',
        worldSubtitle: 'لكل مناسبة هدية تليق بها',
        heroImage:
            'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&q=80',
        subCategories: const [
          CategoryModel(id: '1', name: 'هدايا لها', image: 'https://images.unsplash.com/photo-1512909006721-3d6018887383?w=200&q=80'),
          CategoryModel(id: '2', name: 'هدايا فاخرة', image: 'https://images.unsplash.com/photo-1583847268964-b28ce8fca02e?w=200&q=80'),
          CategoryModel(id: '3', name: 'بوكسات هدايا', image: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=200&q=80'),
          CategoryModel(id: '4', name: 'حسب الميزانية', image: 'https://images.unsplash.com/photo-1570831739435-6601aa3fa4fb?w=200&q=80'),
          CategoryModel(id: '5', name: 'هدايا عطور', image: 'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=200&q=80'),
          CategoryModel(id: '6', name: 'مع إكسسوار', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=200&q=80'),
        ],
      ),
      'المكياج': _CategoryUiConfig(
        worldTitle: 'عالم المكياج',
        worldSubtitle: 'أبرزي جمالك بأرقى العلامات',
        heroImage:
            'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800&q=80',
        subCategories: const [
          CategoryModel(id: '1', name: 'مكياج الوجه', image: 'https://images.unsplash.com/photo-1599305090598-fe179d501227?w=200&q=80'),
          CategoryModel(id: '2', name: 'مكياج العيون', image: 'https://images.unsplash.com/photo-1512496015851-a1c8ce0b0973?w=200&q=80'),
          CategoryModel(id: '3', name: 'مكياج الشفاه', image: 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=200&q=80'),
          CategoryModel(id: '4', name: 'الحواجب', image: 'https://images.unsplash.com/photo-1516975080661-422fc2bc016e?w=200&q=80'),
          CategoryModel(id: '5', name: 'أدوات المكياج', image: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=200&q=80'),
          CategoryModel(id: '6', name: 'مجموعات', image: 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=200&q=80'),
        ],
      ),
      'العطور': _CategoryUiConfig(
        worldTitle: 'عالم العطور',
        worldSubtitle: 'نفحات تعكس شخصيتك الفاخرة',
        heroImage:
            'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80',
        subCategories: const [
          CategoryModel(id: '1', name: 'عطور نسائية', image: 'https://images.unsplash.com/photo-1588405748880-12d1d2a59f75?w=200&q=80'),
          CategoryModel(id: '2', name: 'عطور رجالية', image: 'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=200&q=80'),
          CategoryModel(id: '3', name: 'عطور شرقية', image: 'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=200&q=80'),
          CategoryModel(id: '4', name: 'عطور فرنسية', image: 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=200&q=80'),
          CategoryModel(id: '5', name: 'بخور وعود', image: 'https://images.unsplash.com/photo-1608681284852-6ab590fc35df?w=200&q=80'),
          CategoryModel(id: '6', name: 'أطقم عطور', image: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=200&q=80'),
        ],
      ),
      'العبايات': _CategoryUiConfig(
        worldTitle: 'عالم العبايات',
        worldSubtitle: 'أناقة واحتشام في كل تفصيلة',
        heroImage:
            'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=800&q=80',
        subCategories: const [
          CategoryModel(id: '1', name: 'عبايات يومية', image: 'https://images.unsplash.com/photo-1512316668700-111fb08dbf8c?w=200&q=80'),
          CategoryModel(id: '2', name: 'مناسبات فاخرة', image: 'https://images.unsplash.com/photo-1550639525-c97d455acf70?w=200&q=80'),
          CategoryModel(id: '3', name: 'عبايات ملونة', image: 'https://images.unsplash.com/photo-1601333144130-8c1f12369685?w=200&q=80'),
          CategoryModel(id: '4', name: 'عبايات سوداء', image: 'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=200&q=80'),
          CategoryModel(id: '5', name: 'عبايات شتوية', image: 'https://images.unsplash.com/photo-1515347619252-5d8122d4f2bc?w=200&q=80'),
          CategoryModel(id: '6', name: 'جديد العبايات', image: 'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=200&q=80'),
        ],
      ),
    };

    return map[name] ??
        _CategoryUiConfig(
          worldTitle: 'عالم $name',
          worldSubtitle: 'اكتشفي التشكيلة الأحدث',
          heroImage:
              'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
          subCategories: FakeSeedData.quickLinks.take(6).toList(),
        );
  }
}
