import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../assistant/presentation/cubit/assistant_cubit.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../catalog/presentation/pages/categories_page.dart';
import '../../../catalog/presentation/pages/home_page.dart';
import '../../../catalog/presentation/pages/trends_page.dart';
import '../../../account/presentation/pages/profile_page.dart';
import '../cubit/shell_cubit.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  static const _pages = [
    HomePage(),
    TrendsPage(),
    CategoriesPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, int>(
      builder: (context, currentIndex) {
        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  // يملأ الشاشة كاملة على الجوالات، ويُقيَّد ويُوسَّط على الأجهزة اللوحية.
                  // المساحة الآمنة العلوية تُدار داخل كل صفحة (AppBar أو TopHeader).
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    color: Colors.white,
                    child: IndexedStack(
                      index: currentIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 96,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push('/assistant'),
                  backgroundColor: TintColors.sand,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    'مستشار تنت',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShellCubit>();
    // مساحة آمنة سفلية متغيرة حسب الجهاز (شريط الإيماءات/الزر السفلي)
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final items = [
      _NavItem(icon: Icons.person_outline_rounded, label: 'حسابي', index: 4),
      _NavItem(icon: Icons.trending_up_rounded, label: 'الترندات', index: 1),
      _NavItem(icon: Icons.grid_view_rounded, label: 'الأقسام', index: 2),
      _NavItem(icon: Icons.shopping_cart_outlined, label: 'السلة', index: 3),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TintColors.line)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              for (final item in items.take(2))
                Expanded(
                  child: _BottomNavButton(
                    item: item,
                    isActive: currentIndex == item.index,
                    onTap: () => cubit.selectTab(item.index),
                  ),
                ),
              const SizedBox(width: 74),
              for (final item in items.skip(2))
                Expanded(
                  child: _BottomNavButton(
                    item: item,
                    isActive: currentIndex == item.index,
                    onTap: () => cubit.selectTab(item.index),
                  ),
                ),
            ],
          ),
          Positioned(
            top: -28,
            child: InkWell(
              onTap: () => cubit.selectTab(0),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: currentIndex == 0 ? TintColors.sand : TintColors.charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const TintBrandLogo(isLight: true, compact: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? TintColors.sand : TintColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
}
