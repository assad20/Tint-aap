import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/rewards_cubit.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'المحفظة',
      child: BlocBuilder<RewardsCubit, RewardsState>(
        builder: (context, state) {
          final bundle = state.bundle;
          if (bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TintColors.charcoal, Color(0xFF1A1D21)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Text(
                      'الرصيد المتاح',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${bundle.walletBalance.toStringAsFixed(2)} ﷼',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'سجل العمليات',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TintSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: bundle.walletTransactions
                      .map(
                        (transaction) => ListTile(
                          title: Text(
                            transaction.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(transaction.dateLabel),
                          trailing: Text(
                            transaction.amountLabel,
                            style: const TextStyle(
                              color: TintColors.success,
                              fontWeight: FontWeight.w900,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
