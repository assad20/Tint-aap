import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/stock_alerts_cubit.dart';

/// تنبيهات التوفّر — ما ينتظره العميل من منتجاتٍ نفدت.
///
/// ‼️ **كانت الشاشة تَعِد بما لا سبيل إليه.** تقول «سننبّهك عند عودتها» ولا
/// مسار في الخادم ينشئ تنبيهاً ولا زرّ في صفحة المنتج — فمن فتحها وجدها فارغةً
/// أبداً. (رصده المالك 2026-08-29.)
class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  @override
  void initState() {
    super.initState();
    // تُجلَب عند الفتح لا عند الإقلاع: شاشةٌ يزورها قليلون، ونداءٌ لكلّ إقلاع
    // ثمنٌ يدفعه الجميع.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StockAlertsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TintPageScaffold(
      title: 'تنبيهات التوفر',
      child: BlocBuilder<StockAlertsCubit, StockAlertsState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return const TintEmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'لا توجد تنبيهات توافر',
              // ‼️ يقول **أين** يُضاف التنبيه — وإلّا بقي الوعد بلا طريق.
              subtitle:
                  'افتح منتجاً نفدت كميته واضغط «نبّهني عند التوفّر»، وسنرسل لك إشعاراً حين يعود.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = state.items[index];
              return TintSurfaceCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: TintNetworkImage(
                        url: alert.image,
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
                            alert.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          /// ‼️ **الحالة تُقال لا تُترك للتخمين**: من نُبِّه يعرف
                          /// أنّ المنتج عاد، ومن ينتظر يعرف أنّ اشتراكه قائم —
                          /// وبلا سطرٍ يفرّق بينهما تبدو القائمة واحدة.
                          Text(
                            alert.notified
                                ? 'عاد للتوفّر — أرسلنا لك إشعاراً'
                                : 'بانتظار عودته',
                            style: TextStyle(
                              color: alert.notified
                                  ? TintColors.success
                                  : TintColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await context
                            .read<StockAlertsCubit>()
                            .unsubscribe(alert.productId);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'أُلغي التنبيه.'
                                : 'تعذّر الإلغاء — حاوِل مجدداً.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
