import 'dart:async';

import 'package:flutter/material.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../catalog/presentation/pages/categories_page.dart';
import '../../../catalog/presentation/cubit/categories_cubit.dart';
import '../../../catalog/presentation/cubit/discover_cubit.dart';
import '../../../catalog/presentation/cubit/home_store_cubit.dart';
import '../../../catalog/presentation/pages/home_page.dart';
import '../../../catalog/presentation/widgets/store_drawer.dart';
import '../../../catalog/presentation/pages/trends_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../account/presentation/cubit/addresses_cubit.dart';
import '../../../account/presentation/cubit/favorites_cubit.dart';
import '../../../account/presentation/cubit/orders_cubit.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../account/presentation/cubit/rewards_cubit.dart';
import '../../../account/presentation/pages/profile_page.dart';
import '../../../reels/data/reel_badge.dart';
import '../cubit/shell_cubit.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  /// ‼️ مفتاحٌ على قشرة التطبيق: زرّ ☰ يعيش داخل هيدر الرئيسيّة — أعمق من
  /// `Scaffold` القشرة — فبلا مفتاحٍ صريح لا يجد القائمة ليفتحها.
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  /// تُفتَح من أيّ شاشة داخل القشرة.
  static void openDrawer() => scaffoldKey.currentState?.openEndDrawer();

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _pages = [
    HomePage(),
    TrendsPage(),
    CategoriesPage(),
    CartPage(),
    ProfilePage(),
  ];

  // الرئيسيّة (0) تُحمَّل عند الإقلاع؛ بقيّة التبويبات كسولة عند أوّل فتح.
  // بلا تحميل كسول كانت كلّ الـCubits تجلب دفعةً واحدة عند البدء فتزاحمت
  // على خادم أوروبا وتجاوزت المهلة عند البرودة.
  final Set<int> _loaded = {0};

  /// ‼️ **تُعرَض مرّةً واحدة وبعد أوّل إطار.**
  ///
  /// `initState` أبكر ممّا يجوز: الشجرة لم تُبنَ بعد فلا `Navigator` يُدفَع
  /// عليه. و`addPostFrameCallback` يضمن شاشةً حاضرة.
  ///
  /// ‼️ **وتنتظر وصول الإعدادات**: `needsConsentDecision` تعود `false`
  /// ما دامت القناة مُطفأة — وهي كذلك حتّى يصل ردّ `config`. فعرضُها فوراً كان
  /// يسأل مستخدمي متاجرَ لا تقيس أصلاً.
  /// ‼️ **لا شاشة موافقةٍ حاجزة عند الإقلاع — حُذفت بقرار المالك 2026-08-29.**
  ///
  /// كانت أوّل ما يراه الزائر: استمارةُ خصوصيّةٍ قبل أن يرى منتجاً واحداً، ولم
  /// يقرّر بعدُ أنّه يريد شيئاً. وبعد أن صار الوضع الابتدائيّ مُفعَّلاً، لم تعد
  /// تفعل شيئاً إلّا أن يضغط الجميع «تأكيد» بلا قراءة — **احتكاكٌ بلا فائدةٍ
  /// لأحد.**
  ///
  /// ‼️ **وحُذفت بعد فحصٍ لا بافتراض**: لا معرّف إعلانيّ يُقرأ بأنفسنا، وفايربيس
  /// على iOS لا يقرأ IDFA افتراضيّاً ⇒ **لا نافذة ATT تلزم**؛ وPlay يطلب
  /// إفصاحاً في «أمان البيانات» لا شاشةً حاجزة.
  ///
  /// ‼️ **والصفحة باقيةٌ في «حسابي ← الخصوصيّة والقياس»** — والحذف مشروطٌ
  /// ببقائها: افتراضٌ مفتوحٌ بلا مخرجٍ ظاهر ليس اختياراً.
  ///
  /// ‼️ **وتُعاد هذه الشاشة إن بيع في أوروبا** — اللائحة تشترط موافقةً سابقة.
  /// عندها يُستعاد هذا النداء ويُقيَّد ببلد الجهاز، ومعه الوضع الابتدائيّ في
  /// `TrackingConsent.undecided`.

  @override
  void initState() {
    super.initState();
  }

  void _ensureLoaded(BuildContext context, int index) {
    /// ‼️ **`view_cart` هنا لا في `initState` شاشة السلّة.**
    ///
    /// الشاشات تعيش في `IndexedStack`، فـ`initState` يُنفَّذ **مرّةً واحدة في عمر
    /// التطبيق** — وغالباً والسلّة فارغة. فكان الحدث يُطلَق مرّةً أو لا يُطلَق
    /// أبداً (رُصد على المحاكي 2026-08-13: `begin_checkout` خرج و`view_cart` لم
    /// يخرج رغم فتح السلّة بمنتجٍ فيها).
    ///
    /// والفعل الذي يعنيه الحدث هو **فتح التبويب**، فهنا موضعه.
    if (index == 3) {
      final items = context.read<CartCubit>().state.items;
      if (items.isNotEmpty) {
        unawaited(context.read<TrackingService>().logViewCart([
          for (final row in items)
            TrackingEvents.item(row.product, quantity: row.quantity),
        ]));
      }
    }

    switch (index) {
      case 1: // الترندات: يُعاد جلبها عند كلّ فتح (تعافٍ رخيص من فشل سابق).
        context.read<DiscoverCubit>().load();
        break;
      case 2:
        if (_loaded.add(2)) context.read<CategoriesCubit>().load();
        break;
      case 4: // حسابي: كلّ بيانات الحساب تُجلب مرّةً عند أوّل فتح.
        if (_loaded.add(4)) {
          context.read<ProfileCubit>().load();
          context.read<OrdersCubit>().load();
          context.read<AddressesCubit>().load();
          context.read<RewardsCubit>().load();
          context.read<FavoritesCubit>().load();
        }
        break;
    }
  }

  /// آخر هويّةٍ رُسمت لها بيانات الحساب — `null` = لا أحد.
  String? _accountPhone;

  /// يمحو بيانات الحساب السابق عند تبدّل الهويّة.
  ///
  /// ‼️ **العطل الذي يُغلقه ليس عرضاً خاطئاً بل شحنةٌ إلى الشخص الخطأ.**
  ///
  /// الكيوبتات الحسابيّة الخمسة عامّةٌ في `main`، وتُجلَب **مرّةً واحدة في عمر
  /// التشغيل** بحارس `_loaded`. وتسجيل الخروج كان يمسح التوكن والتفضيلات —
  /// **ولا يمسّها**. فمن خرج ودخل بحسابٍ آخر على الجهاز نفسه كان يرى عنوان
  /// الأوّل وطلباته ونقاطه؛ وشاشة الدفع تقرأ العنوان من هنا، فيُشحن طلبُه
  /// إلى عنوان غيره **باسم غيره ورقمه**. (رصده المالك 2026-08-27.)
  ///
  /// ‼️ **ويُقارَن الجوّال لا مجرّد «أدخلَ أم خرج»**: من خرج ودخل بنفس الحساب
  /// لا داعي لإفراغ شاشاته، ومن بدّل الحساب يجب أن يُفرَغ ولو لم يخرج صراحةً.
  void _onIdentityChanged(BuildContext context, AuthState state) {
    final phone = state.customer?.phone;
    if (phone == _accountPhone) return;
    _accountPhone = phone;

    context.read<ProfileCubit>().clearForAccountSwitch();
    context.read<OrdersCubit>().clearForAccountSwitch();
    context.read<AddressesCubit>().clearForAccountSwitch();
    context.read<RewardsCubit>().clearForAccountSwitch();
    context.read<FavoritesCubit>().clearForAccountSwitch();

    /// ‼️ **ويُرفَع حارس الجلب أيضاً** — وإلّا بقيت الشاشات فارغةً إلى الأبد:
    /// مُسحت البيانات و`_loaded` يقول إنّها جُلبت. والفراغ الدائم عطلٌ آخر
    /// محلّ الأوّل.
    _loaded.remove(4);
    if (mounted && context.read<ShellCubit>().state == 4) _ensureLoaded(context, 4);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.customer?.phone != curr.customer?.phone,
      listener: _onIdentityChanged,
      child: _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return BlocConsumer<ShellCubit, int>(
      listenWhen: (prev, curr) => prev != curr,
      listener: _ensureLoaded,
      builder: (context, currentIndex) {
        return Scaffold(
          key: MainShellPage.scaffoldKey,
          backgroundColor: const Color(0xFFE5E7EB),
          /**
           * ‼️ **القائمة على القشرة لا على كلّ شاشة**: `Scaffold` واحدٌ يملكها،
           * فتُفتَح من أيّ تبويب بنفس الإيماءة ولا تتكرّر خمس مرّات.
           *
           * و`endDrawer` لا `drawer`: الواجهة عربيّة، والقائمة تنزلق من اليمين.
           */
          endDrawer: StoreDrawer(
            onOpenCategory: (item) {
              // ‼️ تبديل تبويبٍ لا مسار: الأقسام تُعرَض داخل القشرة.
              //
              // ‼️ **بالمُعرّف لا بالعنوان**: كان `setActiveTopNav(item.label)`
              // يبحث عن الاسم في الشريط العلويّ وحده، فيفتح الآباء ويصمت عن
              // الأبناء — والقائمة شجرةٌ كلّها أبناء. وهي نفس علّة شبكة
              // الرئيسيّة، فعُولجت في موضعٍ واحد.
              final id = item.actionValue.trim().isNotEmpty
                  ? item.actionValue.trim()
                  : item.id;
              context.read<HomeStoreCubit>().openCategoryById(id);
              context.read<ShellCubit>().selectTab(0);
            },
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  // يملأ الشاشة كاملة على الجوالات، ويُقيَّد ويُوسَّط على الأجهزة اللوحية.
                  // المساحة الآمنة العلوية تُدار داخل كل صفحة (AppBar أو TopHeader).
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    color: Colors.white,
                    child: IndexedStack(
                      index: currentIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ),
              /// ‼️ **دائريٌّ مُصغَّر لا زرٌّ ممتدّ.**
              ///
              /// كان `FloatingActionButton.extended` بعرض ~١٦٠ بكسل يطفو فوق
              /// المحتوى — يحجب صفَّ منتجاتٍ كاملاً في شبكةٍ من أربعة أعمدة.
              /// والدائرة تحجب ربع ما كان يحجبه، وتبقى في متناول الإبهام.
              ///
              /// ‼️ **والاسم بقي داخلها**: أيقونةٌ وحدها تُقرأ زرَّ إضافةٍ أو
              /// مشاركة، فلا يعرف من لم يجرّبها ماذا تفعل. و«اسأل» فعلٌ يدعو،
              /// ويسع الدائرة — بخلاف «مستشار تِنت».
              Positioned(
                left: 20,
                bottom: 100,
                child: Tooltip(
                  message: 'مستشار تِنت الذكيّ',
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      onPressed: () => context.push('/assistant'),
                      backgroundColor: TintColors.sand,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: const CircleBorder(),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 20),
                          SizedBox(height: 1),
                          Text(
                            'اسأل',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
        );
      },
    );
  }
}

/// ‼️ **الخريطة في التطبيق لا في الخادم.** الخادم يُرسل `id` نصّيّاً
/// (`home`/`cart`…) لأنّه لا يعرف `IconData` ولا فهارس القشرة — وهما تفصيلٌ
/// داخليّ يتغيّر بإعادة ترتيب الشاشات. فلو أرسلهما الخادم لصار تعديلُ ترتيبٍ
/// في التطبيق يستلزم تعديلاً في القاعدة.
const Map<String, ({IconData icon, int index})> _tabRegistry = {
  'home': (icon: Icons.home_rounded, index: 0),
  'trends': (icon: Icons.trending_up_rounded, index: 1),
  'categories': (icon: Icons.grid_view_rounded, index: 2),
  'cart': (icon: Icons.shopping_cart_outlined, index: 3),
  'account': (icon: Icons.person_outline_rounded, index: 4),
};

/// التبويبات الأربعة المكتوبة — ملاذُ الرجوع، وهي نفسها ترتيب الخادم الافتراضيّ.
///
/// ‼️ **«الرئيسيّة» حلّت محلّ «حسابي» هنا، وصعد الحساب إلى الترويسة.** الشعار
/// صار يفتح شريط المقاطع وحده، فلزم للرئيسيّة مكانٌ صريح. والشريط أربعةٌ بحكم
/// التصميم لا البيانات، فكان لا بدّ من ترقية أحدها — واختير الحساب لأنّه
/// **أقلّها فتحاً**: الرئيسيّة تُفتح مرّاتٍ في الجلسة والحساب مرّةً عند الحاجة.
const List<_NavItem> _defaultTabs = [
  _NavItem(icon: Icons.home_rounded, label: 'الرئيسيّة', index: 0),
  _NavItem(icon: Icons.trending_up_rounded, label: 'الترندات', index: 1),
  _NavItem(icon: Icons.grid_view_rounded, label: 'الأقسام', index: 2),
  _NavItem(icon: Icons.shopping_cart_outlined, label: 'السلة', index: 3),
];

/// يبني تبويبات الشريط من `app-navigation` — **التسمية والترتيب فقط** (3.5).
///
/// ‼️ **والعدد يبقى أربعة بحكم التصميم لا بحكم البيانات.** الشريط اثنان يميناً
/// واثنان يساراً حول زرّ «تنت» العائم، فخمسةٌ تكسره وثلاثةٌ تترك فجوة. ولذلك:
/// أيّ عددٍ مخالف ⇒ **يُرفض كلّه ويُعاد للمكتوب** — لا يُقصّ ولا يُكمَّل، لأنّ
/// شريطاً نصفه من اللوحة ونصفه من الشيفرة يُربك من يُحرّره.
///
/// ‼️ و`home` يُستبعَد: هو الزرّ الدائريّ في الوسط لا عنصرٌ في الصفّ.
List<_NavItem> _resolveTabs(BuildContext context) {
  final tabs = context.watch<HomeStoreCubit>().state.appNavigation?.bottomTabs;
  if (tabs == null || tabs.isEmpty) return _defaultTabs;

  final resolved = <_NavItem>[];
  for (final tab in tabs) {
    final key = tab.actionType == 'tab' && tab.actionValue.isNotEmpty
        ? tab.actionValue
        : tab.id;
    // ‼️ يُستبعَد **الحساب** لا الرئيسيّة: هو ما صعد إلى الترويسة. وتركُ
    //    استبعاد `home` هنا كان سيُنتج شريطاً بلا رئيسيّة وبشعارٍ لا يفتحها.
    if (key == 'account') continue;

    final known = _tabRegistry[key];
    if (known == null) continue; // تبويبٌ لا تعرفه هذه النسخة ⇒ يسقط بصمت.
    resolved.add(_NavItem(
      // الأيقونة من الاسم إن أرسله الخادم، وإلّا فأيقونة التبويب المعروفة.
      icon: _tabRegistry[tab.icon ?? '']?.icon ?? known.icon,
      label: tab.label,
      index: known.index,
    ));
  }

  if (resolved.length != _defaultTabs.length) {
    debugPrint(
      '[sdui] تبويبات الشريط ${resolved.length} لا ${_defaultTabs.length} ⇒ أُبقي المكتوب',
    );
    return _defaultTabs;
  }
  return resolved;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShellCubit>();
    // مساحة آمنة سفلية متغيرة حسب الجهاز (شريط الإيماءات/الزر السفلي)
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final items = _resolveTabs(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TintColors.line)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              for (final item in items.take(2))
                Expanded(
                  child: _BottomNavButton(
                    item: item,
                    isActive: currentIndex == item.index,
                    onTap: () => cubit.selectTab(item.index),
                  ),
                ),
              const SizedBox(width: 74),
              for (final item in items.skip(2))
                Expanded(
                  child: _BottomNavButton(
                    item: item,
                    isActive: currentIndex == item.index,
                    onTap: () => cubit.selectTab(item.index),
                  ),
                ),
            ],
          ),
          Positioned(
            top: -28,
            child: InkWell(
              /**
               * ‼️ **الشعار لشريط المقاطع وحده — بعد أن نالت الرئيسيّة تبويبها.**
               *
               * كان الشعار زرّ الرئيسيّة (وتبويبها مُسقَطٌ من الشريط لأجله)،
               * فجعلُه يفتح المقاطع دائماً كان يقطع الطريق الوحيد إليها. فصعد
               * «حسابي» إلى الترويسة، وحلّت «الرئيسيّة» محلّه في الشريط، وتفرّغ
               * الشعار — فلا فعلَ مزدوجاً يُخمَّن، ولا شاشةً تُفقد.
               */
              onTap: () {
                // ‼️ تُطفأ النبضة قبل الانتقال لا بعده: العودة تجد الشريط
                //    ساكناً، ولو أُجّلت لظهرت نبضةٌ لمقطعٍ شاهده للتوّ.
                unawaited(context.read<ReelBadge>().markSeen());
                context.push('/reels');
              },
              borderRadius: BorderRadius.circular(999),
              child: _ReelPulse(
                child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  // ‼️ لونٌ ثابت: كان يتلوّن حين تكون الرئيسيّة نشطة لأنّه زرّها.
                  //    وبقاؤه كذلك يعني زرّاً يبدو «نشطاً» وضغطتُه تفتح شاشةً أخرى.
                  color: TintColors.charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: TintColors.tintYellow, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const TintBrandLogo(isLight: true, compact: true),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نبضةٌ خلف شعار الشريط متى وصل مقطعٌ لم يُشاهَد.
///
/// ‼️ **حلقةٌ تخرج من تحت الزرّ لا وميضٌ عليه.** تلوينُ الزرّ نفسه كان يجعله
/// يبدو «نشطاً» — وهو ليس تبويباً — فيظنّ المشتري أنّه في شاشة المقاطع أصلاً.
///
/// ‼️ **وتحترم إيقاف الحركة في النظام.** من أطفأ الحركات في إعدادات هاتفه
/// أطفأها لسببٍ (دوار، صداع، تشتّت)، وتجاوزُه لأجل علامةٍ تسويقيّة لا يجوز —
/// فتبقى له نقطةٌ ساكنة تقول الشيء نفسه.
class _ReelPulse extends StatefulWidget {
  const _ReelPulse({required this.child});

  final Widget child;

  @override
  State<_ReelPulse> createState() => _ReelPulseState();
}

class _ReelPulseState extends State<_ReelPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return ValueListenableBuilder<bool>(
      valueListenable: context.read<ReelBadge>().hasNew,
      builder: (context, hasNew, child) {
        final animate = hasNew && !reduced;

        if (animate && !_controller.isAnimating) {
          _controller.repeat();
        } else if (!animate && _controller.isAnimating) {
          _controller.stop();
          _controller.value = 0;
        }

        return _buildStack(hasNew: hasNew, reduced: reduced, animate: animate);
      },
    );
  }

  Widget _buildStack({
    required bool hasNew,
    required bool reduced,
    required bool animate,
  }) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (hasNew && reduced)
          // البديل الساكن: نقطةٌ تقول «جديد» بلا حركة.
          Positioned(
            top: 2,
            right: 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: TintColors.tintYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        if (animate)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_controller.value);
              return IgnorePointer(
                child: Container(
                  width: 72 + (72 * 0.55 * t),
                  height: 72 + (72 * 0.55 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TintColors.tintYellow.withValues(alpha: 0.85 * (1 - t)),
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? TintColors.sand : TintColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
}
