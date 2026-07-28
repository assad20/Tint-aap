import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/home_store_cubit.dart';
import '../widgets/banner_slider.dart';
import '../widgets/product_card.dart';
import '../widgets/top_header.dart';

/// النقر على بانر يفتح قسمه (كشي إن). وجهة البانر تأتي بصيغة الويب
/// `/category/<slug>`، ولا مسار مقابل لها في `app_router` — الأقسام تُعرض
/// بتبديل التبويب داخل القشرة. فنترجم الوجهة إلى القسم المطابق، وأيّ وجهة
/// أخرى تُتجاهَل بلا فعل (لا شاشة بيضاء ولا تعطّل).
void _openSlideTarget(BuildContext context, String href) {
  final match = RegExp(r'/category/([^/?#]+)').firstMatch(href);
  if (match == null) return;
  final slug = Uri.decodeComponent(match.group(1)!);
  final cubit = context.read<HomeStoreCubit>();
  for (final category in cubit.state.topNav) {
    if (category.id == slug) {
      cubit.setActiveTopNav(category.name);
      return;
    }
  }
}

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
    List<ProductModel> or(List<ProductModel> real, List<ProductModel> fallback) =>
        real.isNotEmpty ? real : fallback;

    // «الرئيسية» = البوّابة بالأقسام التحريريّة الحقيقيّة من /catalog/bootstrap.
    if (state.activeTopNav == kHomeNav) {
      return _HomeGatewayStorefront(
        heroSlides: state.heroSlides,
        quickLinks: state.topNav.isNotEmpty ? state.topNav : FakeSeedData.quickLinks,
        bestSellers: or(bestSellers, FakeSeedData.bestSellers),
        newArrivals: or(newArrivals, FakeSeedData.newArrivals),
        offers: or(offers, FakeSeedData.offers),
        gifts: or(picks, FakeSeedData.productsByCategory['gifts']!),
      );
    }

    // أيّ قسم آخر = قسم متجر حقيقيّ من /catalog/navigation → منتجاته الفعليّة.
    if (state.isCategoryLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 90),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.categoryProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
        child: Center(
          child: Text(
            'لا منتجات في «${state.activeTopNav}» حالياً',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TintColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    // سلايدر القسم أعلى الشاشة (كشي إن): كلّ تبويب علويّ يُظهر بنراته.
    // نسبته 4:1 لا 2.5:1 لأنّ بنرات الأقسام تُصمَّم 3200×800 بخلاف بنرات
    // الرئيسيّة 2304×912 — نسبةٌ واحدة كانت ستقتصّ جوانبها.
    return Column(
      children: [
        if (state.categoryBanners.isNotEmpty)
          TintBannerSlider(
            slides: state.categoryBanners
                .map((url) => HeroSlideModel(image: url))
                .toList(),
            aspectRatio: 4,
            showDots: true,
          ),
        _SimpleGridStorefront(
          title: state.activeTopNav,
          subtitle: 'تشكيلة القسم',
          products: state.categoryProducts,
        ),
      ],
    );
  }
}

class _HomeGatewayStorefront extends StatelessWidget {
  const _HomeGatewayStorefront({
    required this.heroSlides,
    required this.quickLinks,
    required this.bestSellers,
    required this.newArrivals,
    required this.offers,
    required this.gifts,
  });

  final List<HeroSlideModel> heroSlides;
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
        // سلايدر البنرات (نمط شي إن): مُلاصق للحواف بلا زوايا ولا فجوة عن
        // المنيو، ولا طبقة نصّ من الشيفرة — النصّ مطبوع في صورة البانر نفسها.
        // البنرات تُدار من «استوديو البنرات» (موضع `hero`).
        TintBannerSlider(
          slides: heroSlides,
          aspectRatio: 2.5,
          showDots: true,
          onSlideTap: (href) => _openSlideTarget(context, href),
        ),
        _SectionCarousel(
          title: 'الأكثر مبيعًا',
          subtitle: 'الأكثر رواجًا لدى عملائنا',
          items: bestSellers,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TintSectionHeader(title: 'تسوّق حسب القسم'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                // بلا padding صريح يضيف Flutter حشوة MediaQuery العلويّة
                // والسفليّة تلقائيّاً — والرئيسيّة بلا SafeArea (تتعامل مع
                // شريط الحالة داخل TopHeader) فكانت تظهر فراغات فوق كلّ شبكة.
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: quickLinks
                    .take(4)
                    .map((c) => GestureDetector(
                          onTap: () =>
                              context.read<HomeStoreCubit>().setActiveTopNav(c.name),
                          child: _CategoryWorldCard(image: c.image, title: c.name),
                        ))
                    .toList(),
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
                  padding: EdgeInsets.zero,
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
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: TintSurfaceCard(
        color: highlighted ? const Color(0xFFFFF4F1) : Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            TintSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
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
