import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/product_model.dart';
import '../../../../../core/widgets/tint_ui.dart';
import '../../widgets/product_card.dart';

/// عرضٌ محدود بوقت — يقابل `FlashSaleSection` في الويب.
///
/// ‼️ **وفارغٌ يعني لا شيء**: الويب يُرجع `null` عند `items.length == 0`، فرفٌّ
/// بعنوانٍ وعدّادٍ بلا منتجات إعلانٌ عن لا شيء.
///
/// ‼️ و`endsAt` **اختياريّ**: بلا تاريخٍ يُعرَض الرفّ بلا عدّاد. والويب كذلك
/// (`endsAt` يصير `null` إن لم يكن نصّاً غير فارغ).
class TintFlashSale extends StatefulWidget {
  const TintFlashSale({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.endsAt,
  });

  final String title;
  final String? subtitle;
  final List<ProductModel> items;
  final DateTime? endsAt;

  @override
  State<TintFlashSale> createState() => _TintFlashSaleState();
}

class _TintFlashSaleState extends State<TintFlashSale> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sync();
    // ‼️ المؤقّت يعمل فقط إن كان هناك ما يُعَدّ: مؤقّتٌ يدقّ كلّ ثانية في صفحةٍ
    //    بلا عدّاد استهلاكُ بطّاريّةٍ بلا مقابل.
    if (widget.endsAt != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
    }
  }

  @override
  void didUpdateWidget(covariant TintFlashSale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _ticker?.cancel();
      _sync();
      if (widget.endsAt != null) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
      }
    }
  }

  void _sync() {
    final end = widget.endsAt;
    if (end == null) return;
    final left = end.difference(DateTime.now());
    final next = left.isNegative ? Duration.zero : left;
    if (next == _remaining) return;
    if (!mounted) return;
    setState(() => _remaining = next);
    if (next == Duration.zero) _ticker?.cancel();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// ‼️ **الساعة وحدها هنا — والأيّام في ودجةٍ منفصلة.**
  ///
  /// كُشف على المحاكي مرّتين:
  ///  ١· كانت الأيّام تُضاف إلى الساعات، فعرضٌ ينتهي بعد سنواتٍ أظهر
  ///     `643397:11:47` — رقمٌ لا يقرؤه أحد ولا يوحي بإلحاح، وهو نقيض الغرض.
  ///  ٢· ثمّ وُضعت `26808ي 04:55` في نصٍّ واحد اتّجاهه `ltr`، فحرفٌ عربيّ داخل
  ///     نصٍّ لاتينيّ الاتّجاه قلبَ ترتيب المقاطع وظهر `ي 2680804:55`.
  ///
  /// ولا اختبارٌ التقط أيّاً منهما: كلاهما شكلُ نصٍّ لا منطق.
  String get _clock {
    final d = _remaining;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours % 24)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  int get _days => _remaining.inDays;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TintSectionHeader(
            title: widget.title,
            subtitle: widget.subtitle ?? '',
            trailing: widget.endsAt == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TintColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_days > 0) ...[
                          // نصٌّ عربيّ باتّجاهه الطبيعيّ — منفصلٌ عن الساعة.
                          Text(
                            _days == 1 ? 'يوم' : '$_days يوماً',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _clock,
                          // ‼️ اتّجاهٌ لاتينيّ: الساعة تُقرأ ساعة:دقيقة:ثانية،
                          //    وتُقلب في سياقٍ عربيّ فتصير الثواني أوّلاً.
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 275,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 160,
                child: ProductCard(product: widget.items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
