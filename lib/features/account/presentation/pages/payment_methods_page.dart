import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/profile_cubit.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'طرق الدفع',
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final cards = state.bundle?.paymentCards ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TintPrimaryButton(
                label: 'إضافة بطاقة جديدة',
                expanded: true,
                onPressed: () {},
                icon: const Icon(Icons.add_card_rounded),
              ),
              const SizedBox(height: 14),
              ...cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: card.isDefault
                            ? [TintColors.charcoal, const Color(0xFF1A1D21)]
                            : [const Color(0xFFF7F8FA), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              card.brand,
                              style: TextStyle(
                                color: card.isDefault ? Colors.white : TintColors.sand,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            const Spacer(),
                            if (card.isDefault)
                              const TintStatusPill(
                                label: 'الافتراضية',
                                backgroundColor: TintColors.sand,
                                foregroundColor: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          card.maskedNumber,
                          style: TextStyle(
                            color: card.isDefault ? Colors.white : TintColors.charcoal,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.label,
                          style: TextStyle(
                            color: card.isDefault ? Colors.white70 : TintColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
