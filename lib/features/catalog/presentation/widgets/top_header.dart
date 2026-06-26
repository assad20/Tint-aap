import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/fake_seed_data.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../shell/presentation/cubit/shell_cubit.dart';
import '../cubit/home_store_cubit.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeStoreCubit, HomeStoreState>(
      builder: (context, state) {
        // إضافة ارتفاع شريط الحالة/النوتش حتى لا يتداخل الشعار مع أعلى الشاشة
        final topInset = MediaQuery.viewPaddingOf(context).top;
        return Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(14, 16 + topInset, 14, 10),
          child: Column(
            children: [
              const Center(child: TintBrandLogo()),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/profile/favorites'),
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: TintColors.textMuted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ابحثي عن مكياج، عطور، عبايات...',
                                style: TextStyle(
                                  color: TintColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.camera_alt_outlined,
                                color: TintColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<ShellCubit>().selectTab(3),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        Positioned(
                          top: -2,
                          left: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: TintColors.sand,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: FakeSeedData.topNavCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    final item = FakeSeedData.topNavCategories[index];
                    final isActive = item == state.activeTopNav;
                    return InkWell(
                      onTap: () => context.read<HomeStoreCubit>().setActiveTopNav(item),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item,
                            style: TextStyle(
                              color: isActive
                                  ? TintColors.sand
                                  : TintColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: isActive ? 28 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: TintColors.sand,
                              borderRadius: BorderRadius.circular(999),
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
      },
    );
  }
}
