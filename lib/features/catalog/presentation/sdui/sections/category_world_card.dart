import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/widgets/tint_ui.dart';

/// بطاقة القسم: تتبدّل صورها تلقائيّاً حين تُرفع أكثر من واحدة من اللوحة،
/// وتبقى ثابتة بصورةٍ واحدة. الصور مرصوفة فوق بعضها ويتبدّل ظهورها فلا
/// تحميل عند كلّ تبدّل ولا وميض.
///
/// ‼️ نُقلت حرفيّاً من `home_page.dart` (كانت `_CategoryWorldCard`).
///
/// ‼️ **ولم تُسجَّل في سجلّ المكوّنات بعد** (المهمّة 2.6 معلّقة): نوع الخادم
/// `category_highlights` **أغنى منها** — يدعم أربعة أنماط محتوى
/// (`image · products · gateway · manual`) بشعارات ماركات ومنتجاتٍ تحت البانر،
/// وهذه البطاقة تعرض صورةً وعنواناً فقط. وتسجيلُها اليوم يعني أن يضع المسوّق
/// كتلة «منتجات» فيراها في الويب ولا يراها في التطبيق — بلا خطأ ولا سجلّ.
class TintCategoryWorldCard extends StatefulWidget {
  const TintCategoryWorldCard({
    super.key,
    required this.images,
    required this.title,
    required this.index,
  });

  final List<String> images;
  final String title;

  /// موضع البطاقة في الشبكة — يُؤخّر بدايتها فلا يتبدّل الصفّ كلّه دفعةً
  /// واحدة (وهو ما يبدو آليّاً مزعجاً بدل حركةٍ هادئة).
  final int index;

  @override
  State<TintCategoryWorldCard> createState() => _TintCategoryWorldCardState();
}

class _TintCategoryWorldCardState extends State<TintCategoryWorldCard> {
  int _active = 0;
  Timer? _timer;
  Timer? _stagger;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TintCategoryWorldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      if (_active >= widget.images.length) _active = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _stagger?.cancel();
    if (widget.images.length <= 1) return;
    _stagger = Timer(Duration(milliseconds: widget.index * 450), () {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _active = (_active + 1) % widget.images.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stagger?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < widget.images.length; i++)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: i == _active ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: TintNetworkImage(
                url: widget.images[i],
                fit: BoxFit.cover,
                // بلا مقاسٍ صريح تُعطي Stack قيوداً مرنة، فتنكمش الصورة إلى
                // نسبتها الأصليّة وتتوسّط ويظهر الرماديّ حولها — و`cover` لا
                // يقصّ شيئاً لأنّ الصندوق صار بمقاس الصورة أصلاً.
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withOpacity(0.36),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
