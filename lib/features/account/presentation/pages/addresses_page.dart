import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/addresses_cubit.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'عناويني المحفوظة',
      child: BlocBuilder<AddressesCubit, AddressesState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              InkWell(
                onTap: () => context.push('/profile/addresses/form'),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: TintColors.sand.withOpacity(0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.add, color: TintColors.sand),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'إضافة عنوان جديد',
                        style: TextStyle(
                          color: TintColors.sand,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...state.items.map(
                (address) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TintSurfaceCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: address.isDefault
                                  ? TintColors.sand
                                  : const Color(0xFFF5F6F8),
                              foregroundColor:
                                  address.isDefault ? Colors.white : TintColors.textMuted,
                              child: Icon(
                                address.title == 'المنزل'
                                    ? Icons.home_outlined
                                    : address.title == 'العمل'
                                        ? Icons.work_outline_rounded
                                        : Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${address.city}، ${address.neighborhood}',
                                    style: const TextStyle(
                                      color: TintColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (address.isDefault)
                              const TintStatusPill(
                                label: 'الافتراضي',
                                backgroundColor: TintColors.sand,
                                foregroundColor: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(label: 'اسم المستلم', value: address.recipient),
                        _InfoRow(label: 'رقم الجوال', value: address.mobile),
                        _InfoRow(label: 'تفاصيل العنوان', value: address.details),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!address.isDefault)
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => context
                                      .read<AddressesCubit>()
                                      .makeDefault(address.id),
                                  child: const Text('تعيين كافتراضي'),
                                ),
                              ),
                            if (!address.isDefault) const SizedBox(width: 10),
                            Expanded(
                              child: TintSecondaryButton(
                                label: 'تعديل',
                                onPressed: () => context.push(
                                  '/profile/addresses/form?id=${address.id}',
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 52,
                              child: FilledButton.tonal(
                                onPressed: () =>
                                    context.read<AddressesCubit>().remove(address.id),
                                child: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: TintColors.textMuted,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
