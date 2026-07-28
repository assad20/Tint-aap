import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/hero_slide_model.dart';
import '../../../../core/widgets/tint_ui.dart';

/// سلايدر بانرات مشترك — يُغذّى من بنرات الأدمن.
///
/// يُستعمل بمظهرين:
///  • الرئيسيّة (نمط شي إن): مُلاصق للحواف بلا زوايا، بنسبة عرض/ارتفاع، مع نقاط.
///  • صفحة القسم: ارتفاع ثابت وزوايا مستديرة وهامش — كما كان قبل الترقية.
class TintBannerSlider extends StatefulWidget {
  const TintBannerSlider({
    super.key,
    required this.slides,
    this.height,
    this.aspectRatio = 2.5,
    this.borderRadius = BorderRadius.zero,
    this.margin = EdgeInsets.zero,
    this.pageGap = 0,
    this.showDots = false,
    this.headerInset = 0,
    this.interval = const Duration(seconds: 4),
    this.onSlideTap,
  });

  final List<HeroSlideModel> slides;

  /// ارتفاع ثابت. حين يكون `null` يُشتقّ الارتفاع من [aspectRatio] فيتكيّف
  /// مع عرض الجهاز — وهو المطلوب لبانر الرئيسيّة المُلاصق للحواف.
  final double? height;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  /// فاصل أفقيّ بين الشرائح داخل الـPageView.
  final double pageGap;
  final bool showDots;

  /// ارتفاع الهيدر الطافي فوق السلايدر (نمط شي إن). حين يكون > 0 يزداد
  /// الصندوق بهذا القدر، ويُملأ الفراغ خلف الهيدر **بنسخةٍ مموّهة مكبّرة من
  /// البانر نفسه** — فتبقى الصورة الأصليّة كاملةً بنسبتها أسفل الهيدر بلا
  /// قصّ، ويقع نصّ الهيدر على خلفيّةٍ مموّهة داكنة تُبقيه مقروءاً.
  final double headerInset;
  final Duration interval;
  final void Function(String href)? onSlideTap;

  @override
  State<TintBannerSlider> createState() => _TintBannerSliderState();
}

class _TintBannerSliderState extends State<TintBannerSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scheduleWarmUp();
  }

  @override
  void didUpdateWidget(covariant TintBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // الشرائح تصل بعد الإقلاع (شبكة/لقطة)، فيُعاد الضبط على المجموعة الجديدة.
    final changed = oldWidget.slides.length != widget.slides.length ||
        (widget.slides.isNotEmpty &&
            oldWidget.slides.isNotEmpty &&
            oldWidget.slides.first.image != widget.slides.first.image);
    if (changed) {
      _timer?.cancel();
      if (_index >= widget.slides.length) _index = 0;
      _scheduleWarmUp();
    }
  }

  void _scheduleWarmUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmUpThenAutoPlay());
  }

  /// البنرات ثقيلة (٣٢٠٠×٨٠٠)، وتحميلها أبطأ من دورة التقدّم التلقائيّ — فكان
  /// السلايدر ينزلق إلى مربّع رماديّ. نُحمّلها كلّها أوّلاً ثمّ نبدأ التقدّم،
  /// فلا يُعرض تلقائيّاً إلّا ما وصل فعلاً.
  Future<void> _warmUpThenAutoPlay() async {
    for (final slide in widget.slides) {
      if (!mounted) return;
      final url = TintNetworkImage.resolve(slide.image);
      if (url.isEmpty) continue;
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {
        // صورةٌ تعذّرت لا توقف بقيّة الشرائح ولا التقدّم التلقائيّ.
      }
    }
    if (!mounted) return;
    _restartAutoPlay();
  }

  void _restartAutoPlay() {
    _timer?.cancel();
    if (widget.slides.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final pages = PageView.builder(
      controller: _controller,
      itemCount: widget.slides.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) {
        final slide = widget.slides[i];
        // تمرير height صريح للصورة يجبرها على ملء المربّع (cover) فيختفي الفراغ.
        Widget image = TintNetworkImage(
          url: slide.image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: widget.height,
          borderRadius: widget.borderRadius,
        );
        if (widget.headerInset > 0) {
          image = Stack(
            fit: StackFit.expand,
            children: [
              // خلفيّة الهيدر: البانر نفسه مموّهاً ومعتماً قليلاً. بديلٌ عن
              // تطويل الصندوق وقصّ الصورة — تبقى الأصليّة كاملةً أسفله.
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: TintNetworkImage(
                  url: slide.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Container(color: Colors.black.withOpacity(0.22)),
              Padding(
                padding: EdgeInsets.only(top: widget.headerInset),
                child: image,
              ),
            ],
          );
        }
        if (widget.onSlideTap != null && slide.href.isNotEmpty) {
          image = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSlideTap!(slide.href),
            child: image,
          );
        }
        return widget.pageGap > 0
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.pageGap),
                child: image,
              )
            : image;
      },
    );

    // ارتفاع الصندوق = إزاحة الهيدر + ارتفاع البانر بنسبته الأصليّة، فلا
    // تُقصّ الصورة لتفسح للهيدر مكاناً.
    final box = widget.height != null
        ? SizedBox(height: widget.height! + widget.headerInset, child: pages)
        : LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: widget.headerInset + c.maxWidth / widget.aspectRatio,
              child: pages,
            ),
          );

    return Padding(
      padding: widget.margin,
      child: widget.showDots && widget.slides.length > 1
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                box,
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
          : box,
    );
  }
}
