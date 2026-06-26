import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/profile_cubit.dart';

class SizeProfilesPage extends StatelessWidget {
  const SizeProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'مقاساتي',
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final items = state.bundle?.sizeProfiles ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TintPrimaryButton(
                label: 'إضافة بروفايل مقاس',
                expanded: true,
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(height: 14),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TintSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _Badge(label: 'مقاس الفساتين: ${item.dressSize}')),
                            const SizedBox(width: 10),
                            Expanded(child: _Badge(label: 'مقاس العباية: ${item.abayaSize}')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.notes,
                          style: const TextStyle(
                            color: TintColors.textMuted,
                            fontSize: 11,
                            height: 1.5,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
