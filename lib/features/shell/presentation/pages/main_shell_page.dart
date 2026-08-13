import 'dart:async';

import 'package:flutter/material.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/tracking/tracking_events.dart';
import '../../../../core/tracking/tracking_service.dart';
import '../../../settings/presentation/pages/tracking_consent_page.dart';
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
import '../../../account/presentation/cubit/addresses_cubit.dart';
import '../../../account/presentation/cubit/favorites_cubit.dart';
import '../../../account/presentation/cubit/orders_cubit.dart';
import '../../../account/presentation/cubit/profile_cubit.dart';
import '../../../account/presentation/cubit/rewards_cubit.dart';
import '../../../account/presentation/pages/profile_page.dart';
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
  bool _consentAsked = false;

  Future<void> _maybeAskConsent() async {
    if (_consentAsked || !mounted) return;
    final tracking = context.read<TrackingService>();

    // ‼️ **تُنتظَر الإشارة لا المهلة** — انظر `TrackingService.ready`.
    await tracking.ready;
    if (!mounted) return;
    if (!tracking.needsConsentDecision) return;

    _consentAsked = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingConsentPage(tracking: tracking),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskConsent());
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

  @override
  Widget build(BuildContext context) {
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
              context.read<HomeStoreCubit>().setActiveTopNav(item.label);
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
              Positioned(
                left: 20,
                bottom: 96,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push('/assistant'),
                  backgroundColor: TintColors.sand,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    'مستشار تنت',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
const List<_NavItem> _defaultTabs = [
  _NavItem(icon: Icons.person_outline_rounded, label: 'حسابي', index: 4),
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
    if (key == 'home') continue;

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
              onTap: () => cubit.selectTab(0),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: currentIndex == 0 ? TintColors.sand : TintColors.charcoal,
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
        ],
      ),
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
