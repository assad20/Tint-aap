import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/rewards_cubit.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'الكوبونات المتاحة',
      child: BlocBuilder<RewardsCubit, RewardsState>(
        builder: (context, state) {
          final coupons = state.bundle?.coupons ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return TintSurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (coupon.badge != null) ...[
                            TintStatusPill(
                              label: coupon.badge!,
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            coupon.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupon.subtitle,
                            style: const TextStyle(
                              color: TintColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          color: TintColors.sand,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
