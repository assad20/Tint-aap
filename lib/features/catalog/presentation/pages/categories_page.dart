import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../cubit/categories_cubit.dart';
import '../widgets/product_card.dart';

// تبويب «الأقسام»: قائمة جانبيّة بمجموعات المتجر الحقيقيّة (/catalog/navigation)
// + شبكة منتجات القسم المختار (/catalog/categories/<slug>).
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: TintColors.textMuted),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ابحث عن قسم أو منتج…',
                              style: TextStyle(
                                color: TintColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.categories.isEmpty
                          ? const Center(
                              child: Text(
                                'تعذّر تحميل الأقسام',
                                style: TextStyle(color: TintColors.textMuted),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Sidebar(state: state),
                                Expanded(child: _ProductsPane(state: state)),
                              ],
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});

  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final c = state.categories[index];
          final isActive = c.id == state.selected?.id;
          return InkWell(
            onTap: () => context.read<CategoriesCubit>().select(c),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isActive ? TintColors.sand : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                c.name,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? TintColors.sand : TintColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductsPane extends StatelessWidget {
  const _ProductsPane({required this.state});

  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    if (state.isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا منتجات في «${state.selected?.name ?? ''}» حالياً',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TintColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            state.selected?.name ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 260,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) =>
              ProductCard(product: state.products[index]),
        ),
      ],
    );
  }
}
