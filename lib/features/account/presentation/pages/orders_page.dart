import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/account_models.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/orders_cubit.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String activeFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'متابعة الطلبات',
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.headset_mic_outlined),
        ),
      ],
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final orders = _filterOrders(state.orders);
          final activeCandidates = state.orders.where((order) =>
              order.status == OrderStatus.processing ||
              order.status == OrderStatus.shipped);
          final activeOrder = activeCandidates.isNotEmpty ? activeCandidates.first : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (activeOrder != null && activeFilter == 'الكل')
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => context.push('/profile/orders/${activeOrder.id}'),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [TintColors.charcoal, Color(0xFF1A1D21)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TintStatusPill(
                                  label: 'أحدث طلب نشط',
                                  backgroundColor: TintColors.sand,
                                  foregroundColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'طلب ${activeOrder.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  activeOrder.status.label,
                                  style: const TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () =>
                                context.push('/profile/orders/${activeOrder.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: TintColors.charcoal,
                            ),
                            child: const Text('تتبع الطلب'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: const [
                    'الكل',
                    'قيد المعالجة',
                    'تم الشحن',
                    'تم التسليم',
                    'ملغاة'
                  ].length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = const [
                      'الكل',
                      'قيد المعالجة',
                      'تم الشحن',
                      'تم التسليم',
                      'ملغاة'
                    ][index];
                    final isActive = label == activeFilter;
                    return ChoiceChip(
                      selected: isActive,
                      label: Text(label),
                      onSelected: (_) => setState(() => activeFilter = label),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: TintEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد طلبات في هذا القسم حالياً',
                    subtitle: 'ستظهر طلباتك هنا بمجرد إنشائها.',
                  ),
                )
              else
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => context.push('/profile/orders/${order.id}'),
                      borderRadius: BorderRadius.circular(24),
                      child: TintSurfaceCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            order.id,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _OrderStatusChip(status: order.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.dateLabel,
                                        style: const TextStyle(
                                          color: TintColors.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${order.total.toStringAsFixed(0)} ﷼',
                                  style: const TextStyle(
                                    color: TintColors.sand,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  ...order.items.take(3).map(
                                    (item) => Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: ClipOval(
                                        child: TintNetworkImage(
                                          url: item.product.image,
                                          fit: BoxFit.cover,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${order.items.length} منتجات',
                                    style: const TextStyle(
                                      color: TintColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TintSecondaryButton(
                                    label: 'عرض التفاصيل',
                                    onPressed: () =>
                                        context.push('/profile/orders/${order.id}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TintPrimaryButton(
                                    label: order.status == OrderStatus.delivered
                                        ? 'إعادة الطلب'
                                        : 'تتبع الطلب',
                                    onPressed: () =>
                                        context.push('/profile/orders/${order.id}'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (activeFilter) {
      case 'قيد المعالجة':
        return orders.where((order) => order.status == OrderStatus.processing).toList();
      case 'تم الشحن':
        return orders.where((order) => order.status == OrderStatus.shipped).toList();
      case 'تم التسليم':
        return orders.where((order) => order.status == OrderStatus.delivered).toList();
      case 'ملغاة':
        return orders.where((order) => order.status == OrderStatus.cancelled).toList();
      default:
        return orders;
    }
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      OrderStatus.processing => const Color(0xFFFFF3E0),
      OrderStatus.shipped => const Color(0xFFEFF6FF),
      OrderStatus.delivered => const Color(0xFFEAF8F1),
      OrderStatus.cancelled => const Color(0xFFFFEBEE),
    };
    final foreground = switch (status) {
      OrderStatus.processing => TintColors.warning,
      OrderStatus.shipped => Colors.blue,
      OrderStatus.delivered => TintColors.success,
      OrderStatus.cancelled => TintColors.danger,
    };

    return TintStatusPill(
      label: status.label,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }
}
