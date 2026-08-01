import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/discover_model.dart';
import '../../../../core/widgets/tint_ui.dart';
import '../cubit/discover_cubit.dart';
import '../widgets/product_card.dart';

/// تبويب «الترندات» — أرفف اكتشافٍ تُصفّى بتبويب القسم.
///
/// كلّ رفٍّ هنا خلفه إشارةٌ حقيقيّة: الخادم لا يرسل رفّاً دون أربعة عناصر،
/// فما تراه الشاشة موجودٌ فعلاً. لذلك لا حالة «فارغ» داخل رفّ.
class TrendsPage extends StatelessWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<DiscoverCubit>().refresh(),
            child: CustomScrollView(
              slivers: [
                const _TrendsAppBar(),
                if (state.feed.tabs.isNotEmpty)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabsHeader(
                      tabs: state.feed.tabs,
                      active: state.category,
                      onSelect: (slug) =>
                          context.read<DiscoverCubit>().selectCategory(slug),
                    ),
                  ),
                if (state.isLoading)
                  const SliverToBoxAdapter(child: _RailsSkeleton())
                else if (state.failed)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Notice(
                      icon: Icons.wifi_off_rounded,
                      text: 'تعذّر تحميل الترندات',
                      actionLabel: 'إعادة المحاولة',
                      onAction: () => context.read<DiscoverCubit>().refresh(),
                    ),
                  )
                else if (!state.hasContent)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Notice(
                      icon: Icons.insights_rounded,
                      // لا نخترع رفوفاً لملء الفراغ. القسم الفارغ فارغٌ بحقّ.
                      text: 'لا توجد ترندات في هذا القسم بعد',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: state.feed.sections.length,
                    itemBuilder: (context, i) => _Rail(
                      section: state.feed.sections[i],
                      category: state.category,
                      // تعتيمٌ خفيف أثناء تبديل التبويب بدل استبدال المحتوى
                      // بهيكلٍ فارغ — القفزة البيضاء تُقرأ كعطل.
                      dimmed: state.isSwitchingTab,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendsAppBar extends StatelessWidget {
  const _TrendsAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('الترندات',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// شريط تبويبات الأقسام — يبقى ظاهراً أثناء التمرير كي يبقى تبديل القسم
/// في متناول الإبهام مهما نزل المستخدم.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.tabs, required this.active, required this.onSelect});

  final List<DiscoverTab> tabs;
  final String active;
  final void Function(String slug) onSelect;

  static const _height = 54.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _height,
      color: Colors.white,
      alignment: Alignment.centerRight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tab = tabs[i];
          final on = tab.slug == active;
          return Center(
            child: GestureDetector(
              onTap: () => onSelect(tab.slug),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? TintColors.charcoal : const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tab.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    color: on ? Colors.white : TintColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader old) =>
      old.active != active || old.tabs.length != tabs.length;
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.section,
    required this.category,
    this.dimmed = false,
  });

  final DiscoverSection section;
  final String category;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: dimmed ? 0.45 : 1,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
                        if (section.subtitle != null &&
                            section.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              section.subtitle!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TintColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (section.hasMore)
                    TextButton(
                      onPressed: () => context.push(
                        '/discover/${section.key}',
                        extra: category,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('عرض الكل',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: TintColors.charcoal)),
                          Icon(Icons.chevron_left_rounded, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 268,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: section.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 164,
                  child: ProductCard(product: section.items[i], dense: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// هيكلٌ يحاكي رفّين أثناء أوّل تحميل — أهدأ من دوّامةٍ في وسط شاشةٍ بيضاء.
class _RailsSkeleton extends StatelessWidget {
  const _RailsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double w, double h, [double r = 12]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF2),
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(150, 17),
              const SizedBox(height: 8),
              box(200, 11),
              const SizedBox(height: 14),
              Row(
                children: [
                  box(164, 240, 18),
                  const SizedBox(width: 12),
                  box(164, 240, 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: TintColors.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: TintColors.textMuted, fontWeight: FontWeight.w700),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
