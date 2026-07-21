import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/home_store_cubit.dart';
import '../widgets/product_card.dart';
import '../widgets/top_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeStoreCubit, HomeStoreState>(
      builder: (context, state) {
        return Column(
          children: [
            const TopHeader(),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        _buildStorefront(context, state),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorefront(BuildContext context, HomeStoreState state) {
    // الأقسام التحريريّة الحقيقيّة من الوسيط (/catalog/bootstrap)؛ التراجُع
    // للبيانات التجريبيّة يحدث فقط إن كان القسم فارغاً (فشل الجلب / بلا اتّصال).
    final newArrivals = state.productsOf('وصل حديثاً');
    final offers = state.productsOf('عروض وخصومات');
    final bestSellers = state.productsOf('الأكثر مبيعاً');
    final picks = state.productsOf('مختارات لك');
    final realPool = <ProductModel>[
      ...bestSellers,
      ...newArrivals,
      ...offers,
      ...picks,
    ];
    final poolOrFake = realPool.isNotEmpty ? realPool : FakeSeedData.allProducts;
    List<ProductModel> or(List<ProductModel> real, List<ProductModel> fallback) =>
        real.isNotEmpty ? real : fallback;

    switch (state.activeTopNav) {
      case 'المكياج':
        return _CategoryStorefront(
          heroImage:
              'https://images.unsplash.com/photo-1515688594390-b649af70d282?w=800&q=80',
          accent: const Color(0xFFF43F5E),
          overline: 'Glow & Glamour',
          title: 'أبرزي جمالك\nبأرقى اللمسات',
          subtitle: 'تشكيلة حصرية من أفضل العلامات التجارية لتتألقي كل يوم.',
          products: poolOrFake,
          chips: const ['للوجه', 'للعيون', 'للشفاه', 'الفرش والأدوات'],
          tipsTitle: 'روتين جمالك المتكامل',
          tipsSubtitle: 'خطوات أساسية لمكياج احترافي وثابت',
          bannerText: 'إطلالة يومية ناعمة',
          gridTitle: 'ترندات المكياج',
        );
      case 'العطور':
        return _CategoryStorefront(
          heroImage:
              'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=800&q=80',
          accent: const Color(0xFFD4AF37),
          darkTheme: true,
          overline: 'Luxury Fragrances',
          title: 'عالم العطور',
          subtitle: 'نفحات تأسر الحواس وتعبر عن أناقتك برقي لا يُنسى.',
          products: poolOrFake,
          chips: const ['عطور نسائية', 'عطور فاخرة', 'عطور يومية', 'هدايا عطور'],
          tipsTitle: 'اختاري حسب الطابع',
          tipsSubtitle: 'عائلات عطرية تناسب كل إحساس',
          bannerText: 'تجربة فاخرة متكاملة',
          gridTitle: 'الأكثر رواجًا الآن',
        );
      case 'العبايات':
        return _CategoryStorefront(
          heroImage:
              'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=800&q=80',
          accent: TintColors.charcoal,
          darkTheme: true,
          overline: 'Boutique Collection',
          title: 'أناقة محتشمة',
          subtitle: 'تصاميم تعكس ذوقك الرفيع في كل تفصيلة.',
          products: poolOrFake,
          chips: const ['عبايات يومية', 'مناسبات فاخرة', 'ملونة', 'عملية'],
          tipsTitle: 'اختاري حسب المناسبة',
          tipsSubtitle: 'تصاميم تناسب أسلوب حياتك',
          bannerText: 'أناقة المناسبات',
          gridTitle: 'اختيارات عميلاتنا',
        );
      case 'الفساتين':
        return _CategoryStorefront(
          heroImage:
              'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80',
          accent: TintColors.sand,
          overline: 'Soft Elegance',
          title: 'إطلالات\nتخطف الأنظار',
          subtitle: 'اكتشفي تشكيلة الفساتين التي تعانق أنوثتك بكل نعومة.',
          products: poolOrFake,
          chips: const ['ناعم', 'فاخر', 'كلاسيكي', 'عصري'],
          tipsTitle: 'تألقي في كل لحظة',
          tipsSubtitle: 'اختاري فستانك حسب مناسبتك القادمة',
          bannerText: 'إطلالات المناسبات',
          gridTitle: 'الفساتين المفضلة',
        );
      case 'الإكسسوارات':
        return _CategoryStorefront(
          heroImage:
              'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=800&q=80',
          accent: const Color(0xFFBDA588),
          overline: 'The Finishing Touch',
          title: 'لمسات تكمل\nأناقتك',
          subtitle: 'تفاصيل صغيرة تصنع فرقًا كبيرًا في إطلالتك.',
          products: poolOrFake,
          chips: const ['أقراط', 'أساور', 'خواتم', 'أطقم'],
          tipsTitle: 'اختاري لمستك',
          tipsSubtitle: 'قطع تعكس شخصيتك الفريدة',
          bannerText: 'تنسيقات جاهزة',
          gridTitle: 'الأكثر مبيعًا',
        );
      case 'الهدايا':
        return _GiftsStorefront(
          products: or(picks, FakeSeedData.productsByCategory['gifts']!),
        );
      case 'الجديد':
        return _SimpleGridStorefront(
          title: 'وصل حديثًا',
          subtitle: 'منتجات جديدة أضيفت هذا الأسبوع',
          products: or(newArrivals, FakeSeedData.newArrivals),
        );
      case 'العروض':
        return _SimpleGridStorefront(
          title: 'عروض اليوم',
          subtitle: 'خصومات حصرية لفترة محدودة',
          products: or(offers, FakeSeedData.offers),
          highlighted: true,
        );
      case 'الرئيسية':
      default:
        return _HomeGatewayStorefront(
          quickLinks: FakeSeedData.quickLinks, // لا خادم للروابط السريعة بعد
          bestSellers: or(bestSellers, FakeSeedData.bestSellers),
          newArrivals: or(newArrivals, FakeSeedData.newArrivals),
          offers: or(offers, FakeSeedData.offers),
          gifts: or(picks, FakeSeedData.productsByCategory['gifts']!),
        );
    }
  }
}

class _HomeGatewayStorefront extends StatelessWidget {
  const _HomeGatewayStorefront({
    required this.quickLinks,
    required this.bestSellers,
    required this.newArrivals,
    required this.offers,
    required this.gifts,
  });

  final List<CategoryModel> quickLinks;
  final List<ProductModel> bestSellers;
  final List<ProductModel> newArrivals;
  final List<ProductModel> offers;
  final List<ProductModel> gifts;

  @override
  Widget build(BuildContext context) {
    final safeGifts = gifts.isNotEmpty ? gifts : FakeSeedData.productsByCategory['gifts']!;
    return Column(
      children: [
        _HeroBanner(
          image:
              'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
          overline: 'تشكيلة الموسم الجديدة',
          title: 'تألقي بإطلالة\nلا تُنسى',
          subtitle: 'اكتشفي أحدث صيحات الموضة والجمال المختارة بعناية لكِ.',
          buttonLabel: 'تسوقي الآن',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 14,
            children: quickLinks
                .map((item) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 5,
                      child: Column(
                        children: [
                          ClipOval(
                            child: TintNetworkImage(
                              url: item.image,
                              fit: BoxFit.cover,
                              width: 58,
                              height: 58,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TintSurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: const Row(
              children: [
                Expanded(child: _PromiseTile(icon: Icons.local_shipping_outlined, label: 'توصيل سريع')),
                Expanded(child: _PromiseTile(icon: Icons.restart_alt_rounded, label: 'إرجاع سهل')),
                Expanded(child: _PromiseTile(icon: Icons.verified_user_outlined, label: 'دفع آمن')),
              ],
            ),
          ),
        ),
        _SectionCarousel(
          title: 'الأكثر مبيعًا',
          subtitle: 'المنتجات المفضلة لدى عميلاتنا',
          items: bestSellers,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TintSectionHeader(title: 'عوالم تنت المتخصصة'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: const [
                  _CategoryWorldCard(
                    image:
                        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&q=80',
                    title: 'عالم المكياج',
                  ),
                  _CategoryWorldCard(
                    image:
                        'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&q=80',
                    title: 'عالم العطور',
                  ),
                  _CategoryWorldCard(
                    image:
                        'https://images.unsplash.com/photo-1589465885855-40813f367eb7?w=400&q=80',
                    title: 'أناقة العبايات',
                  ),
                  _CategoryWorldCard(
                    image:
                        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
                    title: 'فساتينك المفضلة',
                  ),
                ],
              ),
            ],
          ),
        ),
        _SectionCarousel(
          title: 'وصل حديثًا',
          subtitle: 'منتجات جديدة أضيفت خصيصًا لك',
          items: newArrivals,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TintSurfaceCard(
            color: const Color(0xFFFFF4F1),
            child: Column(
              children: [
                const TintSectionHeader(
                  title: 'عروض اليوم',
                  subtitle: 'خصومات حصرية لفترة محدودة',
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: offers.take(2).length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 255,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => ProductCard(
                    product: offers[index],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _WideBanner(
            image:
                'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&q=80',
            title: 'دليلك للهدايا',
            subtitle: 'هدايا جاهزة وتغليف فاخر',
          ),
        ),
        _SectionCarousel(
          title: 'مختارات الهدايا',
          subtitle: 'أفكار جاهزة للمناسبات الخاصة',
          items: safeGifts,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CategoryStorefront extends StatelessWidget {
  const _CategoryStorefront({
    required this.heroImage,
    required this.accent,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.chips,
    required this.tipsTitle,
    required this.tipsSubtitle,
    required this.bannerText,
    required this.gridTitle,
    this.darkTheme = false,
  });

  final String heroImage;
  final Color accent;
  final String overline;
  final String title;
  final String subtitle;
  final List<ProductModel> products;
  final List<String> chips;
  final String tipsTitle;
  final String tipsSubtitle;
  final String bannerText;
  final String gridTitle;
  final bool darkTheme;

  @override
  Widget build(BuildContext context) {
    final isDark = darkTheme;
    final safeProducts = products.isNotEmpty ? products : FakeSeedData.allProducts.take(4).toList();
    return Container(
      color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFFFFFCFB),
      child: Column(
        children: [
          _HeroBanner(
            image: heroImage,
            overline: overline,
            title: title,
            subtitle: subtitle,
            buttonLabel: 'اكتشفي المجموعة',
            darkOverlay: true,
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Text(
                  chips[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? TintColors.charcoal : accent,
                  ),
                ),
              ),
            ),
          ),
          _SectionCarousel(
            title: 'الأكثر مبيعًا',
            subtitle: 'اختيارات عميلاتنا الراقية',
            items: safeProducts,
            accent: accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TintSurfaceCard(
              color: isDark ? const Color(0xFFF7F1E7) : const Color(0xFFFFF5F7),
              child: Column(
                children: [
                  TintSectionHeader(
                    title: tipsTitle,
                    subtitle: tipsSubtitle,
                  ),
                  const SizedBox(height: 12),
                  _WideBanner(
                    image: safeProducts.first.image,
                    title: bannerText,
                    subtitle: 'اختيارات منسقة بعناية لتسهيل قرار الشراء',
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: safeProducts.take(2).length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) => ProductCard(
                      product: safeProducts[index],
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TintSectionHeader(title: gridTitle),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: safeProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
    );
  }
}

class _GiftsStorefront extends StatelessWidget {
  const _GiftsStorefront({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final safeProducts = products.isNotEmpty ? products : FakeSeedData.productsByCategory['gifts']!;
    return Column(
      children: [
        _WideBanner(
          image:
              'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&q=80',
          title: 'دليلك للهدايا',
          subtitle: 'لكل مناسبة، هدية تليق بها',
          height: 180,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _ChoiceChipLabel('لها'),
            _ChoiceChipLabel('فاخرة'),
            _ChoiceChipLabel('ميزانية محدودة'),
            _ChoiceChipLabel('جاهزة للإهداء'),
            _ChoiceChipLabel('أطقم عطور'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TintSectionHeader(title: 'بوكسات هدايا جاهزة'),
              const SizedBox(height: 14),
              ...safeProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TintSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 8,
                              child: TintNetworkImage(
                                url: product.image,
                                fit: BoxFit.cover,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: TintColors.sand,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomLeft: Radius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'هدية مثالية',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text(
                                product.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${product.price.toStringAsFixed(0)}﷼',
                                style: const TextStyle(
                                  color: TintColors.charcoal,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleGridStorefront extends StatelessWidget {
  const _SimpleGridStorefront({
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
      padding: const EdgeInsets.all(16),
      child: TintSurfaceCard(
        color: highlighted ? const Color(0xFFFFF4F1) : Colors.white,
        child: Column(
          children: [
            TintSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
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

class _SectionCarousel extends StatelessWidget {
  const _SectionCarousel({
    required this.title,
    required this.subtitle,
    required this.items,
    this.accent = TintColors.sand,
  });

  final String title;
  final String subtitle;
  final List<ProductModel> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TintSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: TextButton(
              onPressed: () {},
              child: Text(
                'عرض الكل',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 275,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 160,
                child: ProductCard(product: items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.image,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.darkOverlay = false,
  });

  final String image;
  final String overline;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool darkOverlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url: image,
              fit: BoxFit.cover,
              overlay: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: darkOverlay
                        ? [
                            Colors.black.withOpacity(0.78),
                            Colors.black.withOpacity(0.12),
                          ]
                        : [
                            TintColors.charcoal.withOpacity(0.8),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            left: 24,
            bottom: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: TintColors.sand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    overline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE6E8EC),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TintColors.charcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

class _WideBanner extends StatelessWidget {
  const _WideBanner({
    required this.image,
    required this.title,
    required this.subtitle,
    this.height = 145,
  });

  final String image;
  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: TintNetworkImage(
              url: image,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(24),
              overlay: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            left: 18,
            bottom: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TintColors.sand,
                  ),
                  child: const Text('تصفح'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryWorldCard extends StatelessWidget {
  const _CategoryWorldCard({
    required this.image,
    required this.title,
  });

  final String image;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TintNetworkImage(
            url: image,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(22),
            overlay: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.black.withOpacity(0.36),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseTile extends StatelessWidget {
  const _PromiseTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: TintColors.sand),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: TintColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _ChoiceChipLabel extends StatelessWidget {
  const _ChoiceChipLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: TintColors.sand,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: TintColors.sand),
    );
  }
}
