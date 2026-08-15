import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../shell/presentation/cubit/shell_cubit.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../cubit/home_store_cubit.dart';

// لون القسم النشط في القائمة العلويّة وخطّه السفليّ. شي إن تستعمل الأسود؛
// بدّله إلى TintColors.sand (لون الهويّة) بسطرٍ واحد إن أُريد.
const _activeNavColor = TintColors.charcoal;

/// ☰ في طرف شريط الأقسام — تفتح تبويب «الأقسام» (الفهرس 2 في القشرة)
/// بكامل شجرة المتجر، كما تفعل شي إن.
class _AllCategoriesButton extends StatelessWidget {
  const _AllCategoriesButton({required this.foreground, required this.divider});

  final Color foreground;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      /**
       * ‼️ **يفتح القائمة الجانبيّة لا تبويب «الأقسام»** (المهمّة 3.4).
       *
       * كان يُبدّل التبويب — وهو انتقالٌ يُخرج المستخدم من مكانه. والقائمة
       * تنزلق فوق ما يتصفّحه ويُغلقها فيعود حيث كان. وتبويب «الأقسام» يبقى
       * كما هو للتصفّح الكامل بالصور والبحث.
       */
      onTap: MainShellPage.openDrawer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // فاصل رفيع يوضّح أنّ الزرّ ثابت وليس آخر عناصر القائمة المنزلقة.
            SizedBox(
              height: 20,
              child: VerticalDivider(width: 1, thickness: 1, color: divider),
            ),
            const SizedBox(width: 10),
            Icon(Icons.menu_rounded, size: 24, color: foreground),
          ],
        ),
      ),
    );
  }
}

class TopHeader extends StatelessWidget {
  const TopHeader({super.key, this.overlayOpacity});

  /// تجربة الهيدر الشفّاف فوق السلايدر (نمط شي إن).
  /// `null` = السلوك الأصليّ: خلفيّة بيضاء وألوان داكنة، بلا أيّ تغيّر.
  /// `0` = شفّاف تماماً بألوانٍ فاتحة فوق البانر، و`1` = أبيض كالأصل.
  final double? overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeStoreCubit, HomeStoreState>(
      builder: (context, state) {
        // إضافة ارتفاع شريط الحالة/النوتش حتى لا يتداخل الشعار مع أعلى الشاشة
        final topInset = MediaQuery.viewPaddingOf(context).top;
        final t = overlayOpacity ?? 1.0;
        final immersive = overlayOpacity != null;
        // كلّ لونٍ يتدرّج من «فوق البانر» إلى «فوق الأبيض» مع التمرير.
        final bg = immersive
            ? Color.lerp(Colors.transparent, Colors.white, t)!
            : Colors.white;
        final fg = immersive
            ? Color.lerp(Colors.white, _activeNavColor, t)!
            : _activeNavColor;
        final muted = immersive
            ? Color.lerp(Colors.white70, TintColors.textMuted, t)!
            : TintColors.textMuted;
        final pill = immersive
            ? Color.lerp(Colors.white24, const Color(0xFFF3F4F6), t)!
            : const Color(0xFFF3F4F6);
        final line = immersive
            ? Color.lerp(Colors.white38, TintColors.line, t)!
            : TintColors.line;
        final cartCount = context
            .watch<CartCubit>()
            .state
            .items
            .fold<int>(0, (sum, item) => sum + item.quantity);
        return Container(
          decoration: BoxDecoration(
            color: bg,
            // ظلٌّ خفيف يضمن قراءة الأيقونات فوق بانرٍ فاتح، ويتلاشى بالتمرير.
            gradient: immersive && t < 1
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.40 * (1 - t)),
                      Colors.black.withOpacity(0.10 * (1 - t)),
                    ],
                  )
                : null,
          ),
          padding: EdgeInsets.fromLTRB(14, 16 + topInset, 14, 10),
          child: Column(
            children: [
              // الشعار العلويّ أُزيل: الهويّة حاضرة في زرّ «الرئيسيّة» الدائريّ أسفل
              // الشاشة، والتكرار كان يبتلع ~65 بكسل من أعلى الصفحة بلا فائدة.
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/profile/favorites'),
                    color: fg,
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: pill,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ابحث عن منتجات، أقسام، ماركات…',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.camera_alt_outlined, color: muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<ShellCubit>().selectTab(3),
                    color: fg,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        if (cartCount > 0)
                          Positioned(
                            top: -4,
                            left: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(minWidth: 16),
                              height: 16,
                              decoration: BoxDecoration(
                                color: TintColors.sand,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  /*
                    ‼️ **«حسابي» صعد إلى هنا ليأخذ مكانَه في الشريط السفليّ زرُّ
                    «الرئيسيّة».** الشريط أربعةٌ بحكم التصميم لا البيانات، فكان
                    لا بدّ من ترقية أحدها. واختير الحساب لأنّه **أقلّها فتحاً**:
                    الرئيسيّة تُفتح في كلّ جلسة مرّات، والحساب مرّةً عند الحاجة.
                    وإبقاءُ الأكثر استعمالاً في مدى الإبهام هو القاعدة.
                  */
                  IconButton(
                    onPressed: () => context.read<ShellCubit>().selectTab(4),
                    color: fg,
                    tooltip: 'حسابي',
                    icon: const Icon(Icons.person_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.navLabels.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          final item = state.navLabels[index];
                          final isActive = item == state.activeTopNav;
                          return InkWell(
                            onTap: () => context
                                .read<HomeStoreCubit>()
                                .setActiveTopNav(item),
                            // IntrinsicWidth ليمتدّ الخطّ السفليّ بعرض الكلمة
                            // تماماً (نمط شي إن) بدل عرضٍ ثابت لا يناسب «كل»
                            // و«مجوهرات وإكسسوارات» معاً.
                            child: IntrinsicWidth(
                              child: Center(
                                child: Column(
                                  // mainAxisSize.min + Center: الكلمة وخطّها
                                  // كتلة واحدة متلاصقة تتوسّط الشريط، بدل
                                  // spaceBetween الذي كان يدفع الخطّ لقاع
                                  // الشريط فتتّسع الفجوة.
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      item,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isActive ? fg : muted,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // شفّاف لا بارتفاع صفر حين لا يكون نشطاً،
                                    // فلا يقفز النصّ رأسيّاً بين قسمٍ وآخر.
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color:
                                            isActive ? fg : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // ☰ ثابتة في طرف الشريط لا تنزلق معه (نمط شي إن) — تفتح
                    // تبويب «الأقسام» بكامل شجرة المتجر. وتحلّ محلّ اسم القسم
                    // المقطوع الذي كان يظهر عند الحافّة.
                    _AllCategoriesButton(foreground: fg, divider: line),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
