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

  String get _countdown {
    final d = _remaining;
    String two(int n) => n.toString().padLeft(2, '0');
    // الأيّام تُضاف إلى الساعات: «٥٠:12:30» أوضح من «2ي 02:12:30» في سطرٍ ضيّق.
    final hours = d.inHours;
    return '${two(hours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

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
                    child: Text(
                      _countdown,
                      // ‼️ أرقامٌ لاتينيّة واتّجاه LTR: العدّاد يُقرأ ساعة:دقيقة:ثانية
                      //    ويُقلب في سياقٍ عربيّ فيصير الثواني أوّلاً.
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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
