import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/profile_cubit.dart';

class GiftCardsPage extends StatelessWidget {
  const GiftCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'بطاقات الهدايا',
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final cards = state.bundle?.giftCards ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TintColors.sand, Color(0xFF9B6C5B)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      card.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.balanceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.code,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.expiryLabel,
                      style: const TextStyle(color: Colors.white70),
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
