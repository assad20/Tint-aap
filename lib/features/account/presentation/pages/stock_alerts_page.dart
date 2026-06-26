import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/profile_cubit.dart';

class StockAlertsPage extends StatelessWidget {
  const StockAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'تنبيهات التوفر',
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final alerts = state.bundle?.stockAlerts ?? const [];
          if (alerts.isEmpty) {
            return const TintEmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'لا توجد تنبيهات توافر',
              subtitle: 'أضيفي منتجات منتهية الكمية وسننبهك عند عودتها.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return TintSurfaceCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: TintNetworkImage(
                        url: alert.product.image,
                        fit: BoxFit.cover,
                        width: 72,
                        height: 88,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.product.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            alert.variant,
                            style: const TextStyle(
                              color: TintColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.createdAtLabel,
                            style: const TextStyle(
                              color: TintColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {},
                      child: const Text('إلغاء'),
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
