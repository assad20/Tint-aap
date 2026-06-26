import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading || state.bundle == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = state.bundle!.profile;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'حسابي',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [TintColors.charcoal, Color(0xFF1A1D21)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: TintNetworkImage(
                          url: profile.avatarUrl,
                          fit: BoxFit.cover,
                          width: 68,
                          height: 68,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.phone,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 12,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: TintColors.sand.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: TintColors.sand.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                profile.membershipTier,
                                style: const TextStyle(
                                  color: TintColors.sand,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MetricCard(
                      value: '${profile.points}',
                      label: 'نقطة',
                      icon: Icons.star_rounded,
                      onTap: () => context.push('/profile/points'),
                    ),
                    const SizedBox(width: 10),
                    _MetricCard(
                      value: '${profile.couponsCount}',
                      label: 'كوبونات',
                      icon: Icons.confirmation_number_outlined,
                      onTap: () => context.push('/profile/coupons'),
                    ),
                    const SizedBox(width: 10),
                    _MetricCard(
                      value: '${profile.walletBalance.toStringAsFixed(0)}﷼',
                      label: 'الرصيد',
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => context.push('/profile/wallet'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TintSurfaceCard(
                  child: Column(
                    children: [
                      TintSectionHeader(
                        title: 'طلباتي',
                        trailing: TextButton(
                          onPressed: () => context.push('/profile/orders'),
                          child: const Text('عرض الكل'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => context.push('/profile/orders'),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: TintColors.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.local_shipping_outlined,
                                    color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'طلب #TN-98765',
                                      style: TextStyle(
                                        color: TintColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'تم الشحن - في الطريق إليك',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => context.push('/profile/orders'),
                                child: const Text('تتبع'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'خدمات حسابي',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    _ServiceTile(
                      icon: Icons.favorite_border_rounded,
                      label: 'المفضلة',
                      onTap: () => context.push('/profile/favorites'),
                    ),
                    _ServiceTile(
                      icon: Icons.location_on_outlined,
                      label: 'العناوين',
                      onTap: () => context.push('/profile/addresses'),
                    ),
                    _ServiceTile(
                      icon: Icons.credit_card_outlined,
                      label: 'طرق الدفع',
                      onTap: () => context.push('/profile/payment-methods'),
                    ),
                    _ServiceTile(
                      icon: Icons.history_rounded,
                      label: 'سجل التصفح',
                      onTap: () => context.push('/profile/browsing-history'),
                    ),
                    _ServiceTile(
                      icon: Icons.straighten_rounded,
                      label: 'مقاساتي',
                      onTap: () => context.push('/profile/size-profiles'),
                    ),
                    _ServiceTile(
                      icon: Icons.card_giftcard_rounded,
                      label: 'بطاقات الهدايا',
                      onTap: () => context.push('/profile/gift-cards'),
                    ),
                    _ServiceTile(
                      icon: Icons.notifications_active_outlined,
                      label: 'تنبيهات التوفر',
                      onTap: () => context.push('/profile/stock-alerts'),
                    ),
                    _ServiceTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'الطلبات السابقة',
                      onTap: () => context.push('/profile/orders'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TintSurfaceCard(
                  color: const Color(0xFFEFF6FF),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.support_agent_rounded,
                            color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحتاجين مساعدة؟',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'فريق الدعم جاهز لخدمتك على مدار الساعة',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => context.push('/assistant'),
                        child: const Text('تواصل'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'بناءً على ذوقك',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ProductCard(product: state.bundle!.browsingHistory.first)),
                    const SizedBox(width: 12),
                    Expanded(child: ProductCard(product: state.bundle!.browsingHistory[1])),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: TintSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: TintColors.sand, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: TintColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: TintSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: TintColors.sand),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
