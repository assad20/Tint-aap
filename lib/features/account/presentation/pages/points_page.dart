import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/rewards_cubit.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'مكافآت تنت',
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.info_outline_rounded),
        ),
      ],
      child: BlocBuilder<RewardsCubit, RewardsState>(
        builder: (context, state) {
          if (state.isLoading || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = state.bundle!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TintColors.sand, Color(0xFFA37C6F)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amberAccent),
                        SizedBox(width: 6),
                        Text(
                          'إجمالي النقاط الحالية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${bundle.availablePoints}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'نقطة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'تُعادل 25.00 ﷼',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TintStatTile(value: '${bundle.availablePoints}', label: 'متاحة للاستخدام'),
                  const SizedBox(width: 10),
                  TintStatTile(value: '${bundle.pendingPoints}', label: 'قيد الانتظار'),
                  const SizedBox(width: 10),
                  TintStatTile(value: '${bundle.usedPoints}', label: 'مستخدمة سابقًا'),
                ],
              ),
              const SizedBox(height: 14),
              TintSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TintSectionHeader(title: 'المكافأة القادمة'),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: bundle.availablePoints / 2500,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF2F3F5),
                        color: TintColors.sand,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'أنتِ على بُعد ${2500 - bundle.availablePoints} نقطة فقط للحصول على خصم بقيمة 50 ﷼!',
                      style: const TextStyle(
                        color: TintColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TintSurfaceCard(
                color: TintColors.charcoal,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رصيدك جاهز للخصم!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لا تدعي مكافآتك تنتظر، تسوقي الآن.',
                            style: TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: TintColors.sand,
                      ),
                      child: const Text('تسوقي الآن'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'كيف أجمع نقاط أكثر؟',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: const [
                  _TipsTile(icon: Icons.shopping_bag_outlined, title: 'تسوقي أكثر', subtitle: '1 نقطة لكل ريال تنفقينه'),
                  _TipsTile(icon: Icons.star_border_rounded, title: 'قيّمي مشترياتك', subtitle: '10 نقاط لكل تقييم'),
                  _TipsTile(icon: Icons.share_outlined, title: 'ادعي صديقاتك', subtitle: '50 نقطة لكل دعوة ناجحة'),
                  _TipsTile(icon: Icons.photo_camera_back_outlined, title: 'شاركي صورك', subtitle: '20 نقطة لمشاركة الإطلالة'),
                ],
              ),
              const SizedBox(height: 14),
              TintSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: TintSectionHeader(title: 'سجل النقاط'),
                    ),
                    ...bundle.history.map(
                      (item) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.type == 'earn'
                              ? const Color(0xFFEAF8F1)
                              : const Color(0xFFF4F5F6),
                          child: Icon(
                            item.type == 'earn'
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: item.type == 'earn'
                                ? TintColors.success
                                : TintColors.charcoal,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(item.dateLabel),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.points,
                              style: TextStyle(
                                color: item.type == 'earn'
                                    ? TintColors.success
                                    : TintColors.charcoal,
                                fontWeight: FontWeight.w900,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                            Text(
                              item.status,
                              style: const TextStyle(
                                color: TintColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TipsTile extends StatelessWidget {
  const _TipsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TintSurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF4F0),
            child: Icon(icon, color: TintColors.sand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TintColors.textMuted,
                    fontSize: 10,
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
