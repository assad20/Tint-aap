import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/product_model.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../widgets/product_card.dart';

/// «عرض الكل» لرفٍّ واحد — شبكة عمودين بتمريرٍ لانهائيّ.
///
/// تحمل حالتها بنفسها بلا Cubit عالميّ: الشاشة تُفتح وتُغلق، وحالتها لا يحتاجها
/// أحدٌ بعدها. مُزوّدٌ عامّ لصفحةٍ عابرة يعني تسريب حالةٍ بين فتحتين.
class DiscoverSectionPageView extends StatefulWidget {
  const DiscoverSectionPageView({
    super.key,
    required this.sectionKey,
    this.category = 'all',
  });

  final String sectionKey;
  final String category;

  @override
  State<DiscoverSectionPageView> createState() => _DiscoverSectionPageViewState();
}

class _DiscoverSectionPageViewState extends State<DiscoverSectionPageView> {
  final _scroll = ScrollController();
  final _items = <ProductModel>[];

  String _title = '';
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // 600 بكسل قبل النهاية: الدفعة تصل قبل أن يبلغ الإبهام القاع، فلا يرى
    // المستخدم توقّفاً.
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    final next = _page + 1;
    final page = await context.read<CatalogRepository>().fetchDiscoverSection(
          widget.sectionKey,
          category: widget.category,
          page: next,
        );
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (page == null) {
        // فشل الدفعة لا يمسح ما وصل. ويُوقف الطلب التلقائيّ كي لا يدور النداء
        // في حلقةٍ على شبكةٍ منقطعة.
        _failed = true;
        _hasMore = false;
        return;
      }
      if (_title.isEmpty) _title = page.title;
      _page = next;
      _items.addAll(page.items);
      _hasMore = page.hasMore;
    });
  }

  void _retry() {
    setState(() => _hasMore = true);
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _title.isEmpty ? 'عرض الكل' : _title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded,
                          size: 40, color: TintColors.textMuted),
                      const SizedBox(height: 10),
                      const Text('لا توجد منتجات هنا',
                          style: TextStyle(
                              color: TintColors.textMuted,
                              fontWeight: FontWeight.w700)),
                      if (_failed) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: _retry, child: const Text('إعادة المحاولة')),
                      ],
                    ],
                  ),
                )
              : GridView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 268,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length + (_loading || _failed ? 2 : 0),
                  itemBuilder: (context, i) {
                    if (i < _items.length) {
                      return ProductCard(product: _items[i], dense: true);
                    }
                    // خانتان في الذيل: الأولى تحمل المؤشّر أو زرّ الإعادة.
                    if (i > _items.length) return const SizedBox.shrink();
                    return Center(
                      child: _failed
                          ? OutlinedButton(
                              onPressed: _retry, child: const Text('إعادة المحاولة'))
                          : const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
    );
  }
}
