import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/tint_ui.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../cubit/profile_cubit.dart';

class BrowsingHistoryPage extends StatelessWidget {
  const BrowsingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'سجل التصفح',
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final items = state.bundle?.browsingHistory ?? const [];
          if (items.isEmpty) {
            return const TintEmptyState(
              icon: Icons.history_rounded,
              title: 'لا يوجد سجل تصفح بعد',
              subtitle: 'ابدئي التصفح وسيظهر سجل المنتجات التي شاهدتها هنا.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => ProductCard(product: items[index]),
          );
        },
      ),
    );
  }
}
