import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/orders_cubit.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final order = context.read<OrdersCubit>().findById(orderId);

    if (order == null) {
      return const TintPageScaffold(
        title: 'تفاصيل الطلب',
        child: TintEmptyState(
          icon: Icons.search_off_rounded,
          title: 'تعذر العثور على الطلب',
          subtitle: 'قد يكون هذا الطلب غير موجود أو تم حذفه.',
        ),
      );
    }

    return TintPageScaffold(
      title: 'تفاصيل الطلب',
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.copy_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _Header(order: order),
          const SizedBox(height: 12),
          if (order.status != OrderStatus.cancelled)
            _TimelineCard(order: order),
          if (order.status != OrderStatus.cancelled) const SizedBox(height: 12),
          TintSurfaceCard(
            child: Column(
              children: [
                TintSectionHeader(title: 'المنتجات (${order.items.length})'),
                const SizedBox(height: 12),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: TintNetworkImage(
                            url: item.product.image,
                            fit: BoxFit.cover,
                            width: 64,
                            height: 72,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.variant,
                                style: const TextStyle(
                                  color: TintColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'الكمية: ${item.qty}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.product.price.toStringAsFixed(0)} ﷼',
                                    style: const TextStyle(
                                      color: TintColors.sand,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TintSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: TintColors.sand),
                          SizedBox(width: 6),
                          Text(
                            'عنوان التوصيل',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.address,
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
              const SizedBox(width: 12),
              Expanded(
                child: TintSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.credit_card_outlined, color: TintColors.sand),
                          SizedBox(width: 6),
                          Text(
                            'طريقة الدفع',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TintSurfaceCard(
            child: Column(
              children: [
                const TintSectionHeader(title: 'ملخص الدفع'),
                const SizedBox(height: 12),
                _Row(label: 'المجموع الفرعي', value: '${order.subtotal.toStringAsFixed(2)} ﷼'),
                const SizedBox(height: 8),
                _Row(label: 'رسوم التوصيل', value: order.shipping == 0 ? 'مجاني' : '${order.shipping.toStringAsFixed(2)} ﷼'),
                const Divider(height: 26),
                _Row(
                  label: 'الإجمالي النهائي',
                  value: '${order.total.toStringAsFixed(2)} ﷼',
                  big: true,
                ),
              ],
            ),
          ),
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 14),
            TintPrimaryButton(
              label: 'إعادة الطلب',
              expanded: true,
              onPressed: () {},
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final config = switch (order.status) {
      OrderStatus.processing => (const Color(0xFFFFF3E0), TintColors.warning, Icons.inventory_2_outlined),
      OrderStatus.shipped => (const Color(0xFFEFF6FF), Colors.blue, Icons.local_shipping_outlined),
      OrderStatus.delivered => (const Color(0xFFEAF8F1), TintColors.success, Icons.check_circle_outline_rounded),
      OrderStatus.cancelled => (const Color(0xFFFFEBEE), TintColors.danger, Icons.error_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.$1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.$2.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(config.$3, color: config.$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: TextStyle(
                    color: config.$2,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تاريخ الطلب: ${order.dateLabel}',
                  style: const TextStyle(
                    color: TintColors.textMuted,
                    fontSize: 11,
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final currentStep = switch (order.status) {
      OrderStatus.processing => 1,
      OrderStatus.shipped => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => 0,
    };

    final steps = const [
      ('تم الطلب', Icons.receipt_long_outlined),
      ('قيد المعالجة', Icons.inventory_2_outlined),
      ('تم الشحن', Icons.local_shipping_outlined),
      ('تم التسليم', Icons.check_circle_outline_rounded),
    ];

    return TintSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TintSectionHeader(title: 'حالة التتبع'),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              steps.length,
              (index) {
                final isDone = index <= currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: isDone ? TintColors.sand : const Color(0xFFF2F3F5),
                        foregroundColor: isDone ? Colors.white : TintColors.textMuted,
                        child: Icon(steps[index].$2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index].$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDone ? TintColors.charcoal : TintColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.big = false,
  });

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: big ? TintColors.charcoal : TintColors.textMuted,
              fontWeight: big ? FontWeight.w800 : FontWeight.w600,
              fontSize: big ? 13 : 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: big ? TintColors.sand : TintColors.charcoal,
            fontWeight: FontWeight.w900,
            fontSize: big ? 20 : 13,
          ),
        ),
      ],
    );
  }
}
