import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product_model.dart';
import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';

/// يُطلق `view_item_list` **حين تُرى القائمة فعلاً** لا حين تُبنى.
///
/// ‼️ **والفرق ليس تفصيلاً.** أقسام الرئيسيّة تُبنى كلّها دفعةً واحدة داخل
/// `Column` (لا `ListView` كسول)، فإطلاق الحدث في `build` أو `initState` يُسجّل
/// «شوهدت هذه القائمة» لستّ قوائمَ لم ينزل المستخدم إلى أيٍّ منها. والنتيجة
/// ليست عدداً زائداً فحسب: معدّل «القائمة ← المنتج» ينهار في التقارير، فيبدو
/// أنّ الرفوف لا تُقنع أحداً بينما الحقيقة أنّها لم تُعرض.
///
/// وهو نفس الخطأ الذي وقع في `view_cart` (رُصد بالتشغيل 2026-08-13): حدثٌ
/// موصولٌ في موضعٍ لا يعني الفعل الذي يقيسه.
///
/// فيُقاس الظهور من موضع الودجة في الشاشة، ويُطلَق **مرّةً لكلّ قائمة** —
/// وتغيّر منتجاتها (تبديل تبويبٍ علويّ مثلاً) قائمةٌ جديدة.
class ProductListImpression extends StatefulWidget {
  const ProductListImpression({
    super.key,
    required this.listName,
    required this.products,
    required this.child,
  });

  final String listName;
  final List<ProductModel> products;
  final Widget child;

  @override
  State<ProductListImpression> createState() => _ProductListImpressionState();
}

class _ProductListImpressionState extends State<ProductListImpression> {
  /// ‼️ أقلّ ارتفاعٍ ظاهرٍ يُعدّ «رؤية»: حافّةٌ بعشرين بكسلاً تحت الشاشة ليست
  /// عرضاً، وطلبُ القائمة كاملةً يُسقط الرفوف الطويلة التي لا تُرى دفعةً.
  static const double _minVisiblePx = 120;

  ScrollPosition? _position;
  String? _logged;

  String get _signature =>
      '${widget.listName}|${widget.products.take(20).map((p) => p.id).join(',')}';

  @override
  void initState() {
    super.initState();
    // قائمةٌ ظاهرةٌ بلا تمرير (أوّل رفٍّ في الشاشة) لا يصلها إشعار تمرير أبداً.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) return;
    _position?.removeListener(_check);
    _position = next;
    _position?.addListener(_check);
  }

  @override
  void didUpdateWidget(covariant ProductListImpression oldWidget) {
    super.didUpdateWidget(oldWidget);
    // المنتجات تصل بعد البناء (شبكة)، والتبويب العلويّ يُبدّلها كلّها.
    if (_logged != _signature) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted || widget.products.isEmpty) return;

    final signature = _signature;
    if (_logged == signature) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.of(context).size.height;
    final visible =
        (top + box.size.height).clamp(0.0, screen) - top.clamp(0.0, screen);
    if (visible < _minVisiblePx) return;

    _logged = signature;
    context.read<TrackingService>().logViewItemList(
          listId: widget.listName,
          listName: widget.listName,
          products: widget.products,
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
