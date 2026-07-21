import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/addresses_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          // عند تسجيل الدخول أعِد تحميل بيانات الحساب الحقيقيّة من الخادم.
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, auth) {
            if (auth.isAuthenticated) {
              context.read<ProfileCubit>().load();
              context.read<OrdersCubit>().load();
              context.read<AddressesCubit>().load();
            }
          },
          builder: (context, auth) {
            if (auth.status == AuthStatus.unknown) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!auth.isAuthenticated) {
              return const _SignInGate();
            }
            return const _AccountDashboard();
          },
        ),
      ),
    );
  }
}

// بوّابة تسجيل الدخول — تظهر لغير المسجّلين بدل لوحة حساب وهميّة.
class _SignInGate extends StatelessWidget {
  const _SignInGate();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: TintColors.blush,
            child: Icon(Icons.person_outline_rounded, size: 42, color: TintColors.sand),
          ),
          const SizedBox(height: 22),
          const Text(
            'مرحباً بك في تِنت',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: TintColors.charcoal),
          ),
          const SizedBox(height: 8),
          const Text(
            'سجّلي الدخول لمتابعة طلباتك وعناوينك وتفاصيل حسابك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TintColors.textMuted, height: 1.7, fontSize: 13),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TintColors.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.push('/login'),
              child: const Text(
                'تسجيل الدخول',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDashboard extends StatelessWidget {
  const _AccountDashboard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.isLoading || state.bundle == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = state.bundle!.profile;
        final auth = context.read<AuthCubit>().state;
        final name = profile.name.isNotEmpty
            ? profile.name
            : (auth.customer?.name?.isNotEmpty == true ? auth.customer!.name! : 'عميلة تِنت');
        final phone = profile.phone.isNotEmpty ? profile.phone : (auth.customer?.phone ?? '');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          children: [
            const Text(
              'حسابي',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            // بطاقة الهويّة — اسم/جوّال من /customer/me.
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
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: TintColors.sand,
                    child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            phone,
                            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // طلباتي — رابط لصفحة الطلبات الحقيقيّة (/customer/orders).
            TintSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _LinkRow(
                    icon: Icons.receipt_long_outlined,
                    iconColor: Colors.blue,
                    title: 'طلباتي',
                    subtitle: 'تابعي حالة طلباتك ومشترياتك',
                    onTap: () => context.push('/profile/orders'),
                  ),
                  const Divider(height: 1),
                  _LinkRow(
                    icon: Icons.location_on_outlined,
                    iconColor: TintColors.sand,
                    title: 'عناويني',
                    subtitle: 'إدارة عناوين التوصيل',
                    onTap: () => context.push('/profile/addresses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // بطاقة الدعم / المستشار الذكيّ.
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
                    child: const Icon(Icons.support_agent_rounded, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحتاجين مساعدة؟',
                          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'مستشار تِنت الذكيّ جاهز لخدمتك',
                          style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11),
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
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: () async {
                await context.read<AuthCubit>().logout();
                if (context.mounted) context.read<ProfileCubit>().load();
              },
              style: TextButton.styleFrom(foregroundColor: TintColors.danger),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(color: TintColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: TintColors.textMuted),
          ],
        ),
      ),
    );
  }
}
