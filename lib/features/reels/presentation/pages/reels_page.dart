import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:share_plus/share_plus.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../account/presentation/cubit/favorites_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/reel_model.dart';
import '../cubit/reels_cubit.dart';
import '../widgets/reel_video.dart';

/// شريط فيديو المنتجات — شاشةٌ رأسيّة على نمط المقاطع القصيرة.
///
/// ‼️ **الغاية بيعٌ لا تسلية.** كلّ مقطعٍ يحمل طريقاً واحداً واضحاً إلى الشراء:
/// زرٌّ عريض يضيف للسلّة في مكانه، وبطاقةٌ تفتح المنتج لمن يريد التفاصيل. ومقطعٌ
/// جميل بلا طريقٍ للشراء وقتٌ يمرّ بلا أثر.
/// ‼️ **السعران يُطبعان بالقاعدة نفسها.** طبعُ الحاليّ بكسوره والقديم بلا كسور
/// جعل «16.31» بجانب «16» مشطوباً — أي سعرٌ قديم يبدو **أقلّ** من الحاليّ.
String _money(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // شريطٌ داكن يملأ الشاشة: أيقونات النظام تُقلب فاتحةً وإلّا اختفت في السواد.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(context.read<ReelsCubit>().load());
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsCubit, ReelsState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }
          if (state.isEmpty) return _EmptyReels(failed: state.failed);

          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: state.items.length,
                onPageChanged: (index) {
                  setState(() => _index = index);
                  unawaited(context.read<ReelsCubit>().onPageChanged(index));
                },
                itemBuilder: (context, index) => _ReelPage(
                  key: ValueKey(state.items[index].key),
                  reel: state.items[index],
                  isActive: index == _index,
                  muted: state.muted,
                ),
              ),
              _TopBar(
                muted: state.muted,
                onMute: () => context.read<ReelsCubit>().toggleMute(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ‼️ **رسالتان لا واحدة.** «لا مقاطع» و«تعذّر الاتّصال» ينتهيان بقائمةٍ خالية،
/// ودمجُهما يعني أنّ منفذاً معطّلاً يُقرأ «متجرٌ بلا مقاطع» — فلا يُبلَّغ عنه أحد
/// ولا يُصلَح. (وقع فعلاً عند أوّل تشغيل: المنفذ لم يكن منشوراً بعد.)
class _EmptyReels extends StatelessWidget {
  const _EmptyReels({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.wifi_off_rounded : Icons.slow_motion_video_rounded,
              color: Colors.white24,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text(
              failed ? 'تعذّر تحميل المقاطع' : 'لا مقاطع بعد',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              failed
                  ? 'تحقّق من اتّصالك ثمّ أعد المحاولة.'
                  : 'ستظهر هنا مقاطع المنتجات فور رفعها من المتجر.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            if (failed)
              FilledButton(
                onPressed: () => unawaited(context.read<ReelsCubit>().load()),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: TintColors.charcoal,
                ),
                child: const Text('أعد المحاولة',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('رجوع', style: TextStyle(color: TintColors.tintYellow)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.muted, required this.onMute});

  final bool muted;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        child: Row(
          children: [
            _GlassButton(icon: Icons.close_rounded, onTap: () => context.pop()),
            const Spacer(),
            const Text(
              'مقاطع المنتجات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
            const Spacer(),
            _GlassButton(
              icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              onTap: onMute,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ───────────────────────────── صفحة المقطع ─────────────────────────────

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.muted,
  });

  final ReelModel reel;
  final bool isActive;
  final bool muted;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> with SingleTickerProviderStateMixin {
  final ReelVideoHandle _video = ReelVideoHandle();
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  ProductModel get _product => widget.reel.product!;

  /// ‼️ **النقر المزدوج يُضيف ولا يُبدّل.** في تيك توك النقرتان إعجابٌ دائماً؛
  /// وجعلُهما تبديلاً يعني أنّ من ينقر مرّتين على مقطعٍ أعجبه سلفاً يُلغي إعجابه
  /// وهو يظنّ أنّه أكّده.
  Future<void> _doubleTapLike() async {
    final favorites = context.read<FavoritesCubit>();
    _burst.forward(from: 0);
    if (favorites.state.contains(_product.id)) return;
    await favorites.toggle(_product);
  }

  Future<void> _toggleFavorite() async {
    final added = await context.read<FavoritesCubit>().toggle(_product);
    if (!mounted) return;
    if (added) _burst.forward(from: 0);
  }

  /**
   * مشاركة المنتج أو العرض — بورقة النظام لا بتكاملٍ لكلّ تطبيق.
   *
   * ‼️ **الرابط رابطُ ويب لا `tint://`.** الرابط العميق لا يفتح إلّا عند من
   * ثبّت التطبيق؛ ومن لم يُثبّته — وهو **كلّ من نشارك لأجله** — يرى في واتساب
   * نصّاً لا يُنقر، أو صفحةَ خطأ. ورابط المتجر يفتح عند الجميع، ويعرض على من
   * لا يملك التطبيق تثبيتَه.
   */
  Future<void> _share() async {
    final reel = widget.reel;
    final origin = context.read<AppConfig>().storeWebUrl;
    final link = reel.isPromo
        ? (reel.ctaHref.trim().isEmpty ? origin : '$origin${reel.ctaHref.trim()}')
        : '$origin/product/${Uri.encodeComponent(_product.id)}';

    final headline = reel.isPromo
        ? (reel.title.trim().isEmpty ? 'شاهد هذا من تِنت' : reel.title.trim())
        : '${_product.title} — ${_money(_product.price)} ر.س';

    try {
      await SharePlus.instance.share(
        ShareParams(text: '$headline\n$link', subject: headline),
      );
    } catch (error) {
      // ‼️ لا تسقط الشاشة: ورقة المشاركة قد تُرفض على أجهزةٍ مقيّدة.
      debugPrint('[reels] تعذّرت المشاركة: $error');
    }
  }

  void _addToCart() {
    final added = context.read<CartCubit>().addProduct(_product);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: TintColors.charcoal,
          /*
            ‼️ **يرتفع فوق بطاقة الشراء ويقصر.**

            كان يهبط في مكانه الافتراضيّ **فيغطّي زرّ «أضف إلى السلّة» نفسه** —
            فمن أراد إضافة منتجٍ ثانٍ وجد التأكيدَ حاجزاً دون الزرّ الذي أنتجه.
            وثلاث ثوانٍ في شريطٍ يُمرَّر كلّ ثانيتين تُقرأ «معلّقة».
          */
          margin: const EdgeInsets.only(bottom: 172, left: 16, right: 16),
          duration: const Duration(milliseconds: 1800),
          content: Text(added ? 'أُضيف إلى السلّة' : 'هذا المنتج في سلّتك بالفعل'),
          action: SnackBarAction(
            label: 'السلّة',
            textColor: TintColors.tintYellow,
            // الانتقال للسلّة من داخل الشريط: يُغلق الشريط أوّلاً وإلّا بقيت
            // الشاشة السوداء فوق السلّة.
            onPressed: () {
              context.pop();
              context.go('/?tab=cart');
            },
          ),
        ),
      );
  }

  /// وجهة زرّ الترويج — تُقرأ من رابط البنر كما تُدار من اللوحة.
  ///
  /// ‼️ **الرابط المجهول لا يُعطَّل بل يُخفى زرّه.** زرٌّ ظاهرٌ لا يفعل شيئاً
  /// يُقرأ عطلاً في التطبيق؛ وغيابُه يُقرأ «مقطعٌ للعرض لا للنقر» — وهو الصحيح.
  void _openPromo(String href) {
    final target = href.trim();
    if (target.isEmpty) return;
    if (target.startsWith('/category/') ||
        target.startsWith('/product/') ||
        target.startsWith('/discover/')) {
      context.push(target);
      return;
    }
    if (target.startsWith('/')) context.push(target);
  }

  Widget _buildPromo(BuildContext context) {
    final reel = widget.reel;
    final hasCta = reel.ctaHref.trim().isNotEmpty;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reel.eyebrow.trim().isNotEmpty)
                Text(
                  reel.eyebrow,
                  style: const TextStyle(
                    color: TintColors.tintYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              if (reel.title.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ],
              if (reel.note.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  reel.note,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // ‼️ وسمٌ صريح: المشاهد يستحقّ أن يعرف أنّ ما يراه ترويجٌ للمتجر
              //    لا مقطعُ منتجٍ عاديّ — والإخفاء يُفقد الثقة حين يُكتشَف.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'مقطع ترويجيّ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasCta) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openPromo(reel.ctaHref),
                    style: FilledButton.styleFrom(
                      backgroundColor: TintColors.sand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reel.ctaLabel.trim().isEmpty ? 'شاهد الآن' : reel.ctaLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_left_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reel.isPromo) {
      return GestureDetector(
        onTap: _video.togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ReelVideo(
              handle: _video,
              url: widget.reel.videoUrl,
              isActive: widget.isActive,
              muted: widget.muted,
              poster: widget.reel.poster,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xE0000000), Color(0x00000000)],
                ),
              ),
            ),
            _buildPromo(context),
          ],
        ),
      );
    }

    final product = _product;
    final oldPrice = product.oldPrice;
    final discount = (oldPrice != null && oldPrice > product.price)
        ? (((oldPrice - product.price) / oldPrice) * 100).round()
        : 0;

    /*
      ‼️ **الخصم يُعرض حين يُقرَّب إلى 1٪ فأكثر — لا حين يوجد.**

      رُصد بالتشغيل على مقطعٍ حقيقيّ: سعرٌ 16.31 وقديمٌ 16.36 أنتج شارة
      «\u200E-0%\u200E» وسعراً مشطوباً «16» — لأنّ القديم كان يُطبع بلا كسور. فبدا للمشتري
      **سعرٌ قديم أقلّ من الحاليّ وخصمٌ صفر**: متجرٌ يعرض هزلاً، والبيانات سليمة.

      فالفرق الذي لا يُرى لا يُعلَن، والقديم يُطبع بكسوره كالحاليّ.
    */
    final hasDiscount = discount >= 1;

    return GestureDetector(
      onTap: _video.togglePlay,
      onDoubleTap: () => unawaited(_doubleTapLike()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ReelVideo(
            handle: _video,
            url: widget.reel.videoUrl,
            isActive: widget.isActive,
            muted: widget.muted,
            poster: widget.reel.poster,
          ),

          // تدرّجٌ سفليّ: النصّ الأبيض على فيديو فاتح لا يُقرأ، والتدرّج يضمن
          // التباين مهما كان لون المقطع.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xCC000000), Color(0x00000000)],
              ),
            ),
          ),

          _HeartBurst(controller: _burst),

          // الشريط الجانبيّ: إعجابٌ وسلّة — بعيدةٌ عن حافّة الإبهام السفليّة
          // كي لا تُضغط سهواً أثناء التمرير.
          /*
            ‼️ **إلى اليسار لا اليمين.** الواجهة عربيّة، والإبهام يستقرّ حيث
            يُمسك الهاتف؛ لكنّ اليمين هنا يقع فوق نصّ العنوان والسعر الممتدّ من
            اليمين — فكان الشريط يزاحم ما يُقرأ. واليسار يتركه فارغاً كما في
            تيك توك ذاته.
          */
          Positioned(
            left: 12,
            bottom: 190,
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favorites) {
                final liked = favorites.contains(product.id);
                return Column(
                  children: [
                    _RailButton(
                      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: liked ? TintColors.danger : Colors.white,
                      label: 'أعجبني',
                      onTap: () => unawaited(_toggleFavorite()),
                    ),
                    const SizedBox(height: 16),
                    _RailButton(
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.white,
                      label: 'السلّة',
                      onTap: _addToCart,
                    ),
                    const SizedBox(height: 16),
                    _RailButton(
                      icon: Icons.reply_rounded,
                      color: Colors.white,
                      label: 'مشاركة',
                      onTap: () => unawaited(_share()),
                    ),
                  ],
                );
              },
            ),
          ),

          // بطاقة الشراء السفليّة.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(74, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: TintColors.tintYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${_money(product.price)} ر.س',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            _money(oldPrice!),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: TintColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-$discount%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addToCart,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: TintColors.charcoal,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                            label: const Text(
                              'أضف إلى السلّة',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ‼️ صورةُ المنتج زرٌّ لا زينة: هي أوضح ما يدلّ على أنّ
                        //    خلف المقطع منتجاً يُفتح — والنصّ وحده يُقرأ عنواناً.
                        InkWell(
                          onTap: () => context.push('/product', extra: product),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white70, width: 1.5),
                              image: DecorationImage(
                                // القاعدة نفسها: مصغّرةٌ خام كانت تظهر إطاراً فارغاً.
                                image: NetworkImage(TintNetworkImage.resolve(product.image)),
                                fit: BoxFit.cover,
                              ),
                            ),
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
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

/// قلبٌ ينبض عند الإعجاب — تأكيدٌ بصريّ فوريّ لا ينتظر الشبكة.
class _HeartBurst extends StatelessWidget {
  const _HeartBurst({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            if (controller.isDismissed) return const SizedBox.shrink();
            final t = controller.value;
            // يكبر ثمّ يخفت: منحنى واحد للحجم وآخر للشفافيّة كي لا يختفي وهو كبير.
            final scale = 0.6 + Curves.easeOutBack.transform((t * 1.6).clamp(0.0, 1.0)) * 0.7;
            final opacity = t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 110,
            shadows: [Shadow(color: Colors.black45, blurRadius: 18)],
          ),
        ),
      ),
    );
  }
}
